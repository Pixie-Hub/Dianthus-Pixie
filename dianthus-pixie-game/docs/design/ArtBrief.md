# Art Brief: Ruins of Veld Tileset Overhaul

## Current Diagnosis

The existing spritesheet suffers from three core problems:
- **Flat, uniform stone** — every tile reads as the same monotone brown-gray slab with identical surface texture, creating the "chocolate bar grid" effect.
- **No environmental narrative** — nothing in the tilework tells the player this was once a living botanical city now being consumed by void corruption. It could be any generic dungeon.
- **Tonal mismatch** — the warm, saturated browns feel cartoonish and don't match the scene's own CanvasModulate tint `Color(0.58, 0.52, 0.46)` or the deep purple-black void overlays already painted into the scene (Breach Glow, Resin Fissures).

---

## 1. Color Palette & Tone

The goal is **ancient weathered stone slowly losing a war against two forces: nature reclaiming it, and void corruption devouring it.** Three color families should coexist on the sheet:

| Zone | Hex Range | Role |
|---|---|---|
| **Base Stone** | `#4A433B` → `#5E5549` → `#6B6358` | Desaturated warm gray-brown. Weathered sandstone, not fresh-cut. Subtle per-tile hue shifts (some tiles lean cooler gray `#504D48`, others warmer `#5C5244`) to break repetition. |
| **Botanical Reclamation** | `#3B5432` → `#4D6B3E` (moss/lichen), `#5A4A30` → `#4E3F28` (dead roots/dirt in cracks) | Dark muted greens and earth browns. Moss patches on stone edges, root tendrils snaking through cracks, dried leaf litter in corners. Never bright green — always desaturated, half-dead. |
| **Void Corruption** | `#1A0E28` → `#2E1640` (deep void purple), `#0A0610` (near-black core), `#6B3A8A` at 30% opacity (ambient stain) | Matches the existing scene's `DeepBreachOmenGlow Color(0.2, 0.1, 0.28)` and `BreachBlackCore Color(0.04, 0.025, 0.055)`. Void tint should appear as subtle staining on ~20% of tiles, intensifying on tiles meant for the northern "deep breach" area. |

**Key tonal rules:**
- No pure whites or bright highlights. The brightest pixel on any tile should be ~`#8A8070` (a dusty cream for stone edge highlights).
- Shadows use cool dark brown `#2A2520` rather than pure black.
- The overall impression when tiled should be **dim, heavy, old** — like walking through Angkor Wat at dusk.

---

## 2. Tile Variation (Fixing Repetition)

The current sheet uses a single stone surface for all autotile variants. The new sheet needs **at least 4 visually distinct ground reads** that can be mixed:

### Ground Tiles (Autotile Terrain)
- **Intact flagstone** — large fitted stones with visible mortar lines. Some tiles have 2×2 blocks, others 3×1 slabs, varying the grid rhythm.
- **Cracked flagstone** — same base but with 1–3 crack lines per tile. Cracks filled with dark dirt or faint void-purple residue.
- **Broken/missing stones** — patches where flagstones are gone, exposing packed earth `#3D3428` underneath, with stone fragments at edges.
- **Overgrown flagstone** — moss and lichen covering 30–60% of the stone surface. Small fern fronds poking through joints.

### Path Tiles
- Lighter, more worn stone `#6B6358` with foot-traffic polish in the center and grime at edges. Should contrast subtly with ground tiles to read as an ancient road.

### Decor Tiles (Replacing the Generic Objects)
- **Collapsed pillar segments** — cylindrical stone with fluting detail, lying on their side or broken at mid-height. Moss on the shadow side.
- **Ruined planter boxes** — stone troughs that once held botanical specimens. Now cracked, with dead root tangles and void-stained soil.
- **Inscribed floor tiles** — faded botanical diagrams or circle-patterns carved into stone (the Veld civilization studied plants). Partially obscured by dirt.
- **Void-touched rubble** — stone clusters with visible purple-black veining, as if the corruption is growing through the rock like a fungus.
- **Broken archways** — 2-tile-wide remnants of doorframes or gates, with roots growing over the top.
- **Ancient irrigation channels** — narrow carved channels in stone, now dry, cracked, with dark residue (matches the `CrackedIrrigationChannel` Polygon2D overlays in the scene).

---

## 3. Environmental Storytelling: Botanical vs. Void

The Ruins of Veld were an **ancient botanical research city** — the civilization that preceded the player's garden. The Devourer's void corruption is what destroyed it. Every tile should whisper one of these two stories:

### The Botanical Past (Nature Reclaiming)
- **Carved botanical motifs** on intact stone — stylized flower/leaf patterns etched into the surface, now weathered almost flat.
- **Root invasion** — thick dark roots (Beringin-like) cracking through walls and floors, splitting stone apart. Roots should be `#3A2E1E` with `#2A2018` shadows.
- **Petrified garden beds** — rectangular stone-bordered areas filled with grey-brown dead soil and fossilized plant material.
- **Scattered seed pods** — tiny 2–3px details on ground tiles, suggesting the city's botanical nature even in ruin.

