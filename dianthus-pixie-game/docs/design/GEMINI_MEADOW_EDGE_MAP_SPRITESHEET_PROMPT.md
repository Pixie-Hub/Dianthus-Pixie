# Gemini Image Generation Prompt - Meadow Edge Grass Tileset

Use this document as the image-generation prompt for Gemini. The goal is to create a **grass-only pixel-art tileset** for the Meadow Edge map in **Dianthus Pixie**, following the same terrain-atlas structure as the existing Sprout Lands reference sheets.

## Source References

Use these files as direct visual/layout references:

- `world/tilesets/Sprout Lands - Sprites - Basic pack/Grass.png`
- `world/tilesets/Sprout Lands - Sprites - Basic pack/Hills.png`
- `world/tilesets/Sprout Lands - Sprites - Basic pack/Bitmask references 1.png`
- `world/tilesets/Sprout Lands - Sprites - Basic pack/Bitmask references 2.png`

`Grass.png` is the main layout reference. `Hills.png` is a secondary reference for how the pack handles terrain edges, corners, vertical lips, and shaded sides. The bitmask reference images are the mask-shape guide: keep the same terrain silhouettes and autotile coverage pattern.

## Target Use

- Game: `Dianthus Pixie`
- Engine: Godot 4.6
- Scene target: `world/zones/meadow_edge/meadow_edge.tscn`
- Tile size: 16 x 16 pixels
- Intended use: grass terrain atlas for a Godot `TileSetAtlasSource`
- Output asset type: one PNG spritesheet
- Subject: grass only

## Main Prompt

```text
Create one grass-only pixel-art terrain tileset spritesheet for a 2D top-down Godot game called Dianthus Pixie.

The tileset must follow the structure and mask pattern of the existing Sprout Lands grass terrain atlas. Use Grass.png as the primary layout reference, Hills.png as the secondary terrain-edge reference, and Bitmask references 1.png / Bitmask references 2.png as the required bitmask silhouette guide.

Theme:
Warm, vibrant Meadow Edge grass at the border of a magical botanical garden. The grass should feel natural, fresh, slightly magical, and readable in a survival-crafting exploration map.

Technical output:
- Exactly one PNG image.
- Exact canvas size: 176 x 112 pixels.
- Exact grid: 11 columns x 7 rows.
- Each tile is exactly 16 x 16 pixels.
- No gutters, no spacing, no labels, no text, no numbers, no visible grid lines.
- Preserve the same occupied-cell / empty-cell structure as Grass.png.
- Preserve the same bitmask/autotile terrain silhouette pattern shown in the bitmask reference images.
- Empty or unused cells must be transparent, not black.
- Terrain cutout areas outside the grass mask must be transparent.
- The sheet must be easy to slice in Godot using 16 x 16 atlas coordinates.

Style rules:
- Strict pixel art.
- Pixel-perfect hard edges.
- No anti-aliasing.
- No blur.
- No soft gradients.
- No painterly texture.
- No sub-pixel rendering.
- Top-down / slightly angled top-down perspective matching Grass.png and Hills.png.
- Keep the readable rounded terrain-edge style of the reference sheets.
- Use the same visual logic as Grass.png: grass fills the terrain mask, edges are darker green, top surfaces have small grass-blade clusters and light speckles.
- Use the edge logic from Hills.png only as a shape reference; do not create brown cliffs, exposed dirt walls, rocks, or hill terrain. Translate those edge forms into grass-only edges using dark green side shading and leafy rim details.

Grass design:
- Base grass is warm yellow-green.
- Add darker garden-green edge shading on terrain rims.
- Add small light-green and pale-yellow highlights inside the grass.
- Add tiny blade clusters, clover-like dots, mossy pixels, and subtle leaf texture.
- Make repeated full grass tiles tile seamlessly across a large 96 x 72 map.
- Keep detail subtle so the player, pickups, and plants remain readable above the ground.
- Use a limited palette, around 12-18 grass colors total.
- The palette should fit a bright Meadow Edge daytime zone, not a dark forest.

Required atlas behavior:
- Full-cell grass tiles must be seamless on all four sides.
- Edge tiles must clearly show where grass terrain ends and transparency begins.
- Outer corners, inner corners, T-shapes, narrow strips, small islands, and end caps must follow the bitmask reference silhouettes.
- Each tile must keep its terrain shape inside the 16 x 16 cell.
- Do not invent a new atlas arrangement.
- Do not add extra rows or columns.
- Do not convert this into a decorative full-map painting.

Allowed content:
- Grass terrain.
- Grass edge shading.
- Tiny grass blades.
- Tiny clover/moss-like green detail.
- Small pale-yellow grass highlights.
- Transparent unused/cutout areas.

Forbidden content:
- Dirt paths.
- Brown hill cliffs.
- Water.
- Stone.
- Ruins.
- Flowers.
- Trees.
- Logs.
- Brambles.
- Resource icons.
- Player or enemy sprites.
- UI icons.
- Text, numbers, labels, arrows, visible guide marks, or watermarks.

Important:
The output must look like a grass-only replacement/variant for the Sprout Lands Grass.png sheet, not a new generic tileset. Match the reference sheet's 11-column atlas cadence, rounded mask geometry, and Godot-ready 16 x 16 slicing.
```

