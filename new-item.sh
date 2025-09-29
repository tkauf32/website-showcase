#!/usr/bin/env bash
set -euo pipefail

# new-collection.sh — create a new Jekyll page/post skeleton
# Creates:
#   1) _<collection>/<slug>.md
#   2) assets/<collection>/<slug>/files
#   3) assets/<collection>/<slug>/images
#
# Template source (if present):
#   assets/<collection>/template.md
#
# Safe placeholder replacements inside template (optional):
#   {{slug}}, {{collection}}, {{date}}, {{title}}
#
# Usage:
#   ./new-item.sh <type> <slug>
#   ./new-item.sh --force project my-cool-thing
#   ./new-item.sh           # prompts for missing inputs
#
# <type> may be:
#   1|pj|project|projects
#   2|pd|product|products
#   3|lk|link|links
#   4|pt|printable|printables
#
# Exit codes:
#   0 ok, 1 usage/validation error, 2 refused to overwrite without --force

show_usage() {
  cat <<'EOF'
Usage: new-item.sh [--force] <TYPE> <SLUG>

Create Jekyll skeleton for a new item:
  1) _<collection>/<slug>.md
  2) assets/<collection>/<slug>/files
  3) assets/<collection>/<slug>/images

TYPE options:
  1|pj|project|projects
  2|pd|product|products
  3|lk|link|links
  4|pt|printable|printables

Flags:
  --force   Overwrite existing destination .md if it exists
  -h, --help  Show help

If TYPE or SLUG are omitted, you'll be prompted.
EOF
}

force_overwrite=false
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_usage; exit 0
fi
if [[ "${1:-}" == "--force" ]]; then
  force_overwrite=true
  shift || true
fi

prompt() {
  local msg="$1"; local def="${2:-}"
  if [[ -n "$def" ]]; then
    read -r -p "$msg [$def]: " ans || true
    echo "${ans:-$def}"
  else
    read -r -p "$msg: " ans || true
    echo "$ans"
  fi
}

normalize_type() {
  # input -> collection (no underscore)
  local t="$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^_//')"
  case "$t" in
    1|pj|project|projects) echo "projects" ;;
    2|pd|product|products) echo "products" ;;
    3|lk|link|links)       echo "links" ;;
    4|pt|printable|printables) echo "printables" ;;
    *) echo "" ;;
  esac
}

TYPE_IN="${1:-}"
SLUG="${2:-}"

if [[ -z "$TYPE_IN" ]]; then
  echo "Select type:"
  echo "  1) projects    2) products    3) links    4) printables"
  TYPE_IN="$(prompt 'Enter type (number or name)')"
fi
COLLECTION="$(normalize_type "$TYPE_IN" || true)"

if [[ -z "$COLLECTION" ]]; then
  echo "Error: Invalid TYPE '$TYPE_IN'." >&2
  show_usage
  exit 1
fi

if [[ -z "$SLUG" ]]; then
  SLUG="$(prompt 'Enter the slug (e.g., my-new-page)')"
fi

if [[ -z "$SLUG" ]]; then
  echo "Error: SLUG is required." >&2
  exit 1
fi

# Paths
jekyll_dir="_${COLLECTION}"
asset_base="assets/${COLLECTION}"
item_asset_dir="${asset_base}/${SLUG}"
files_dir="${item_asset_dir}/files"
images_dir="${item_asset_dir}/images"
template_src="${asset_base}/template.md"
dest_md="${jekyll_dir}/${SLUG}.md"

echo "Creating new item:"
echo "  collection : ${COLLECTION}"
echo "  slug       : ${SLUG}"
echo "  markdown   : ${dest_md}"
echo "  assets     : ${files_dir} & ${images_dir}"
echo

# Create directories
mkdir -p "$jekyll_dir"
mkdir -p "$files_dir" "$images_dir"

# Create or copy markdown
today="$(date +%Y-%m-%d)"
title_guess="$(echo "$SLUG" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')"

if [[ -e "$dest_md" && "$force_overwrite" != true ]]; then
  echo "Refusing to overwrite existing file: $dest_md (use --force to overwrite)" >&2
  exit 2
fi

if [[ -f "$template_src" ]]; then
  # Copy template and replace known placeholders if present
  tmp="$(mktemp)"
  cp "$template_src" "$tmp"
  # Only change placeholders if they exist; otherwise content remains intact.
  sed -i.bak \
    -e "s/{{slug}}/${SLUG}/g" \
    -e "s/{{collection}}/${COLLECTION}/g" \
    -e "s/{{date}}/${today}/g" \
    -e "s/{{title}}/${title_guess}/g" \
    "$tmp"
  rm -f "${tmp}.bak"
  mv "$tmp" "$dest_md"
  echo "Created from template: $template_src -> $dest_md"
else
  # Minimal default front matter when no template exists
  cat > "$dest_md" <<EOF
---
layout: ${COLLECTION%?}   # [Unverified] adjust as needed (e.g., 'project')
title: "${title_guess}"
date: ${today}
slug: ${SLUG}
collection: ${COLLECTION}
assets_dir: /assets/${COLLECTION}/${SLUG}
---

<!-- Content goes here. Replace with your own template at assets/${COLLECTION}/template.md -->
EOF
  echo "[Unverified] No template found at ${template_src}. Wrote minimal front matter to ${dest_md}."
fi

echo
echo "Done."
