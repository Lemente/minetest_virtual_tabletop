
## Landscape Shaping

This mod add various tools with God-like power to reshape the landscape.
This is meant for creative mode, so those *magic wands* have no crafting recipe yet.

Also, **you should backup your world** before using this, because a mistake can really mess things up.

Current magic wands:

* **Transmute wand:** left click copy a node, right click change pointed node into the copy node, existing rotation is preserved
* **Blow wand:** blow nodes away, left click is like TNT, blowing away anything within the radius, right-click do the same but only for the upward hemisphere instead
  of the whole sphere, the later is useful to flatten an area
* **Flat hemisphere wand:** fill the downward hemisphere with the pointed node's type (left-click) or the copied node (right-click), useful to fill holes
* **Flat square wand:** fill the area of a thin horizontal square at the y-level of the pointed node, with the pointed node's type (left-click)
  or the copied node (right-click), useful to pave things quickly
* **Water wand:** left-click: remove all water around (sphere), right-click create a water hemisphere
* **Lava wand:** works like the water wand for lava
* **Fall wand:** all nodes within the radius will fall if there isn't anything solid below. Beware, in-range cavern will collapse! Non-blocky things that receive
  the falling node will be destroyed (snow slabs, grass, ...)
* **Cover wand:** cover the landscape within the radius with a layer of dirt (left-click) or a layer of the copied node (right-click)
* **Smooth wand:** smooth the heightmap of the surrounding landscape, left-click: smooth just a bit (just one smooth pass),
  right-click: smooth more (multiple pass depending on the current wand radius, each pass average with 20 neighbors instead of the 8 closest).
  Grass and things like snow slabs are preserved in the process, for each voxel on top of the heigtmap, two voxels above and two voxels
  below are preserved (they move along), but don't mess with trees!

