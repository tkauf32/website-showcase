mkdir -p _printables/lego-f1-frame
cat > _printables/lego-f1-frame/index.md <<'MD'
---
title: "LEGO F1 Frame (Wall Art Clip)"
tags: ["lego","wall-art","petg"]
poster:

# If you have GLB later, switch to model_url
# model_url: /assets/printables/lego-f1-frame/files/clip.glb
stl_url: /assets/projects/lego-f1-frame/files/Lego-F1-Speed-Champions-Car-Wall-Mount.stl

downloads:
  - label: "Bambu 3MF"
    url: /assets/printables/lego-f1-frame/files/Lego-F1-Frame-Wall-Art.3mf
  - label: "STL"
    url: /assets/projects/lego-f1-frame/files/Lego-F1-Speed-Champions-Car-Wall-Mount.stl

printer: "Bambu X1C"
material: "PETG"
layer_height: "0.2 mm"
nozzle: "0.4 mm"
supports: "No"
infill: "15% Gyroid"
time_to_print: "—"
rating: 4.5
---

One-paragraph summary; orientation & tips.
MD
