# PixelLab Prompt - Ruins of Veld Object Refresh

**Status:** Prompt only  
**Scope:** Regenerate Ruins of Veld decorative object sprites with PixelLab  
**Do not regenerate:** `devourer_omen_landmark.png`  
**Implementation rule:** Preserve the existing filenames and dimensions so `world/zones/ruins_of_veld/ruins_of_veld.tscn` keeps working without scene edits.

---

## Goal

Recreate every decorative object in `assets/tilesets/ruins_of_veld/objects/` except the Devourer Omen landmark. The new objects should look like one coherent Ruins of Veld object set: ancient botanical research-city ruins, weathered gray-brown stone, dead roots, muted moss, and restrained purple-black void corruption.

Only replace the object PNGs listed below. Keep the Ruins of Veld terrain tilesets, floor tilemap, scene layout, collision, resource placement, and Devourer Omen landmark unchanged.

---

## Files To Regenerate

Regenerate these exact files in place:

| File | Canvas | Notes |
|---|---:|---|
| `assets/tilesets/ruins_of_veld/objects/broken_archway.png` | 48x48 | Broken 2-tile-wide archway remnant |
| `assets/tilesets/ruins_of_veld/objects/collapsed_pillar.png` | 48x32 | Fallen fluted column segment |
| `assets/tilesets/ruins_of_veld/objects/inscribed_floor_tile.png` | 32x32 | Single carved floor slab |
| `assets/tilesets/ruins_of_veld/objects/irrigation_channel.png` | 48x32 | Dry carved stone channel |
| `assets/tilesets/ruins_of_veld/objects/ruined_planter_box.png` | 32x32 | Cracked botanical planter |
| `assets/tilesets/ruins_of_veld/objects/void_rubble_pile.png` | 48x48 | Rubble with void crystal growth |

Do not change:

```text
assets/tilesets/ruins_of_veld/objects/devourer_omen_landmark.png
assets/tilesets/ruins_of_veld/ruins_terrain.tres
assets/tilesets/ruins_of_veld/*.png outside objects/
world/zones/ruins_of_veld/ruins_of_veld.tscn
```

Because `ruins_of_veld.tscn` already references the object PNG paths directly, replacing these files in place implements the refreshed objects into the world immediately. Do not rename files and do not move them to a new folder.

---

## PixelLab Workflow

Use PixelLab MCP for each object.

Preferred tool:

```text
create_map_object
```

Use exact `width` and `height` for each target file. Use `view = "high top-down"`, `detail = "medium detail"`, `outline = "selective outline"`, and `shading = "medium shading"` unless PixelLab produces noisy details; if that happens, drop to `basic shading`.

If PixelLab cannot produce a clean non-square object for the 48x32 assets, generate on a 48x48 or 64x64 transparent canvas, then crop and normalize back to the required final size without smoothing.

After saving each replacement:

1. Confirm the PNG is `RGBA`.
2. Confirm the final dimensions exactly match the table above.
3. Confirm alpha is transparent outside the object silhouette.
4. Remove or overwrite the old object image in the same path.
5. Do not manually edit `.import` or `.uid` files unless Godot import requires it.
6. Run a Godot editor import pass if available so the textures resolve through `res://`.

---

## Global Pixel-Art Rules

Use these rules in every PixelLab prompt:

```text
Strict pixel art object sprite for a 2D top-down Godot survival-crafting game. Transparent background. No anti-aliasing. No blur. No soft gradients. No painterly rendering. No 3D render. Hard pixel edges. Limited palette. Selective 1-pixel dark outline on important silhouette edges. High top-down RPG perspective. Readable at in-game size. No text, no labels, no numbers, no UI, no arrows, no watermarks, no visible grid.

Art direction: Ruins of Veld, an ancient botanical research city destroyed by void corruption. Weathered desaturated gray-brown sandstone, chipped carved stone, dead root tendrils, dark moss and lichen, dry soil in cracks, restrained purple-black void veins and crystal growths. Dim, heavy, old atmosphere. Match the existing 16x16 terrain scale and do not look brighter or cleaner than the current Ruins of Veld tileset.

Palette guide: outline #1F1A17, deep shadow #2A2520, stone dark #423B33, stone mid #6E6457, stone light #9E9180, soil #33291F, dead root #5C472E, moss #3B5432, lichen #4D6B3E, void dark #1A0E28, void purple #2E1640, void accent #6B3A8A. Avoid pure black, pure white, bright saturated green, bright purple glow, or clean cartoon stone.
```

---

## Individual Object Prompts

Generate one object at a time. Paste the global rules, then paste the relevant object section.

### 1. Broken Archway

Output file: `broken_archway.png`  
Canvas: `48x48`

```text
Create a 48x48 transparent pixel-art sprite: broken stone archway remnant from an ancient botanical ruin.

The object should read as a collapsed 2-tile-wide doorway or gate fragment. One side pillar remains taller and more intact, the opposite pillar is shorter and jagged. A few broken arch stones curve across the top but the center is open. Add weathered carved seams, chipped corners, small fallen stones at the base, and dark root tendrils crawling over the upper stones. Add muted moss on shadow edges. Add only a few subtle purple-black void cracks in the stone; this is still mostly old sandstone, not a glowing portal.

Keep the silhouette readable from gameplay distance. Leave 2-4 pixels of transparent padding where possible. Do not include a floor tile under it, doorway interior, character, text, or large magical aura.
```

### 2. Collapsed Pillar

Output file: `collapsed_pillar.png`  
Canvas: `48x32`

