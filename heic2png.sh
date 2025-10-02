#!/usr/bin/env bash
# Robust HEIC/HEIF -> PNG converter with sequential numbering & loud logs.
# Works in bash and zsh. Requires ImageMagick with HEIC support (libheif).
set -euo pipefail
IFS=$'\n\t'

# -------------------- Logging --------------------
ts() { date +"%Y-%m-%d %H:%M:%S"; }
log() { printf "[%s] [%s] %s\n" "$(ts)" "$1" "$2"; }
info() { log "INFO" "$1"; }
warn() { log "WARN" "$1" >&2; }
err()  { log "ERROR" "$1" >&2; }

# -------------------- Defaults & Flags --------------------
DRY_RUN=0
RECURSE=0
KEEP_EXIF=0
DEST=""
SRC_DIRS=()
WIDTH_DEFAULT=3
IM_CMD=""

usage() {
  cat <<EOF
Usage: $0 [options] [SRC_DIR ...]
Options:
  -d DIR   Destination directory for PNGs (will be created if missing).
  -r       Recurse into subfolders of source(s).
  -n       Dry-run (show what would happen; no files written).
  -K       Keep EXIF metadata (default strips metadata).
  -h       Help.

Examples:
  $0 -d ~/Pictures/Converted .           # prompt-like behavior; current dir as source
  $0 -r -d /tmp/out ~/DCIM ~/MorePhotos  # multiple sources, recursive
  $0 -n -d ./out .                       # dry-run to preview all actions

If no sources are provided, you'll be prompted for one. If no -d is provided, you’ll be prompted.
EOF
}

# -------------------- Parse Args --------------------
while getopts ":d:rnhK" opt; do
  case "$opt" in
    d) DEST="$OPTARG" ;;
    r) RECURSE=1 ;;
    n) DRY_RUN=1 ;;
    K) KEEP_EXIF=1 ;;
    h) usage; exit 0 ;;
    \?) err "Unknown option: -$OPTARG"; usage; exit 2 ;;
    :) err "Option -$OPTARG requires an argument."; usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
  SRC_DIRS=("$@")
fi

# Prompt if missing
if [ "${#SRC_DIRS[@]}" -eq 0 ]; then
  read -rp "Source directory (default '.'): " _S; _S=${_S:-.}
  SRC_DIRS=("$_S")
fi
if [ -z "$DEST" ]; then
  read -rp "Destination directory: " DEST
  if [ -z "$DEST" ]; then err "Destination is required."; exit 2; fi
fi

# -------------------- Helpers --------------------
abspath() {
  # 'readlink -f' not portable on macOS; do a POSIX-ish fallback
  # Usage: abspath <path> -> prints absolute path
  local p="$1"
  if [ -d "$p" ]; then
    (cd "$p" && pwd)
  else
    local d; d=$(dirname -- "$p")
    local f; f=$(basename -- "$p")
    (cd "$d" && printf "%s/%s\n" "$(pwd)" "$f")
  fi
}

# -------------------- Tool & Support Checks --------------------
if command -v magick >/dev/null 2>&1; then
  IM_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
  IM_CMD="convert"
else
  err "ImageMagick not found. Install it (e.g., 'brew install imagemagick libheif' or 'sudo apt install imagemagick libheif1')."
  exit 1
fi
info "Using ImageMagick command: $IM_CMD"

# Check HEIC support
if "$IM_CMD" -list format 2>/dev/null | grep -Ei '^\s*HEIC\b' >/dev/null; then
  info "HEIC support: detected."
else
  warn "HEIC support not detected. You may see 'no decode delegate' errors. Install libheif and ensure ImageMagick links against it."
fi

# -------------------- Resolve & Create Dest --------------------
DEST_ABS=$(abspath "$DEST")
info "Destination directory (resolved): $DEST_ABS"
if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p -- "$DEST_ABS"
  # Write test
  if ! ( tmpf=$(mktemp "$DEST_ABS/.wtest.XXXX") && rm -f "$tmpf" ); then
    err "Destination not writable: $DEST_ABS"
    exit 1
  fi
else
  info "(dry-run) Would create directory: $DEST_ABS (if missing)"
