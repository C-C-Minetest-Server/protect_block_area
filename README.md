# Protector Blocks for Area Protection Mod
This mod provides a block that works like the one in [Protector Redo](https://content.minetest.net/packages/TenPlus1/protector/), but create areas based on the [Area Protection Mod](https://content.minetest.net/packages/ShadowNinja/areas/) instead.

Therefore, players who don't know how to use the commands provided by the Area Protection Mod can now use the protector block to do the same job, without installing two protection mods.

This mod merges the user experience of the two mods, so players can use the Protector Blocks just like the one provided by Protector Redo. Though, this is not a drop-in replacement. When installing this mod, it's not recommended to uninstall Protector Redo.

This mod optionally depends on the Protector Redo mod *only* to avoid crafting recipe confidence, and *not* using any of its APIs.

## Behaviour copied from Protector Redo
Users can place the protector node at the middle of the area, then the system will create an area for the player (11x11x11 by default, which share the same setting key `protector_radius`) if he/she can protect it.

When a user punch a protector node, the corresponding area is selected, just like the result of `/select_area`. In addition, if the area is removed when the user punch it, the protector node will self-destruct.

When a protector is removed by its owner, the ares is also removed.


