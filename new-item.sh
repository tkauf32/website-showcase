#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ---------- tiny logger ----------
ts(){ date +"%Y-%m-%d %H:%M:%S"; }
log(){ printf "[%s] [%s] %s\n" "$(ts)" "$1" "$2"; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1" >&2; }
err(){  log ERROR "$1" >&2; }

TITLE_FROM_FLAG=0

# ---------- helpers ----------
normalize_type() {
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]' | sed 's/^_//')" in
    1|pj|project|projects) echo "projects" ;;
    2|pd|product|products) echo "products" ;;
    3|lk|link|links)       echo "links" ;;
    4|pt|printable|printables) echo "printables" ;;
    *) echo "" ;;
  esac
}
slugify(){ echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-+//; s/-+$//'; }
titlecase(){ echo "$1" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2)}; print}'; }
abspath(){ local p="$1"; if [ -d "$p" ]; then (cd "$p" && pwd); else (cd "$(dirname -- "$p")" && printf "%s/%s\n" "$(pwd)" "$(basename "$p")"); fi; }

# ---------- args ----------
COLLECTION=""; TITLE=""; SLUG=""; DATE="$(date +%Y-%m-%d)"
FROM_IMG=""; FROM_FILES=""; RECURSE=0; KEEP_EXIF=0; DRY=0; FORCE=0; PAD_DEFAULT=3

usage(){ cat <<'EOF'
Usage: new-item.sh [opts]
  -t, --type TYPE        projects|products|links|printables (1/pj/etc. ok)
  -T, --title TITLE      Human title (slug auto from this unless --slug)
  -s, --slug SLUG        Override slug
  -d, --date YYYY-MM-DD  Override date (default: today)
  -i, --from-images DIR  Ingest images (HEIC->PNG if supported), numbered
  -F, --from-files DIR   Ingest files (keeps names, unique-suffixed)
  -r, --recurse          Recurse in ingest dirs
  -K, --keep-exif        Keep EXIF (default strips)
  -n, --dry-run          Preview only
      --force            Overwrite existing .md (assets still protected)
  -h, --help
EOF
}

while (($#)); do case "${1:-}" in
  -t|--type)        COLLECTION="$(normalize_type "${2:-}")"; shift 2 ;;
  -T|--title)       TITLE="${2:-}"; TITLE_FROM_FLAG=1; shift 2 ;;
  -s|--slug)        SLUG="${2:-}"; shift 2 ;;
  -d|--date)        DATE="${2:-}"; shift 2 ;;
  -i|--from-images) FROM_IMG="${2:-}"; shift 2 ;;
  -F|--from-files)  FROM_FILES="${2:-}"; shift 2 ;;
  -r|--recurse)     RECURSE=1; shift ;;
  -K|--keep-exif)   KEEP_EXIF=1; shift ;;
  -n|--dry-run)     DRY=1; shift ;;
  --force)          FORCE=1; shift ;;
  -h|--help)        usage; exit 0 ;;
  *) warn "Unknown arg: $1"; usage; exit 2 ;;
esac; done

prompt(){ local m="$1" d="${2:-}"; local a; read -r -p "$m${d:+ [$d]}: " a || true; echo "${a:-$d}"; }

# Essentials
if [[ -z "$COLLECTION" ]]; then
  echo "Select collection: 1) projects  2) products  3) links  4) printables"
  COLLECTION="$(normalize_type "$(prompt 'Type')" )"
fi
[[ -z "$COLLECTION" ]] && { err "Invalid type."; exit 1; }

if [[ -z "$TITLE" && -z "$SLUG" ]]; then TITLE="$(prompt 'Title (derive slug)')"; fi
[[ -z "$SLUG" ]] && SLUG="$(slugify "${TITLE}")"
[[ -z "$SLUG" ]] && { err "Slug could not be derived. Provide --slug."; exit 1; }
[[ -z "$TITLE" ]] && TITLE="$(titlecase "$SLUG")"

# Make a human title if user didn't explicitly pass --title
if [[ $TITLE_FROM_FLAG -eq 0 ]]; then
  if [[ -z "$TITLE" || "$TITLE" == "$SLUG" || "$TITLE" =~ ^[a-z0-9-]+$ ]]; then
    TITLE="$(echo "$SLUG" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2)}; print}')"
  fi