```text
Create a 48x32 transparent pixel-art sprite: collapsed fluted stone pillar lying horizontally on ruined ground.

The pillar should be a broken cylindrical column segment viewed from high top-down angle, angled slightly left-to-right across the canvas. Show fluting grooves, chipped circular end caps, cracked stone bands, and two or three small rubble chunks around it. Add muted moss along the lower shadow side and a few dead roots wrapped around the cracks. Include tiny purple-black void staining inside one crack only, not a large glow.

The object must occupy most of the 48x32 canvas while keeping transparent background around the silhouette. Do not make it a standing pillar, wall, tree trunk, UI icon, or generic log.
```

### 3. Inscribed Floor Tile

Output file: `inscribed_floor_tile.png`  
Canvas: `32x32`

```text
Create a 32x32 transparent pixel-art sprite: single ancient inscribed floor slab.

The object is a square weathered stone tile with a faint botanical research diagram carved into it: circular diagram lines, tiny leaf or root motifs, and worn intersecting guide marks. The carvings should be subtle stone-highlight pixels, not readable text or symbols. Add chipped corners, dirt in seams, a hairline crack, and a small muted void stain creeping from one corner.

This should remain a low floor object that can sit on top of the current Ruins of Veld terrain. Do not add a background floor, frame, UI border, readable letters, or bright magic circle.
```

### 4. Irrigation Channel

Output file: `irrigation_channel.png`  
Canvas: `48x32`

```text
Create a 48x32 transparent pixel-art sprite: ancient dry irrigation channel carved into a stone slab.

The object is a long rectangular carved stone channel, slightly top-down. The center groove is dry and dark, with cracked residue where water once flowed. Add worn bevels on the stone rim, dark soil caught in the channel, tiny broken corners, and a few dead roots crossing the groove. Add restrained purple-black residue in the channel to show void contamination. The void detail should be subtle and pooled in cracks, not a bright stream.

The sprite should feel like infrastructure from a ruined botanical city. Do not make it a modern pipe, river, blue water channel, UI panel, or full floor tile strip.
```

### 5. Ruined Planter Box

Output file: `ruined_planter_box.png`  
Canvas: `32x32`

```text
Create a 32x32 transparent pixel-art sprite: ruined stone planter box from an ancient botanical research city.

The planter is a cracked rectangular stone trough viewed high top-down. It has chipped thick stone walls, dark soil inside, dead root tangles, a few fossilized leaf shapes, and muted moss on one edge. Include one small purple-black void stain in the soil and a few tiny corrupted root pixels, but keep the object mostly stone and dead botanical matter.

The silhouette must read clearly as a planter, not a crate, coffin, altar, or chest. Leave transparent background around it. Do not include flowers, bright healthy plants, UI text, or a full floor tile underneath.
```

### 6. Void Rubble Pile

Output file: `void_rubble_pile.png`  
Canvas: `48x48`

```text
Create a 48x48 transparent pixel-art sprite: pile of broken ruin stones corrupted by void growth.

The object is a cluster of fallen sandstone chunks, shattered carved slabs, and small debris. Several stones have thin purple-black veining. Add two or three small dark void crystal growths emerging from cracks, with very restrained purple highlights. Include muted moss and dead roots competing with the corruption so the object fits the botanical ruin theme.

The pile should have an irregular natural silhouette and strong readable contrast. Keep it grounded as map decor, not a magical portal, enemy, ore icon, or bright crystal collectible. No large glow, no smoke, no background floor.
```

---

## Replacement And Cleanup Instructions

After PixelLab generation:

1. Save each approved PNG directly over the matching old file in `assets/tilesets/ruins_of_veld/objects/`.
2. Keep the six filenames and exact dimensions unchanged.
3. Leave `devourer_omen_landmark.png` untouched.
4. Delete any temporary candidate files, alternate exports, or scratch folders created during generation.
5. Keep terrain tilesets unchanged. Do not edit `ruins_terrain.tres`, the `earth_to_*` / `stone_to_*` tiles, or any files outside the `objects/` folder unless the user explicitly expands scope.
6. Run a focused static check:

```powershell
@'
from pathlib import Path
from PIL import Image
expected = {
    "broken_archway.png": (48, 48),
    "collapsed_pillar.png": (48, 32),
    "inscribed_floor_tile.png": (32, 32),
    "irrigation_channel.png": (48, 32),
    "ruined_planter_box.png": (32, 32),
    "void_rubble_pile.png": (48, 48),
}
base = Path("assets/tilesets/ruins_of_veld/objects")
for name, size in expected.items():
    path = base / name
    with Image.open(path) as img:
        assert img.mode == "RGBA", f"{name}: expected RGBA, got {img.mode}"
        assert img.size == size, f"{name}: expected {size}, got {img.size}"
        print(f"{name}: OK {img.size} {img.mode}")
'@ | python -
```

7. Run a focused scene reference check:

```powershell
rg -n "broken_archway|collapsed_pillar|inscribed_floor_tile|irrigation_channel|ruined_planter_box|void_rubble_pile|devourer_omen_landmark" world/zones/ruins_of_veld/ruins_of_veld.tscn
```

8. If Godot is available, run an editor import pass:

```powershell
godot --headless --editor --path . --quit
```

If `godot` is not on `PATH`, try `godot4`, then inspect `.godot/editor/project_metadata.cfg` for the editor executable path.

---

## Acceptance Criteria

- The six listed Ruins of Veld object PNGs are replaced with PixelLab-generated artwork.
- `devourer_omen_landmark.png` is not modified.
- Terrain tilesets and TileSet resources are not modified.
- All replacement PNGs keep their original filenames, exact dimensions, transparent background, and `RGBA` mode.
- The replacements visually match the current Ruins of Veld terrain: desaturated stone, old botanical ruin details, and restrained void corruption.
- `world/zones/ruins_of_veld/ruins_of_veld.tscn` needs no path or node edits because the same filenames are reused.
