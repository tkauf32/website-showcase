---
title: "Mini Joshua Tree"
date: 2025-10-01
slug: mini-joshua-tree
collection: projects
assets_dir: /assets/projects/mini-joshua-tree
images_dir: /assets/projects/mini-joshua-tree/images
files_dir: /assets/projects/mini-joshua-tree/files
poster: /assets/projects/mini-joshua-tree/images/001.png
images:
  - /assets/projects/mini-joshua-tree/images/001.png
  - /assets/projects/mini-joshua-tree/images/002.png
  - /assets/projects/mini-joshua-tree/images/003.png
  - /assets/projects/mini-joshua-tree/images/004.png
  - /assets/projects/mini-joshua-tree/images/005.png
  - /assets/projects/mini-joshua-tree/images/006.png
  - /assets/projects/mini-joshua-tree/images/007.png
  - /assets/projects/mini-joshua-tree/images/jtree-shapexr-01.png
  - /assets/projects/mini-joshua-tree/images/jtree-shapexr-02.png
  - /assets/projects/mini-joshua-tree/images/jtree.png
gallery:
  - /assets/projects/mini-joshua-tree/images/001.png
  - /assets/projects/mini-joshua-tree/images/002.png
  - /assets/projects/mini-joshua-tree/images/003.png
  - /assets/projects/mini-joshua-tree/images/004.png
  - /assets/projects/mini-joshua-tree/images/005.png
  - /assets/projects/mini-joshua-tree/images/jtree.png
tags: ["3dp","tree","national parks","joshua tree","nature","hiking"]
---

To be honest with you, I had no clue what a Joshua Tree was, let alone how freaking awesome they are. My buddy out in Southern California (~So Cal~ to the natives) inisted we go hiking out there. I'm down. I want to see all the National Parks. So we went out. And, damn, was I blown away. Joshua Trees are these bristled, twisted, alien-like pieces of nature. At a glance their bark looks bushy, almost appears as if you can to brush your fingers through it. But when you get up close, I wouldn't suggest it. That flowy mane is actually a armour shrouded in pointy wooden swords. In Spanish, they are referred to as *izote de desierto* aka the "desert dagger". I guess it makes sense given the environment the trees survive in. If you're molded by the harsh conditions of the Mojave/Colorado Deserts and you live to tell the tale, you're probably gonna have a pretty otherworldy elevator pitch. 

But even in what we may consider terrible circumstances, life thrives. It prevails. And I feel like we should take that as inspiration. Anywho, on the hike, we were talking about how incredible it would be to capture your own mini Joshua tree. Like to take a little part of Josh home. Have a little tree on your desk, or in a planter. Like Josh but Bonsai. I don't know much about plants, but I don't think this is possible. Though, I do know a thing or two about 3D Printing. 

One of my billion unfinished pseudo side projects is one where I am trying to 3D scan objects in National Parks and then 3D print them at home. Printing 3D Scanned objects from your phone can be quite the post-processing-manual-intervention type of project. Literally all I can scan and print without intensive effort in data collection, cleaning up meshes, and optimizing for 3dp are big rocks and specific, continuous, non complex objects like a statue or sign. 

<div class="img-row">
  <figure>
    <img src="{{ page.images[5] }}" alt="poses">
    <figcaption>NeRF Pose Failure</figcaption>
  </figure>
  <figure>
    <img src="{{ page.images[9] }}" alt="poses">
    <figcaption>Frame from Video</figcaption>
  </figure>
</div>

So trying to capture the J Trees was merely not worth it. I Actually attempted to run a NeRF (Neural Radiance Field) on a video I took of my favorite tree, but the first few runs didn't turn out well, and I'm not particularly aiming to take a deep dive into of turning 2D image sets -> 3D Models (See screenshot where 0.60% -- yes less than 1% of my 3000 images -- had poses). While staring at the trees in the park, I realized the best bet for a mini model is a ground up approach. 

<div class="img-row">
  <figure>
    <img src="{{ page.images[8] }}" alt="poses">
    <figcaption>premium angle of tree sculpture</figcaption>
  </figure>
  <figure>
    <img src="{{ page.images[7] }}" alt="poses">
    <figcaption>even more premium angle of tree sculpture</figcaption>
  </figure>
</div>

To be honest with you, I kinda suck at designing in Blender. Like I can get things in, scale, move them around, texture and color a bit, play with some plugins, but I am far from whipping up pretty models in O(n*log(n)) time. But I've been loving my Meta Quest 3 Lately, and playing with ShapeXR. It is kinda like 3D painting/scuplting in thin air. And I think this is a good start to my project. I played around, got a feel for it, and I will revisit this post with more details one the project soon!


-**TK**

