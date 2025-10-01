---
title: "Ikea 3D Model Downloader"
tags: ["ikea", "3d","blender","glb","gltf","furniture","cad"]

poster: /assets/projects/ikea-downloader/images/poster.png

models:
  - title: "Ikea ALEX Drawer"
    src: /assets/projects/ikea-downloader/files/ikea-alex.glb
    type: glb
    yaw: 0
  - title: "Ikea Desk"
    src: /assets/projects/ikea-downloader/files/ikea-desk.glb
    type: glb
    yaw: 0

---

I found this really useful project on GitHub for downloading 3D files straight from Ikea's CDN. You can grab most files in a `.gltf` or `.glb` format — complete with textures — and they’re surprisingly dimensionally accurate. The project is super scrappy but clever. It works by using a browser userscript via [Tampermonkey](https://www.tampermonkey.net/) to inject a download button right onto Ikea’s product pages. Just click, download, and boom — you’ve got the model. They even provide a CLI tool if you want to batch pull entire catalogs, which is wild.  
👉 Repo here: [IKEA-3D-Model-Download-Button](https://github.com/apinanaivot/IKEA-3D-Model-Download-Button)

I originally stumbled across this because I wanted to design my room in Blender before buying and assembling a big Ikea desk. Once I saw how well it worked, I started pulling down whole catalogs of furniture and importing them into Blender for quick visualization.

I ended up doing this not just for my room, but also for a barbershop I was building out. It made the design process way faster since I could make changes on the fly and see the layout instantly. (I’ve got links to those projects over on my YouTube if you want to check them out.)

---

### Capturing the Space
Blender is an insanely powerful — and somehow free — tool for 3D modeling. For indoor spatial visualization though, you need some kind of model of your actual room. At first, I just measured things and manually built walls, windows, and doors in Blender. It worked, but it was tedious.  

Then I tried using Polycam on my iPhone to 3D scan the room. Exporting into `.usdz` made it easy to import into Blender. That saved a bunch of time and gave me a more “real” base to work with. But I wanted to take it even further.

---

### Full Immersion with VR
Enter the Meta Quest 3. Pure immersion. Recently, Meta even released support for exploring immersive Gaussian Splats (still on my to-try list). But what really caught my attention was seeing a TikTok of an artist sculpting in VR. That blew my mind.  

I went digging and found [ShapeXR](https://www.shapexr.com/) (that’s the actual app name I was reaching for). Flip on passthrough mode and you’re suddenly sketching and arranging 3D furniture inside your real environment. You can import the Ikea models, draw, rearrange — whatever your little heart wants. It’s like Blender, but in your living room.

---

### The Next Step
Naturally, my brain went: *what if I could build a Meta Quest app that lets you browse Ikea’s catalog, pick an item, and drop the 3D file directly into your VR space with one click?*  

That feels like the logical extension of this project — straight from Ikea’s CDN into your headset, no Blender middleman required.  

Not sure if I’ll build it, but it’s fun to imagine where this could go.

---

## 📂 Downloads
- [Ikea ALEX (GLB)](/assets/projects/ikea-downloader/files/ikea-alex.glb)  
- [Ikea Desk (GLB)](/assets/projects/ikea-downloader/files/ikea-desk.glb)

— **TK**
