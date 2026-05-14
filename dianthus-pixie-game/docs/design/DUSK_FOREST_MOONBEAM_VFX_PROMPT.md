# Dusk Forest Moonbeam VFX Prompt

**Task type:** WORLD-01 polish / teaser capture polish
**Status:** Prompt only
**Target scene:** `world/zones/dusk_forest/dusk_forest.tscn`
**Target node:** `DuskForestAtmosphereVFX`
**Primary teaser use:** Dusk Forest progression hook shot in `docs/design/TEASER_VIDEO_SCRIPT.md`

---

## Goal

Rebuild the Dusk Forest atmosphere moonbeam visuals as fake volumetric 2D VFX for a teaser-ready shot.

The current `DuskForestAtmosphereVFX` child visuals rely on solid `Polygon2D` shapes. Replace those atmosphere polygons with `Sprite2D` or carefully positioned `ColorRect` nodes using `ShaderMaterial` alpha masks, so the effect reads as soft moonlight cutting through mist instead of flat polygon overlays.

This is an atmosphere polish pass only. Do not redesign Dusk Forest layout, resource placement, zone transitions, camera bounds, quest gates, enemies, or gameplay flow.

---

## Scope Cross-Check

Before implementing, read:

- `docs/design/TASK_BREAKDOWN.md`
- `docs/design/TEASER_VIDEO_SCRIPT.md`
- `world/zones/dusk_forest/dusk_forest.tscn`
- `world/zones/dusk_forest/dusk_forest.gd`
- `world/zones/dusk_forest/dusk_forest_atmosphere_vfx.gd`
- `project.godot`

Confirm these repo facts before editing:

- `WORLD-01` is already `Done`; treat this as polish over completed Dusk Forest work.
- `Dusk Forest or Ruins of Veld shot` is listed as a teaser progression hook.
- The target atmosphere root is `DuskForestAtmosphereVFX`.
- Do not edit anything in `addons/`.

---

## Current Scene Problem To Solve

In `world/zones/dusk_forest/dusk_forest.tscn`, atmosphere children currently include `Polygon2D` nodes under `DuskForestAtmosphereVFX`, including:

- `MoonlightWash`
- `MoonbeamHints/MoonbeamNorthWest`
- `MoonbeamHints/MoonbeamCenter`
- `MoonbeamHints/MoonbeamBlackwater`
- `MistBands/MistBandSouth`
- `MistBands/MistBandWest`
- `MistBands/MistBandMoonspore`
- `MistBands/MistBandNorth`
- `BlackwaterGlowAccents/BlackwaterRimGlow`
- `BlackwaterGlowAccents/BlackwaterStarMoteA`
- `BlackwaterGlowAccents/BlackwaterStarMoteB`
- `CanopyEdgeShadows/TopCanopyShadow`
- `CanopyEdgeShadows/WestCanopyShadow`
- `CanopyEdgeShadows/EastCanopyShadow`

Replace all `Polygon2D` descendants inside `DuskForestAtmosphereVFX` with scene-authored `Sprite2D` or `ColorRect` based visuals. Leave unrelated map-shape polygons under `ForestMapVisuals` alone unless the requested polish explicitly expands scope later.

---

## Required Moonbeam Structure

Create each major moonbeam as a `Node2D` group, with layered shader-driven child nodes. At minimum, `MoonbeamNorthWest` must become:

```text
MoonbeamNorthWest
|-- BeamWide        Sprite2D or ColorRect + soft cone shader
|-- BeamCore        Sprite2D or ColorRect + narrower soft cone shader
|-- BeamStreaks     Sprite2D or ColorRect + thin streak shader
\-- GroundGlow      Sprite2D ellipse glow at light landing area
```

Recommended structure for the other moonbeams:

```text
MoonbeamCenter
|-- BeamWide
|-- BeamCore
|-- BeamStreaks
\-- GroundGlow

MoonbeamBlackwater
|-- BeamWide
|-- BeamCore
|-- BeamStreaks
\-- GroundGlow
```

Use the same shader/material pattern for all beams, but tune each beam's position, rotation, scale, alpha, and flicker phase so they do not pulse in perfect sync.