fi

# -------------------- Build Find Plan --------------------
MAXDEPTH_ARG=()
if [ "$RECURSE" -eq 0 ]; then
  MAXDEPTH_ARG=(-maxdepth 1)
fi

# -------------------- Determine starting index & pad width --------------------
# Find existing numeric pngs in DEST_ABS like 001.png, 12.png, 0005.png (case-insensitive)
existing_nums=$(
  find "$DEST_ABS" -maxdepth 1 -type f -iregex '.*/[0-9]+\.png' -printf '%f\n' 2>/dev/null | \
  sed -E 's/\.png$//I' || true
)

START=1
WIDTH=$WIDTH_DEFAULT
if [ -n "$existing_nums" ]; then
  MAXNUM=$(printf "%s\n" "$existing_nums" | sort -n | tail -1)
  MAXW=$(printf "%s\n" "$existing_nums" | awk '{print length}' | sort -n | tail -1)
  START=$((10#$MAXNUM + 1))
  WIDTH=$MAXW
fi
info "Numbering: start=$START, zero-pad width=$WIDTH (existing files considered)."

# -------------------- Collect Inputs --------------------
tempfile=$(mktemp)
trap 'rm -f "$tempfile"' EXIT

TOTAL_CANDIDATES=0
for dir in "${SRC_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    warn "Skipping non-directory source: $dir"
    continue
  fi
  SRC_ABS=$(abspath "$dir")
  info "Scanning source: $SRC_ABS  (recurse=$RECURSE)"
  # shellcheck disable=SC2086
  find "$SRC_ABS" "${MAXDEPTH_ARG[@]}" -type f \( -iname '*.heic' -o -iname '*.heif' \) -print0 >> "$tempfile"
done

if [ -s "$tempfile" ]; then
  TOTAL_CANDIDATES=$(tr -dc '\0' < "$tempfile" | wc -c | tr -d ' ')
  info "Found $TOTAL_CANDIDATES HEIC/HEIF file(s) to process."
else
  warn "No HEIC/HEIF files found in the provided source(s). Nothing to do."
  exit 0
fi

# -------------------- Convert Loop --------------------
SEQ=$START
COUNT_OK=0
COUNT_ERR=0
COUNT_SKIPPED=0

while IFS= read -r -d '' f; do
  # Next available output name in DEST_ABS
  while : ; do
    cand=$(printf "%s/%0*d.png" "$DEST_ABS" "$WIDTH" "$SEQ")
    if [ ! -e "$cand" ]; then break; fi
    SEQ=$((SEQ + 1))
  done

  info "Convert: src=$(abspath "$f") -> out=$cand"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "(dry-run) Would run: $IM_CMD \"$f\" ${KEEP_EXIF:+(keep EXIF)} -> $cand"
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
    SEQ=$((SEQ + 1))
    continue
  fi

  # Actual convert
  if [ "$KEEP_EXIF" -eq 1 ]; then
    if "$IM_CMD" "$f" "$cand"; then
      info "Wrote: $cand"
      COUNT_OK=$((COUNT_OK + 1))
      SEQ=$((SEQ + 1))
    else
      err "Failed converting: $f"
      COUNT_ERR=$((COUNT_ERR + 1))
    fi
  else
    if "$IM_CMD" "$f" -strip "$cand"; then
      info "Wrote: $cand"
      COUNT_OK=$((COUNT_OK + 1))
      SEQ=$((SEQ + 1))
    else
      err "Failed converting: $f"
      COUNT_ERR=$((COUNT_ERR + 1))
    fi
  fi
done < "$tempfile"

# -------------------- Summary --------------------
echo "------------------------------------------------------------"
info "Summary"
info "Destination: $DEST_ABS"
info "Sources: $(printf '%s ' "${SRC_DIRS[@]}")"
info "Converted OK: $COUNT_OK"
info "Errors:       $COUNT_ERR"
if [ "$DRY_RUN" -eq 1 ]; then
  info "Dry-run skips: $COUNT_SKIPPED"
fi
info "Next file would start at index: $SEQ (pad width $WIDTH)"
echo "------------------------------------------------------------"
