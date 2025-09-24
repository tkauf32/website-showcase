# Scrappy Catalog (Jekyll + Pagefind + 3D Viewer)

A tiny, static catalog for **prints**, **products**, and **links** with:
- GLB viewer via `<model-viewer>` (and STL fallback via three.js)
- Simple client-side filtering on index
- Pagefind-powered full-site search (build step)

## Requirements
- Ruby & Bundler
- Node.js & npm

## Setup
```bash
bundle install
npm i
```

## Develop
```bash
npm run dev
# open http://localhost:4000
```

> Dev mode does not run Pagefind. Use `build:search` to generate the search index.

## Build + Search Index
```bash
npm run build:search
# outputs to _site/, including /pagefind assets
```

## Content Model
Three collections in `_config.yml`:
- `prints/`  → 3D models, print specifics
- `products/` → reviews/notes, optional affiliate link
- `links/` → curated resources

Each item supports front-matter fields:
```yaml
title: "Example"
tags: ["tag1","tag2"]
poster: /models/example.jpg

# viewer (one of)
model_url: /models/example.glb   # GLB/GLTF (preferred)
# stl_url: /models/example.stl   # raw STL fallback

# optional
printer: "Bambu X1C"
material: "PETG"
time_to_print: "3h 10m"
rating: 4.5
affiliate_url: "https://..."
download_url: /models/example.glb
```

## 3D Viewer
- Preferred: convert STL → GLB (via Blender), then **compress** with `gltfpack`:
  ```bash
  gltfpack -i input.glb -o output.glb -cc -tc
  ```
- For pages with only STL, remove `model_url` and set `stl_url` instead.

## Notes
- Replace placeholders in `/models/` with your real `*.glb` / `*.stl` / poster image.
- You can host large files on S3/Backblaze and point `model_url`/`download_url` to absolute URLs.
- Pagefind assets are written to `_site/pagefind/` during `build:search`.
