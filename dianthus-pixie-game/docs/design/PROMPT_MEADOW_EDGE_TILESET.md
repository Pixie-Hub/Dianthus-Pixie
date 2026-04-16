## 1. What to Generate

Create a **single PNG sprite sheet** containing every tile needed for a **3×3 bitmask (47-tile) terrain set** representing **meadow grass ground** for the "Meadow Edge" zone of a 2D pixel-art survival game called *Dianthus Pixie*.

The tiles must cover **all 47 unique bitmask configurations** so the engine can seamlessly autotile any terrain shape — straight edges, outer corners, inner corners, peninsulas, single-tile islands, and fully surrounded centers.

---

## 2. Tile Specifications

| Property | Value |
|---|---|
| **Tile size** | 16×16 px per tile |
| **Total tiles** | 47 unique tiles (full 3×3 minimal bitmask set) |
| **Sheet layout** | Follow the exact arrangement shown in the **Bitmask Reference Image** (the blue-and-white grid). Each white cell = one tile to draw; blue area = transparent / empty background |
| **Output format** | PNG, transparent background outside tile areas |
| **Color depth** | 8-bit indexed or 32-bit RGBA |

---

## 3. Layout — Match the Bitmask Reference Exactly

Use the provided **Bitmask Reference Image** (blue-and-white grid) as the **pixel-perfect placement guide**. Every white rectangle in that image represents one 16×16 tile you must draw. Maintain the same rows, columns, and spacing between tile groups.

### Tile groups visible in the reference (left to right):

1. **Basic 3×3 block** (top-left region)
   - Row 1: top-left outer corner, top edge, top-right outer corner
   - Row 2: left edge, full center, right edge
   - Row 3: bottom-left outer corner, bottom edge, bottom-right outer corner
   - Row 4: horizontal strip (left cap, middle, right cap), single isolated tile

2. **Vertical strip column** (narrow column next to the 3×3 block)
   - Top cap, vertical middle, bottom cap

3. **Inner corners & complex junctions** (large right region)
   - All inner-corner combinations (1 inner corner, 2 adjacent inner corners, 2 diagonal inner corners, 3 inner corners, 4 inner corners)
   - T-junctions, cross-junctions, and L-shaped peninsulas
   - Every remaining bitmask combination not covered by the basic 3×3 block

4. **Small/special tiles** (bottom rows)
   - Single-pixel-width connectors, diagonal-only connections, isolated dot

**Do NOT rearrange the tiles.** The engine will index them by their grid position on the sheet.

---

## 4. Art Style & Visual Reference

Use the provided **Grass.png** from the *Sprout Lands* asset pack as the primary style reference. Match these qualities:

### Shapes & Edges
- **Rounded, organic edges** — no harsh straight-line cuts. Grass borders should curve softly into the transparent area.
- **Subtle inner shadow/highlight** — a slightly darker green along inner edges to give a gentle embossed/puffy feel, and a lighter highlight toward the center-top of large fill areas.
- Outer border pixels should use a **slightly darker olive-green outline** (1 px) to separate the grass from the background.

### Surface Detail
- The **center/fill tiles** should have subtle **texture variation**: tiny darker-green dots, small tufts, or seed-like speckles scattered organically (not in a grid pattern).
- Occasional **lighter yellow-green patches** to break up flat areas — similar to how the Sprout Lands Grass.png has subtle color shifts across its fill tiles.
- Keep detail density **low-to-medium** — this is ground terrain, not a focal element. It should read as a soft, lush meadow at a glance.

### What NOT to include
- No flowers, rocks, or resource objects on the tiles — those are separate sprites.
- No animated frames — this is a static tileset.
- No drop shadows extending outside the tile boundary.

---

## 5. Color Palette

The Meadow Edge zone uses a **warm, vibrant daytime** palette per the game's GDD.

| Role | Hex | Description |
|---|---|---|
| **Primary grass** | `#7EC850` | Bright warm green — largest fill area |
| **Grass highlight** | `#A8E060` | Light yellow-green for top-surface highlights |
| **Grass shadow** | `#5B9830` | Medium olive-green for inner-edge shading and tufts |
| **Border outline** | `#3E7020` | Dark olive for the 1 px outer contour |
| **Detail speckle** | `#4A8828` | Subtle dark dots for surface texture |
| **Light speckle** | `#C8F078` | Occasional bright dot highlights |

> **Palette is a guideline** — feel free to interpolate between these values for anti-alias pixels, but stay within this warm-green hue range. Do NOT introduce blue-greens, teals, or cool grays.

---

## 6. Seamless Tiling Rules

- Any two tiles that share an edge in-game must **tile seamlessly** at their shared border. Grass texture, color, and detail must flow across tile boundaries without visible seams.
- The **center/full fill tile** must be seamlessly repeatable in both X and Y — it will cover large interior areas.
- Edge tiles must transition cleanly from grass to **full transparency** (the area beyond the terrain). The transition should be a soft 1–2 px rounded contour, not a hard rectangle.

---

## 7. Technical Checklist

- [ ] Exactly **47 tiles** present — no missing bitmask configurations
- [ ] Each tile is precisely **16×16 px** — no sub-pixel offsets
- [ ] Layout matches the Bitmask Reference Image grid positions exactly
- [ ] Background / non-grass area is **fully transparent** (alpha = 0)
- [ ] No tile bleeds into its neighbor's grid cell
- [ ] Palette stays within the warm-green range defined above
- [ ] Surface detail is consistent in density across all fill tiles
- [ ] Outer corners, inner corners, edges, and center tiles all connect seamlessly
- [ ] PNG saved without lossy compression artifacts

---

## 8. Reference Images to Attach

When sending this prompt, include these two images:

1. **Bitmask Reference Image** — the blue-and-white grid showing the exact 47-tile layout and positions. (The AI must replicate this arrangement.)
2. **Grass.png** (from *Sprout Lands - Sprites - Basic pack*) — the art-style reference for edge shapes, shading, color feel, and surface detail level.

---

## 9. Example Prompt (Copy-Paste Ready)

> Generate a 16×16 px pixel-art tileset sprite sheet for meadow grass terrain. The sheet must contain all 47 tiles of a 3×3 bitmask autotile set, arranged exactly as shown in the attached bitmask layout reference (blue-and-white grid). Each white cell = one 16×16 tile to draw; the rest is transparent.
>
> **Art style:** Match the attached Grass.png from the Sprout Lands pixel-art pack — soft rounded edges, subtle inner highlight/shadow, 1 px darker-green outline on outer borders, and gentle surface speckles (small tufts and dots) on fill areas. Keep detail low-to-medium density.
>
> **Palette:** Warm vibrant greens — primary fill `#7EC850`, highlight `#A8E060`, shadow `#5B9830`, outline `#3E7020`. No cool greens or grays. Stays within a warm meadow hue range.
>
> **Tiling:** All shared edges must be seamless. Center fill tile must repeat seamlessly in both axes. Edge-to-transparent transitions should be soft and rounded (1–2 px organic contour).
>
> **Do NOT include:** flowers, rocks, objects, animations, or drop shadows. Output a single flat PNG with transparent background.