fi
# Fallback safety
[[ -z "$TITLE" ]] && TITLE="$(echo "$SLUG" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2)}; print}')"

# Paths
jekyll_dir="_${COLLECTION}"
asset_base="assets/${COLLECTION}"
item_dir="${asset_base}/${SLUG}"
images_dir="${item_dir}/images"
files_dir="${item_dir}/files"
dest_md="${jekyll_dir}/${SLUG}.md"
assets_dir_web="/assets/${COLLECTION}/${SLUG}"

info "Collection : $COLLECTION"
info "Title      : $TITLE"
info "Slug       : $SLUG"
info "Date       : $DATE"
info "Markdown   : $dest_md"
info "Assets dir : $(abspath "$item_dir")"

# Create dirs
if ((DRY)); then info "(dry-run) Would mkdir -p $jekyll_dir $images_dir $files_dir"
else mkdir -p "$jekyll_dir" "$images_dir" "$files_dir"; fi

# Tools (optional)
# ---------- ImageMagick detection (robust) ----------
IM_CMD=""
# Try PATH first
if command -v magick >/dev/null 2>&1; then IM_CMD="$(command -v magick)"
elif command -v convert >/dev/null 2>&1; then IM_CMD="$(command -v convert)"
# Try common Homebrew/macOS fallbacks (for sudo PATH issues)
elif [ -x /opt/homebrew/bin/magick ]; then IM_CMD="/opt/homebrew/bin/magick"
elif [ -x /usr/local/bin/magick ]; then IM_CMD="/usr/local/bin/magick"
elif [ -x /opt/homebrew/bin/convert ]; then IM_CMD="/opt/homebrew/bin/convert"
elif [ -x /usr/local/bin/convert ]; then IM_CMD="/usr/local/bin/convert"
fi

if [ -n "$IM_CMD" ]; then
  info "Using ImageMagick: $IM_CMD"
else
  warn "ImageMagick CLI not found (magick/convert). HEIC/JPG->PNG conversions will be skipped."
fi

heic_ok=0
if [ -n "$IM_CMD" ] && "$IM_CMD" -list format 2>/dev/null | grep -Eq '^[[:space:]]*HEIC\b'; then
  heic_ok=1
  info "HEIC support: yes"
else
  warn "HEIC support: NO (install libheif; e.g., 'brew install imagemagick libheif')."
fi
# ----- enumerate using find (zsh/bash safe) -----
find_images() { # echo absolute paths
  local d="$1"
  find "$d" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print \
    | LC_ALL=C sort
}
find_files() {
  local d="$1"
  # everything except typical image inputs
  find "$d" -maxdepth 1 -type f ! -name '.*' \
    ! -iname '*.png' ! -iname '*.jpg' ! -iname '*.jpeg' ! -iname '*.heic' ! -iname '*.heif' -print \
    | LC_ALL=C sort
}