---

## Visual Direction

Build a fake volumetric moonbeam, not a real Godot light:

- Narrow near the source, wider toward the ground.
- Soft feathered edges, never a hard polygon edge.
- Mist/noise within the beam so it feels like humid forest air.
- A slightly brighter center core inside a wider faint beam.
- Fine vertical or diagonal streaks to imply light filtering through canopy gaps.
- Ellipse-shaped `GroundGlow` at the landing area, soft and subtle.
- Very slow alpha flicker, barely visible, atmospheric rather than flashy.

Mood targets:

- Dusk Forest should feel quiet, humid, and mysterious.
- The beam should help teaser footage read immediately as a progression zone.
- Keep the player/world readable; the VFX should not wash out interactables or resource nodes.

Avoid:

- Solid filled polygons.
- Real `Light2D` as the primary beam shape.
- Overbright bloom that hides tile readability.
- UI overlays or text.
- Fast strobing flicker.
- Large full-screen effects that make the teaser shot look like a cutscene instead of live gameplay.

---

## Shader Requirements

Create one or more reusable `canvas_item` shaders for these layers.

Recommended materials:

- `moonbeam_soft_cone.gdshader`
- `moonbeam_streaks.gdshader`
- `moonbeam_ground_glow.gdshader`

Keep the shaders feature-local if no shared VFX shader folder pattern already exists. A reasonable target is:

```text
world/zones/dusk_forest/shaders/
```

### Soft Cone Shader

The soft cone shader should:

- Use `UV` to generate an alpha cone mask.
- Make the top/source width narrower than the bottom width.
- Feather both left and right edges with `smoothstep`.
- Fade alpha near the top and bottom so the rectangle boundary is invisible.
- Add low-frequency noise or mist variation.
- Expose uniforms for:
  - `beam_color`
  - `alpha_strength`
  - `source_width`
  - `bottom_width`
  - `edge_feather`
  - `mist_strength`
  - `noise_scale`
  - `time_scale`
  - `flicker_strength`
  - `flicker_phase`

### Streak Shader

The streak shader should:

- Create thin, irregular vertical or diagonal streaks inside the same broad cone footprint.
- Keep alpha lower than the core beam.
- Expose uniforms for:
  - `streak_density`
  - `streak_softness`
  - `streak_angle`
  - `streak_alpha`
  - `drift_speed`

### Ground Glow Shader

The ground glow shader should:

- Generate an ellipse alpha mask from `UV`.
- Feather the edge heavily.
- Keep the center soft, not a hard spotlight.
- Expose uniforms for:
  - `glow_color`
  - `alpha_strength`
  - `ellipse_width`
  - `ellipse_height`
  - `edge_feather`
  - `pulse_strength`
  - `pulse_phase`

---

## Scene-First Implementation Direction

Author the static node setup in `dusk_forest.tscn`:

- Node hierarchy.
- Node names.
- Positions, rotations, scales, z-index values.
- Shader resources and default uniform values.
- Initial colors/modulates.
- Visibility defaults.

Use script only for runtime-dynamic behavior:

- Subtle flicker.
- Slow mist drift.
- Optional small alpha phase offsets between beam layers.

Do not create the moonbeam node hierarchy dynamically in `_ready()`.

---

## Script Update Direction

Update `world/zones/dusk_forest/dusk_forest_atmosphere_vfx.gd` only as needed to support the new node types.

Expected changes:

- Stop assuming atmospheric items are `Polygon2D`.
- Track `CanvasItem` base `modulate` for `Sprite2D`, `ColorRect`, and other relevant atmosphere nodes.
- Continue supporting particles and existing flicker behavior where appropriate.
- Add a small, slow flicker path for moonbeam layers by name:
  - `BeamWide`
  - `BeamCore`
  - `BeamStreaks`
  - `GroundGlow`
- Prefer shader uniform updates for mist drift/flicker if the shader exposes time or phase uniforms.

Keep flicker restrained:

```text
BeamWide alpha variation: about 3-6%
BeamCore alpha variation: about 4-8%
BeamStreaks alpha variation: about 5-10%
GroundGlow alpha variation: about 2-5%
Cycle length: roughly 3-7 seconds, offset per beam
```

Do not add gameplay dependencies to the VFX script.

---

## Node Replacement Guidance

Replace atmosphere polygons under `DuskForestAtmosphereVFX` as follows:

```text
MoonlightWash
  Replace with a large low-alpha Sprite2D or ColorRect wash using a broad feathered mask.

MoonbeamHints/*
  Replace each Polygon2D moonbeam with a Node2D group containing BeamWide, BeamCore, BeamStreaks, GroundGlow.

MistBands/*
  Replace with Sprite2D or ColorRect strip shaders that use soft horizontal mist masks and slow drift.

BlackwaterGlowAccents/BlackwaterRimGlow
  Replace with Sprite2D or ColorRect elliptical/rim glow shader.

BlackwaterGlowAccents/BlackwaterStarMoteA and BlackwaterStarMoteB
  Replace with small Sprite2D glow motes or shader-driven soft circles.

CanopyEdgeShadows/*
  Replace with large soft shadow sprites or ColorRects using feathered alpha masks.
```

If `ColorRect` positioning becomes awkward inside world-space `Node2D`, prefer `Sprite2D` with a simple white placeholder texture and a `ShaderMaterial`.

---

## Suggested Asset/Texture Approach

Prefer shader-generated masks over large hand-painted textures.

Options:

- Use a tiny white texture or Godot built-in placeholder texture on `Sprite2D`, then let the shader produce the shape through alpha.
- If a texture is needed, create small neutral mask textures under:

```text
world/zones/dusk_forest/vfx/
```

Keep new raster assets small and transparent. Do not add large generated atlas files for this effect unless the shader approach fails.

---

## Acceptance Criteria

The polish pass is complete when:

- There are no `Polygon2D` descendants under `DuskForestAtmosphereVFX`.
- `MoonbeamNorthWest` uses the required layered structure:
  - `BeamWide`
  - `BeamCore`
  - `BeamStreaks`
  - `GroundGlow`
- `MoonbeamCenter` and `MoonbeamBlackwater` either use the same structure or have explicit `TODO: DUSK-MOONBEAM-POLISH` stubs explaining why they were deferred.
- Moonbeams have feathered cone shapes, not hard-edged solid geometry.
- Ground glows are soft ellipses at the light landing points.
- The VFX script supports the new `Sprite2D` or `ColorRect` nodes without parser errors.
- Flicker is subtle and does not visibly strobe.
- Dusk Forest remains playable and readable.
- No files in `addons/` are changed.

---

## Validation Checklist

Run the smallest checks available:

1. `git status --short` before editing and before commit.
2. Targeted search:

```powershell
rg -n "Polygon2D" world/zones/dusk_forest/dusk_forest.tscn
```

Confirm any remaining `Polygon2D` matches are outside `DuskForestAtmosphereVFX` unless deliberately justified.

3. Static scene search:

```powershell
rg -n "MoonbeamNorthWest|BeamWide|BeamCore|BeamStreaks|GroundGlow|ShaderMaterial|gdshader" world/zones/dusk_forest
```

4. Godot startup check when possible:

```powershell
godot --headless --path . --quit
```

If `godot` is not on `PATH`, try `godot4`, then inspect `.godot/editor/project_metadata.cfg` for the editor binary path.

5. Visual check in the Godot editor:

- Open `world/zones/dusk_forest/dusk_forest.tscn`.
- Verify the beam edges are soft.
- Verify the beam lands in a readable part of the teaser composition.
- Verify flicker is visible only as atmospheric breathing, not a blinking effect.

---

## Implementation Guardrails

- Do not edit `addons/`.
- Do not modify Dusk Forest zone unlocks, transitions, resources, collisions, or quest flow.
- Do not replace terrain/map polygons outside `DuskForestAtmosphereVFX`.
- Do not introduce a new global VFX manager.
- Do not hardcode static visual setup in GDScript when the scene can author it.
- Preserve unrelated existing changes in the worktree.
- Commit only the files changed for this polish pass.
