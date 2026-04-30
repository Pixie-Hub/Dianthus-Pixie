# Gemini Image Generation Prompt - Dianthus Pixie Meadow Edge Map Spritesheet

Use this document as the image-generation prompt for Gemini. The goal is to create a usable pixel-art tileset spritesheet for the **Meadow Edge** exploration map in **Dianthus Pixie**.

## Target Use

- Game: `Dianthus Pixie`
- Engine: Godot 4.6
- Scene target: `world/zones/meadow_edge/meadow_edge.tscn`
- Current map scale: 96 x 72 tiles
- Tile size: 16 x 16 pixels
- Intended use: TileSet atlas for a warm daytime meadow / garden-edge exploration zone
- Output asset type: one PNG spritesheet

## Main Prompt

```text
Create a single pixel-art tileset spritesheet for a 2D top-down survival-crafting game called Dianthus Pixie.

The tileset is for the "Meadow Edge" map: a warm, vibrant daytime meadow at the edge of a magical botanical garden. The player explores this zone to gather Petal Shards and Verdant Sap before returning to defend a glowing Dianthus Core at night.

Art direction:
- Strict 2D pixel art.
- Top-down / slightly angled top-down view, compatible with a 16x16 tile world.
- Southeast Asian botanical fantasy mood.
- Warm daytime exploration palette.
- Natural meadow grass, soft dirt routes, flower patches, sap groves, old roots, small pond edges, ruined stone fragments, and garden-edge boundary tiles.
- Readable at small scale.
- Cohesive with a cozy but dangerous survival-crafting garden.

Technical output:
- Exactly one PNG image.
- Exact canvas size: 256 x 256 pixels.
- Exact grid: 16 columns x 16 rows.
- Each cell is exactly 16 x 16 pixels.
- No gutters, no spacing, no labels, no text, no numbers, no visible grid lines.
- Pixel-perfect hard edges.
- No anti-aliasing, no blur, no soft gradients, no painterly rendering.
- The base terrain tiles must fill their full 16x16 cells.
- Decoration / overlay tiles may use transparent background.
- The sheet must be easy to slice in Godot using 16x16 atlas coordinates.

Visual style:
- Crisp 1-pixel clusters and readable silhouettes.
- Limited but rich environment palette, around 32-48 total colors.
- Use small dithering and pixel clusters for texture, not smooth noise.
- Lighting should feel like late morning or early afternoon.
- Shadows should be short, soft in shape, but still pixel-art hard-edged.
- Repeated grass tiles should tile seamlessly across a large 96x72 map.

Color direction:
- Meadow grass: warm yellow-green and leaf green.
- Deeper foliage: dark garden green.
- Dirt route: warm brown / ochre.
- Flowers: dianthus pink, magenta, pale cream, and small yellow centers.
- Verdant sap: fresh green glow in tiny pixel accents.
- Water: teal-blue with muted green reflections.
- Roots and fallen wood: natural bark brown.
- Ruins: muted gray-beige stone with moss.
- Boundary thickets: darker green, brambles, roots, and shaded foliage.

Required tile atlas layout:

Row 0 - base meadow grass:
16 seamless full-cell grass tiles with slight variation: plain grass, soft clover, tiny leaf clusters, faint lighter patches, darker mossy grass.

Row 1 - grass detail and meadow blend:
16 seamless full-cell grass variants for visual breakup: taller blades, sparse flowers, soft soil specks, slightly darker patches, slightly lighter sunny patches.

Row 2 - flower meadow overlays:
16 transparent overlay tiles with small flowers and petals: dianthus-pink flower clusters, tiny white flowers, yellow pollen dots, scattered petals, low meadow blossoms.

Row 3 - dirt route autotile set:
16 full-cell dirt path tiles for routes through grass: center dirt, horizontal path, vertical path, 4 outer corners, 4 inner corners, T-junctions, 4-way junction, path end caps.

Row 4 - soft path / worn grass transitions:
16 full-cell transition tiles: grass blending into dirt, narrow footpath, broken path, grassy path edge, small pebble path, trampled meadow route.

Row 5 - meadow boundary thickets:
16 full-cell blocked-edge tiles: dense tall grass, dark shrubs, leafy wall, bramble edge, shadowed foliage, impassable garden-edge vegetation.

Row 6 - bramble and obstacle overlays:
16 transparent or full-cell obstacle tiles: thorny bramble patch, low root snare, thorn corner, bramble end cap, chopped bramble stump, blocked shortcut marker.

Row 7 - small trees and grove edges:
16 transparent or full-cell tiles: sapling base, leafy canopy edge, tree root base, bush clump, fern cluster, broad tropical leaves, shaded grove border.

Row 8 - Verdant Sap grove props:
16 transparent prop tiles: fallen log segments, cut stump, bark chips, green sap drops, glowing sap knot, mossy roots, small fungi, shaded leaf litter.

Row 9 - pond and water edge:
16 full-cell pond tiles: water center, top edge, bottom edge, left edge, right edge, four outer corners, four inner corners, reeds, shallow muddy bank, tiny reflection tile.

Row 10 - old root hollow:
16 transparent or full-cell tiles: curved old roots, root wall segments, hollow entrance edge, root floor, root arch fragments, golden root-glow accent pixels.

Row 11 - ruin glimmer stones:
16 transparent or full-cell tiles: mossy stone floor, broken stone block, cracked slab, small shrine fragment, arch base, ruin corner, glowing rune specks, stone debris.

Row 12 - garden gate clearing:
16 full-cell transition tiles: softer garden grass, clearing edge, compact earth, petal-strewn ground, gentle path into garden, warm safe-zone grass.

Row 13 - outer map edge / hill blockers:
16 full-cell boundary tiles: low hill edge, raised grass lip, stone-and-root barrier, dark edge shadow, cliff-like meadow boundary, corner blockers.

Row 14 - resource landmark markers:
16 transparent small marker tiles: Petal Shard sparkle patch, Verdant Sap sparkle patch, small harvestable sprout base, resource glow ring, tiny sign stones, subtle discovery clue.

Row 15 - utility overlays:
16 transparent utility tiles: soft oval shadow, small sparkle, pollen motes, leaf scatter, path dust, small highlight glints, empty transparent tile variations.

Important composition rules:
- Each tile must remain inside its 16x16 cell.
- Do not let props spill across cell boundaries unless they are explicitly designed as repeatable edge tiles.
- Do not add any character sprites, UI icons, text labels, arrows, grid numbers, or watermarks.
- Do not make the scene a single painted map. It must be a tile atlas spritesheet.
- Do not use isometric perspective.
- Do not use high-resolution brush textures.
- Do not create large decorative objects that cannot be sliced into 16x16 tiles.
- Keep the overall result bright and warm, but leave enough darker boundary tiles for collision edges.
```