# ----- numbering helpers -----
calc_img_numbering() {
  local d="$1"

  local maxnum=0
  local pad="$PAD_DEFAULT"

  # remember nocasematch state and enable it
  local old_ncm
  if shopt -q nocasematch; then old_ncm=1; else old_ncm=0; fi
  shopt -s nocasematch

  # BSD/macOS-safe: no -printf/-iregex; use -print0 and parse
  local f name
  while IFS= read -r -d '' f; do
    name="${f##*/}"  # basename
    # match numeric filename with png/jpg/jpeg (case-insensitive)
    if [[ "$name" =~ ^[0-9]+\.(png|jpg|jpeg)$ ]]; then
      local stem="${name%.*}"
      local n=$((10#$stem))
      (( n > maxnum )) && maxnum=$n
      local w=${#stem}
      (( w > pad )) && pad=$w
    fi
  done < <(find "$d" -maxdepth 1 -type f -print0 2>/dev/null)

  # restore nocasematch
  (( old_ncm == 1 )) || shopt -u nocasematch

  local start=$(( (maxnum > 0 ? maxnum : 0) + 1 ))
  # IMPORTANT: print a trailing newline so read never chokes
  printf '%d %d\n' "$start" "$pad"
}

unique_copy() { # src dest_dir -> prints final path
  local src="$1" dest="$2" base name ext cand i=1
  base="$(basename "$src")"; name="${base%.*}"; ext="${base##*.}"; cand="$dest/$base"
  while [ -e "$cand" ]; do cand="$dest/${name}_$i.$ext"; i=$((i+1)); done
  if ((DRY)); then info "(dry-run) copy $src -> $cand"; else cp -f "$src" "$cand"; fi
  printf "%s" "$cand"
}

ingest_images() {
  local src="$1" recurse="$2" keep="$3"

  # collect candidates (BSD-safe find)
  local maxdepth=(-maxdepth 1)
  [[ "$recurse" == "1" ]] && maxdepth=()
  mapfile -t inputs < <(find "$src" "${maxdepth[@]}" -type f \
     \( -iname '*.heic' -o -iname '*.heif' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
     -print | LC_ALL=C sort)

  info "Images to ingest: ${#inputs[@]} from $(abspath "$src")"

  # none found → return cleanly (don’t kill the script)
  if ((${#inputs[@]} == 0)); then
    info "No image candidates found in $(abspath "$src")"
    return 0
  fi

  # numbering (robust to IFS setting)
  local start width seq outnums
  outnums="$(calc_img_numbering "$images_dir" || true)"

  if [[ -z "$outnums" ]]; then
    warn "calc_img_numbering produced no output; defaulting to start=1 pad=$PAD_DEFAULT"
    start=1
    width=$PAD_DEFAULT
  else
    # your script sets IFS to newline+tab; use a plain space here for splitting
    local OLDIFS="$IFS"
    IFS=' '
    read -r start width <<< "$outnums"
    IFS="$OLDIFS"
    # guard non-numerics
    [[ "$start" =~ ^[0-9]+$ ]] || start=1
    [[ "$width" =~ ^[0-9]+$ ]] || width=$PAD_DEFAULT
  fi

  seq=$start
  info "Numbering computed: start=$start, pad=$width"
  info "Numbering starts at: $(printf '%0*d' "$width" "$seq") (pad $width)"

  # process each file
  local f ext lc out
  for f in "${inputs[@]}"; do
    ext="${f##*.}"
    lc="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    out="${images_dir}/$(printf '%0*d' "$width" "$seq").png"
    info "Processing: $f -> $out (ext=$lc)"

    if [[ "$lc" = "heic" || "$lc" = "heif" ]]; then
      if [[ -z "$IM_CMD" || $heic_ok -ne 1 ]]; then
        warn "Skipping HEIC (no ImageMagick+libheif): $f"
        continue
      fi
      if (( DRY )); then
        info "(dry-run) HEIC -> $out"
      else
        if (( keep )); then
          if ! "$IM_CMD" "$f" "$out"; then warn "Convert failed: $f"; continue; fi
        else
          if ! "$IM_CMD" "$f" -strip "$out"; then warn "Convert failed: $f"; continue; fi
        fi
        info "Wrote $out"
      fi

    elif [[ "$lc" = "jpg" || "$lc" = "jpeg" ]]; then
      if [[ -z "$IM_CMD" ]]; then
        warn "No ImageMagick; cannot convert JPG->PNG. Skipping: $f"
        continue
      fi
      if (( DRY )); then
        info "(dry-run) JPG -> $out"
      else
        if (( keep )); then
          if ! "$IM_CMD" "$f" "$out"; then warn "Convert failed: $f"; continue; fi
        else
          if ! "$IM_CMD" "$f" -strip "$out"; then warn "Convert failed: $f"; continue; fi
        fi
        info "Wrote $out"
      fi

    elif [[ "$lc" = "png" ]]; then
      if (( DRY )); then
        info "(dry-run) copy PNG -> $out"
      else
        # BSD cp: no '--'
        if ! cp -f "$f" "$out"; then warn "Copy failed: $f"; continue; fi
        info "Wrote $out"
      fi

    else
      warn "Unsupported image type, skipping: $f"
      continue
    fi

    # increment after successful branch
    seq=$((seq+1))
  done
}

ingest_files() {
  local src="$1" recurse="$2"
  local maxdepth=(-maxdepth 1); [[ "$recurse" == "1" ]] && maxdepth=()
  mapfile -t inputs < <(find "$src" "${maxdepth[@]}" -type f ! -name '.*' -print | LC_ALL=C sort)
  info "Files to ingest: ${#inputs[@]} from $(abspath "$src")"
  for f in "${inputs[@]}"; do
    case "${f,,}" in *.png|*.jpg|*.jpeg|*.heic|*.heif) continue ;; esac
    unique_copy "$f" "$files_dir" >/dev/null
  done
}

# Optional ingest
[[ -n "$FROM_IMG"  ]] && { [[ -d "$FROM_IMG"  ]] || { err "--from-images not a dir"; exit 1; }; ingest_images "$FROM_IMG"  "$RECURSE" "$KEEP_EXIF"; }
[[ -n "$FROM_FILES" ]] && { [[ -d "$FROM_FILES" ]] || { err "--from-files not a dir";  exit 1; }; ingest_files  "$FROM_FILES" "$RECURSE"; }


# Build YAML sections only when non-empty
build_images_yaml() {
  if ((${#imgs_abs[@]}==0)); then return 0; fi
  printf "images:\n"
  local first=""
  for p in "${imgs_abs[@]}"; do
    local rel="${p#assets/}"
    printf "  - /assets/%s\n" "$rel"
    [[ -z "$first" ]] && first="/assets/${rel}"
  done
  # echo poster path to stdout fd3 for capture
  printf "%s" "$first" >&3
}
build_downloads_yaml() {
  if ((${#files_abs[@]}==0)); then return 0; fi
  printf "downloads:\n"
  for p in "${files_abs[@]}"; do
    local rel="${p#assets/}"
    local name; name="$(basename "$p")"
    printf "  - label: \"%s\"\n    url: /assets/%s\n" "$name" "$rel"
  done
}

# ----- build images/downloads explicitly (no FD hacks) -----
# Re-scan assets
mapfile -t imgs_abs  < <(find "$images_dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print | LC_ALL=C sort)
mapfile -t files_abs < <(find "$files_dir"  -maxdepth 1 -type f ! -name '.*' ! -iname '*.png' ! -iname '*.jpg' ! -iname '*.jpeg' ! -iname '*.heic' ! -iname '*.heif' -print | LC_ALL=C sort)

poster_line=""
images_block=""
downloads_block=""
gallery_block=""

# images -> YAML + poster (first image)
if ((${#imgs_abs[@]} > 0)); then
  # Build a string that already contains real newlines
  images_block="$(
    {
      printf 'images:\n'
      for p in "${imgs_abs[@]}"; do
        rel="${p#assets/}"
        printf '  - /assets/%s\n' "$rel"
      done
    }
  )"
  first_rel="${imgs_abs[0]#assets/}"
  poster_line="poster: /assets/${first_rel}"
fi

# downloads -> YAML (real newlines)
if ((${#files_abs[@]} > 0)); then
  downloads_block="$(
    {
      printf 'downloads:\n'
      for p in "${files_abs[@]}"; do
        rel="${p#assets/}"
        fname="$(basename "$p")"
        printf '  - label: "%s"\n    url: /assets/%s\n' "$fname" "$rel"
      done
    }
  )"
fi

# images -> YAML + poster (first image)
if ((${#imgs_abs[@]} > 0)); then
  # Build a string that already contains real newlines
  gallery_block="$(
    {
      printf 'gallery:\n'
      for p in "${imgs_abs[@]}"; do
        rel="${p#assets/}"
        printf '  - /assets/%s\n' "$rel"
      done
    }
  )"
fi

# Only include sections that exist; never add empty stubs
if ((DRY)); then
  info "(dry-run) Front matter preview:"
  cat <<EOF
---
title: "${TITLE}"
date: ${DATE}
slug: ${SLUG}
collection: ${COLLECTION}
assets_dir: ${assets_dir_web}
images_dir: ${assets_dir_web}/images
files_dir: ${assets_dir_web}/files
${poster_line:+$poster_line}
${images_block}
${downloads_block}
${gallery_block}
tags: []
---
EOF
else
  cat > "$dest_md" <<EOF
---
title: "${TITLE}"
date: ${DATE}
slug: ${SLUG}
collection: ${COLLECTION}
assets_dir: ${assets_dir_web}
images_dir: ${assets_dir_web}/images
files_dir: ${assets_dir_web}/files
${poster_line:+$poster_line}
${images_block}
${downloads_block}
${gallery_block}
tags: []
---
EOF
  info "Wrote: $dest_md"
fi
