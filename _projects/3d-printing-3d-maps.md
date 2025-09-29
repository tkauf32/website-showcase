---
title: "3D Printing 3D Maps"
slug: "project-template"
poster: /assets/projects/3d-printing-3d-maps/images/blender-skyline.png
tags: ["art", "3d-print","3d-maps","maps","blender","osm","openstreetmap","wall-art", "3d-tiles", "download", "gltf", "glb"]
printer: "Bambu X1C"
material: "PLA"
ams: "No"
models:
  - title: "Chicago"
    src: /assets/projects/3d-printing-3d-maps/files/Chicago.glb
    type: glb
    yaw: 0
# time_to_print: "3h 19m"
# rating:
# poster: /assets/projects/lego-f1-frame/images/poster.jpg
# downloads:
#   - label: "Bambu 3MF"
#     url: /assets/projects/
#   - label: "STL"
#     url: /assets/projects/
---

I've seen 3D printed 3D maps of cities all over the internet. The files are paywalled and the off the shelf printed product prices are often pretty jacked up. I wanted to print my own city, tailored to my likings. This triggered my first meander through the 3D Maps realm. Which is kind of daunting if you're an outsider. The skillset required to obtain proper 3D maps, of anywhere in the world, cleaned up in nice, in a realiable 3MF format is a bit more niche than I thought. 

Luckily, I have found a neat workflow that seems to work well enough to get the job done. 

I was working on a project for work related to 3D Renders of buildings (aka 3D Tiles). Let me tell you, the Geodetic 3D Maps rabbit hole is deeper than you may think. It took some time, but I got a pretty good grip on the general file formats, data structures, data sources and useful tools in the Geodetic 3D maps space. I struggled through the process so you don't have to. 


We are going to need a few pre reqs for this project. 

- Maps Source (Open Street Map, Google Maps API Key)
- Blender (latest)
- Blosm (Blender Open Street Map)


Okay lets just give a brief overview so we know why we are doing what. You need a source for 3d tile data. Google has 3D tiles available from an API key. I think they built it using satellite images and photogrammetry from google maps. Gotta fact check. Anywho, these are nice for enhanced precision and colored 3D tiles. For our use case, there is an alternative Open Street Maps (OSM)! OSM is publicly available and will be perfect for our use case. 

Next is Blender Open Street Maps (BLOSM). Blosm is a blender plugin built by some cool people for using real world 3D maps data in blender. The use cases are essentially endless. Most use it for video games, some for renders, some like us for 3D printing. 