### The Void Corruption (Devourer's Influence)
- **Purple-black veining** — thin tendrils of corruption running through stone like infected blood vessels. Use `#2E1640` lines, 1px wide, branching organically.
- **Void-stained tiles** — some ground tiles have an irregular dark purple blotch, as if the stone is being dissolved from below. The stain should have a soft, uneven edge (dithered in pixel art terms).
- **Crystallized corruption nodes** — small 3–4px dark crystal formations sprouting from cracks, matching the void-purple palette. These sell the "active, growing threat" narrative.
- **Gradient of corruption** — tiles intended for the southern (entrance) area should have minimal void presence (mostly botanical decay). Tiles for the northern deep-breach area should be heavily corrupted (more purple veining, darker stone base).

### Visual Layering Principle
A single tile can (and should) contain **both** stories — e.g., a flagstone with moss on the left edge AND a void vein on the right. This creates the tension: *nature and void are competing to consume what remains.*

---

## 4. Image Generation Prompts

These are crafted for the PixelLab `create_tiles_pro` or `create_topdown_tileset` tools, targeting **16×16 tile size**, **high top-down** view, matching the Sprout Lands art style.

### Prompt 1 — Base Ground Terrain (Autotile Set)

> **Lower terrain:** ancient weathered sandstone flagstones, desaturated warm gray-brown, cracked mortar lines, some tiles with missing stones exposing dark packed earth, subtle variation in stone block sizes, pixel art top-down RPG style
>
> **Upper terrain:** moss and dark lichen patches growing over ancient stone, dried brown root tendrils in cracks, scattered stone debris, muted green-brown botanical overgrowth on ruined floor
>
> **Style notes:** lineless or selective outline, medium shading, muted earthy desaturated palette (no bright colors), aged and weathered look, similar style to Sprout Lands tileset

### Prompt 2 — Void-Corrupted Ground Variant

> **Lower terrain:** ancient cracked stone floor with dark purple-black void corruption veins spreading through the rock like infected blood vessels, deep desaturated gray stone base, near-black void stains bleeding through cracks, crystallized dark purple growths in damaged areas, pixel art top-down RPG style
>
> **Upper terrain:** corrupted stone rubble mixed with petrified dead roots, void-purple residue pooling in broken tile gaps, faded botanical carvings barely visible under corruption, dark organic tendrils creeping across surface
>
> **Style notes:** selective outline, medium to detailed shading, very dark desaturated palette with purple-black (#2E1640) as accent, ominous and ancient atmosphere, match Sprout Lands pixel density

### Prompt 3 — Decorative Objects & Structures

> 1). collapsed stone pillar lying on its side with moss on shadow side, ancient fluted column broken at midpoint
> 2). ruined stone planter box cracked open with dead tangled roots and dark void-stained soil inside
> 3). broken stone archway remnant with roots growing over top, 2 tiles wide
> 4). ancient carved floor tile with faded botanical circle diagram, partially covered by dirt and void stains
> 5). dry cracked irrigation channel carved in stone with dark residue
> 6). void-corrupted rubble pile with purple-black crystal formations growing from cracks
>
> **Style notes:** high top-down view, selective outline, medium detail, desaturated gray-brown stone (#5E5549) with muted green moss (#4D6B3E) and void purple (#2E1640) accents, pixel art RPG style matching Sprout Lands aesthetic

---

## 5. Technical Constraints

- **Tile size:** 16×16 px (matching current TileSet configuration in [ruins_of_veld.tscn](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/ruins_of_veld/ruins_of_veld.tscn:0:0-0:0))
- **View angle:** high top-down (consistent with existing game camera)
- **The scene already applies CanvasModulate** `Color(0.58, 0.52, 0.46)` and per-layer modulate tints — so the spritesheet itself should be painted at *slightly higher* saturation/brightness than the final in-game appearance, since those tints will darken and desaturate everything further.
- **Spritesheet layout** should preserve the same atlas grid dimensions so the existing TileMapLayer painted data in [ruins_of_veld.tscn](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/ruins_of_veld/ruins_of_veld.tscn:0:0-0:0) remains valid — or we accept repainting the tilemap as part of the overhaul.

---

Review this brief and let me know which direction you'd like to adjust before we move to execution. Key decisions for you:

1. **Repaint tilemap?** — If we change tile positions on the atlas, the existing painted tilemap data becomes invalid. Worth it for the quality gain, but it's extra work.
2. **Corruption gradient** — Do you want a single tileset with mixed tiles (letting the map painter control corruption density), or two separate terrain sets (clean ruins + corrupted ruins) for cleaner autotiling?
3. **Object count** — The current sheet has ~15 decorative objects. Should we keep that count, expand, or trim to focus on quality?

1. Yes scrap the old one
2. Separate
3. Its up to you