## Short Gemini Prompt

Use this if Gemini struggles with the full prompt.

```text
Create one grass-only pixel-art terrain tileset PNG for a Godot 2D top-down game.

Follow the exact layout pattern of Sprout Lands Grass.png: 176 x 112 pixels, 11 columns x 7 rows, each tile 16 x 16 pixels. Use Hills.png only as a secondary reference for terrain-edge/corner shape logic. Use Bitmask references 1.png and Bitmask references 2.png as the required autotile mask guide.

Make warm Meadow Edge grass for Dianthus Pixie: bright yellow-green meadow grass, darker green terrain rims, tiny grass blades, clover/moss pixels, and subtle pale-yellow highlights. Strict pixel art, transparent unused/cutout areas, no gutters, no labels, no grid lines.

Grass only. No dirt, no hills, no brown cliffs, no water, no stones, no flowers, no trees, no props, no characters, no UI, no text. Preserve the same occupied-cell and bitmask silhouette structure as Grass.png so it can be sliced in Godot as a 16 x 16 TileSet atlas.
```

## Reference Interpretation Notes

- `Grass.png` is `176 x 112`, which equals `11 x 7` tiles at `16 x 16`.
- `Hills.png` is `176 x 144`, which equals `11 x 9` tiles at `16 x 16`; do not copy its extra rows into this prompt's target output.
- The bitmask reference sheets show the terrain-mask pattern. Gemini should paint grass inside those masks and leave cutout space transparent.
- The goal is not to redraw the bitmask guides themselves. The guides are only for the shape of each autotile.
- If the model adds flowers or props, reject the output and regenerate with the short prompt.

## Import Specification For Godot

- Import as `Texture2D`.
- Disable texture filtering so pixels stay sharp.
- Slice as an atlas with tile size `16 x 16`.
- Confirm the atlas reads as `11 columns x 7 rows`.
- Use the terrain/bitmask settings from the existing `Grass.png` TileSet setup as the starting point.
- Add collision only if this grass variant is used for blocked terrain. Normal meadow grass should remain walkable.

## Quality Checklist

- Image is exactly `176 x 112`.
- Atlas is exactly `11 x 7` tiles.
- Every tile aligns to a 16 x 16 grid.
- Empty/cutout areas are transparent.
- No text, labels, arrows, watermarks, or visible guide lines appear.
- No dirt, water, stones, trees, props, flowers, or characters appear.
- Full grass tiles repeat without seams.
- Edge/corner/strip/island tiles match the bitmask reference silhouettes.
- Style reads as the same family as `Grass.png` and `Hills.png`, but with a fresh Meadow Edge color treatment.

## Negative Prompt

```text
No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D render, no isometric perspective, no text, no labels, no numbers, no arrows, no watermark, no visible grid, no bitmask guide overlay, no dirt, no path, no hill cliff, no brown exposed soil, no water, no stone, no ruins, no flowers, no trees, no logs, no brambles, no props, no icons, no characters, no UI, no full map illustration, no random collage, no extra rows, no extra columns, no black background in transparent areas.
```