## Short Gemini Prompt

Use this if Gemini struggles with the full prompt.

```text
Create a single 256x256 PNG pixel-art tileset spritesheet for a 2D top-down Godot game. The sheet must be exactly 16 columns x 16 rows, with each tile exactly 16x16 pixels, no gutters, no labels, no grid lines.

Theme: warm daytime "Meadow Edge" map for a botanical fantasy survival-crafting game. Southeast Asian garden edge, vibrant meadow grass, dirt routes, pink dianthus flowers, Verdant Sap grove, old roots, small pond edges, mossy ruins, brambles, garden boundary thickets.

Strict pixel art: no anti-aliasing, no blur, no gradients, no painterly texture. Base terrain tiles fill the full cell. Decoration tiles may be transparent. Top-down / slightly angled top-down view.

Rows: grass, grass variants, flower overlays, dirt path autotiles, path transitions, thicket blockers, bramble obstacles, small trees, sap grove props, pond edges, root hollow tiles, ruin stones, garden clearing tiles, outer boundary blockers, resource markers, utility overlays.

No characters, no UI, no text, no watermark, no isometric view. Make it easy to slice in Godot as a 16x16 TileSet atlas.
```

## Import Specification For Godot

- Import as `Texture2D`.
- Disable filtering so pixels stay sharp.
- Use nearest-neighbor sampling.
- Slice with tile size `16 x 16`.
- Atlas size should read as `16 columns x 16 rows`.
- Use full-cell terrain rows for the primary `TileMapLayer`.
- Use transparent decoration rows on a separate decoration `TileMapLayer` if needed.
- Add collision only to boundary, thicket, bramble, water-edge, root-wall, hill, and ruin-blocker tiles.

## Quality Checklist

- The image is exactly `256 x 256`.
- Every tile aligns to the 16x16 grid.
- No text, labels, arrows, or generated grid marks appear in the image.
- Grass repeats cleanly without obvious seams.
- Dirt routes include straight, corner, T-junction, end-cap, and 4-way tiles.
- Pond edges include enough corner and edge pieces to form small ponds.
- Boundary tiles are visually darker and clearly read as blocked.
- Meadow Edge landmarks are represented: Petal Field, Sap Grove, Old Root Hollow, Ruin Glimmer, Garden Gate Clearing.
- Pixel edges are crisp when zoomed in.

## Negative Prompt

```text
No anti-aliasing, no blur, no smooth gradients, no soft painterly lighting, no 3D render, no isometric perspective, no text, no labels, no numbers, no arrows, no watermark, no characters, no UI, no icons, no single full map illustration, no random collage, no oversized props crossing many tiles, no modern objects, no sci-fi objects, no muddy dark palette.
```
