# VFX-04 Plant Animations Implementation Prompt

**Task ID:** VFX-04
**Title:** Plant Animations
**Category:** Audio/Visual
**Priority:** Medium
**Status in `TASK_BREAKDOWN.md`:** Not Started
**Dependency:** PLANT-05 - All 8 Base Plants Implementation (Done); current repo also has 4 implemented hybrid plant entities
**GDD Reference:** `docs/design/Dianthus Pixie GDD.md` section 12.2 - Animation Priorities
**Primary Acceptance Criteria:** Bloom/placement, active-effect, and wither animations for all 11 currently implemented plant entity scenes; wither triggers when plants are destroyed by enemies.

---

## Goal

Replace the current static plant presentation with lightweight, readable pixel-art animations that preserve the already implemented plant sprites and gameplay behavior.

Each current plant entity should have:

1. A **bloom animation** when the plant is placed in the garden.
2. An **active-effect animation** when its gameplay effect fires or applies.
3. A **wither animation** when the plant is destroyed by enemies or other hostile damage.

The implementation must be grounded in the existing plant entity scenes and current PNG sprites under `plants/sprites/`. Do not redesign the plants. Any generated frames must look like animation frames derived from the current implemented sprite, not a new interpretation of the plant.

---

## Required Pre-Read

Before implementing, read these files and cross-check the scope:

| File | Why it matters |
|---|---|
| `docs/design/TASK_BREAKDOWN.md` | VFX-04 row, dependency/status, acceptance criteria |
| `docs/design/Dianthus Pixie GDD.md` | GDD section 7.1 plant catalogue and section 12.2 animation priority |
| `docs/design/GEMINI_PLANT_SPRITES_PROMPT.md` | Original visual direction and palette notes for current plant sprites |
| `docs/design/PLANT_CODEX.md` | Plant identities, roles, weaknesses, and effect language |
| `plants/entities/plant_base.gd` | Shared HP, vitality, destroy, ability signal, and current wither fade |
| `plants/placement/plant_placement_manager.gd` | Placement flow, plant instancing, `plant_placed`, and `plant_destroyed` wiring |
| `ui/codex/plant_registry.gd` | Current plant IDs, display names, roles, sprite paths, hybrid flags |
| Each target plant `.gd` and `.tscn` | Effect trigger points and scene-authored node structure |

Also inspect the current sprite dimensions before generating or importing animation sheets:

```powershell
Add-Type -AssemblyName System.Drawing
Get-ChildItem plants/sprites -Filter *.png | Sort-Object Name | ForEach-Object {
    $img=[System.Drawing.Image]::FromFile($_.FullName)
    [PSCustomObject]@{Name=$_.Name; Width=$img.Width; Height=$img.Height}
    $img.Dispose()
} | Format-Table -AutoSize
```

Current plant PNGs are 64x64 and the entity scenes render them at `scale = Vector2(0.5, 0.5)`, so new animation frames should use 64x64 source frames unless you intentionally update every scene scale consistently.

---

## Scope Decision

`TASK_BREAKDOWN.md` says "all 8 plants" because VFX-04 originally followed PLANT-05's base-plant scope. This implementation prompt intentionally expands the art/runtime target to **all 11 currently implemented plant entity scenes** so the base and hybrid plants stay visually consistent.

| plant_id | Display name | Scene | Current sprite |
|---|---|---|---|
| `bougainvillea` | Bougainvillea | `res://plants/entities/bougainvillea.tscn` | `res://plants/sprites/Bougainvillea.png` |
| `rafflesia` | Rafflesia | `res://plants/entities/rafflesia.tscn` | `res://plants/sprites/Rafflesia.png` |
| `bunga_api` | Bunga Api | `res://plants/entities/bunga_api.tscn` | `res://plants/sprites/Bunga Api.png` |
| `bunga_bayang` | Bunga Bayang | `res://plants/entities/bunga_bayang.tscn` | `res://plants/sprites/Bunga Bayang.png` |
| `melati` | Melati | `res://plants/entities/melati.tscn` | `res://plants/sprites/Melati.png` |
| `melati_emas` | Melati Emas | `res://plants/entities/melati_emas.tscn` | `res://plants/sprites/Melati Emas.png` |
| `baja_kuning` | Baja Kuning | `res://plants/entities/baja_kuning.tscn` | `res://plants/sprites/Baja Kuning.png` |
| `wijaya_kusuma` | Wijaya Kusuma | `res://plants/entities/wijaya_kusuma.tscn` | `res://plants/sprites/Wijaya Kusuma.png` |
| `beringin` | Beringin | `res://plants/entities/beringin.tscn` | `res://plants/sprites/Beringin.png` |
| `kecombrang` | Kecombrang | `res://plants/entities/kecombrang.tscn` | `res://plants/sprites/Kecombrang.png` |
| `kunyit` | Kunyit | `res://plants/entities/kunyit.tscn` | `res://plants/sprites/Kunyit.png` |

Important repo reality:

- The current placed-plant system has 11 non-core plant entity scenes: 7 non-hybrid plant entries, including Kunyit, plus 4 hybrids.
- The Dianthus Core is already covered by VFX-02 and lives in `core/dianthus_core/`, not `plants/entities/`.
- `ui/codex/plant_registry.gd` currently lists 11 plant entries: 7 non-hybrid entries plus 4 hybrids. It does not include the Core as a normal placeable plant.

Recommended implementation boundary:

1. Implement VFX-04 for all 11 current plant registry/entity plants in `plants/entities/`.
2. Include the 4 hybrids with the same bloom, active, and wither coverage as the non-hybrid plants. Do not leave hybrid coverage as a stretch goal.
3. Keep the Dianthus Core out of this pass unless the user explicitly expands scope to Core animation work. Core animation belongs to VFX-02/Core ownership, not this 11-plant entity pass.
4. Do not mark VFX-04 Done unless all 11 plant entity scenes have the required animation coverage and the wither path is verified through hostile damage.

---

## Existing Runtime Hooks

### Shared Plant Base

`plants/entities/plant_base.gd` already provides these useful hooks:

- `ability_triggered(plant, trigger_id)` signal
- `plant_destroyed(plant)` signal
- `_report_ability_triggered(trigger_id)`
- `destroy()`
- `_play_wither_animation()`
- `_flash_damage()`
- `_update_vitality_visual()`
- `is_destroyed`
- `is_wilted`
- `%Sprite2D` as the current visual node

Current wither is only a 0.5 second alpha fade in `_play_wither_animation()`. Replace that with an authored animation call, then queue-free only after the wither animation finishes.

### Placement Flow

`plants/placement/plant_placement_manager.gd` instantiates the plant scene in `_place_plant()`, sets quality, removes the seed, discovers the plant, plays `plant_placed`, then emits `plant_placed`.

The bloom animation should start from the plant itself after it enters the tree, not from the placement manager. A shared `PlantBase` hook is cleaner than wiring every call site.

### Active Effects

Most plant scripts already call `_report_ability_triggered(...)` after a real effect occurs. Use this as the shared active animation trigger.

Current trigger IDs:

| Plant | Trigger ID(s) | Source |
|---|---|---|
| Bougainvillea | `thorn_tick` | enemy takes thorn tick damage |
| Rafflesia | `slow` | enemy enters/receives slow |
| Melati | `energy_regen` | player receives energy regen |
| Wijaya Kusuma | `night_projectile` | projectile fires |
| Beringin | `root_wall` | root wall spawns |
| Kecombrang | `attack_speed_boost` | player enters boost radius |
| Kunyit | `melee_damage_boost` | player enters boost radius |
| Bunga Api | `fire_thorn_tick` | fire thorn tick damage |
| Bunga Bayang | `shadow_projectile`, `shadow_slow` | projectile fire and slow application |
| Melati Emas | `hp_regen`, `energy_regen` | player receives HP/energy regen |
| Baja Kuning | `armor_buff` | player receives armor buff |

Do not animate when a plant is wilted or destroyed.

---

## Asset Requirements

### Frame Format

Use one 64x64 transparent PNG frame size for every plant animation frame. This keeps the current scene scale (`0.5`) and visual footprint stable.

Recommended sprite sheets:

| Animation | Frame count | Sheet dimensions | Playback |
|---|---:|---|---|
| `bloom` | 6 | 384x64 | one-shot, 10-12 fps |
| `active` | 4 | 256x64 | one-shot or loop pulse, 8-10 fps |
| `wither` | 6 | 384x64 | one-shot, 10-12 fps |

Recommended output folder:

```text
plants/sprites/animations/
```

Recommended file names:

```text
plants/sprites/animations/bougainvillea_bloom.png
plants/sprites/animations/bougainvillea_active.png
plants/sprites/animations/bougainvillea_wither.png
...
```

Import settings:

- Texture filter: nearest.
- Transparent background.
- No smoothing.
- No padding color bleed.
- Keep frame rectangles exact multiples of 64.

### Animation Design Rules

All generated frames must be based on the current sprite:

- Preserve silhouette, flower count, leaf layout, and palette.
- Do not change the plant species or introduce new props.
- Use pixel motion, pose edits, glow pixels, leaf curls, root motion, and opacity/particle overlays.
- Keep the plant centered on the same anchor as the static sprite.
- Avoid camera motion, background tiles, shadows outside the existing 64x64 transparent frame, text, UI, or terrain.

### Optional PixelLab Workflow

Use PixelLab only if it helps create consistent pixel-art frames. The important constraint is still source fidelity: use the current `plants/sprites/<Plant>.png` as the visual reference, and reject outputs that redesign the plant.

Suggested PixelLab brief for each plant:

```text
Create pixel-art animation frames based on the provided 64x64 transparent plant sprite. Preserve the exact plant identity, silhouette, palette, top-down/slightly angled view, and transparent background. Do not redesign the plant. Output separate 64x64 frames suitable for a horizontal sprite sheet. Strict pixel art, no antialiasing, no gradients, no background.
```

If PixelLab cannot directly use the current sprite as a reference in the chosen mode, use it only for rough motion ideas and redraw/adjust the final frames manually against the current PNG.

### Per-Plant Art Direction

Use these animation beats to keep each active animation tied to gameplay:

| Plant | Bloom | Active effect | Wither |
|---|---|---|---|
| Bougainvillea | bracts open from tight bud, thorns extend | magenta thorn ring pulses outward, 1-2 thorn pixels snap | bracts curl inward, magenta desaturates, thorns droop |
| Rafflesia | petals unfold outward from dark center | foul red miasma pulse, center darkens briefly | petals sag and spot highlights dim |
| Melati | white flowers pop open with small blue-white glow | soft white-blue aura rises toward player | flowers close, leaves lose saturation |
| Wijaya Kusuma | pale night bloom opens from the cactus leaf | moonlit center flashes before projectile fire | petals fold, moon glow fades |
| Beringin | roots grip outward and canopy lifts | root energy travels downward before wall spawn | canopy browns, roots slacken/crack |
| Kecombrang | torch bud lifts and layered petals flare | orange-pink spark pulse, torch tip brightens | torch tip dims, petals collapse |
| Kunyit | leaves fan out, golden rhizome glints | gold hardening pulse around rhizome/leaves | leaves droop, gold becomes dull ochre |
| Bunga Api | thorny magenta base flares as orange tips ignite | orange flame-thorn pulse, small ember pixels | flame tips extinguish, bracts curl and darken |
| Bunga Bayang | dark petals open from a shadowed center | violet shadow ripple, dark center flash | petals collapse inward into muted purple-black |
| Melati Emas | golden-white flowers open with pink center glints | golden-white healing/energy sparkle pulse | gold glow drains to dull cream, leaves sag |
| Baja Kuning | metallic leaves unfold and rhizome flashes | steel-gold armor glint, dark vein pulse | hard leaves crack/dull, veins fade |

---

## Recommended Implementation Architecture

### 1. Keep Plant Scenes Scene-First

Each plant `.tscn` should own its visual setup. Do not create visual nodes from code except for already-runtime projectiles/effects.

Recommended scene node pattern:

```text
<Plant> (StaticBody2D, script extends PlantBase)
  Sprite2D              # existing static/current sprite, unique_name_in_owner = true
  AnimatedSprite2D      # new, unique_name_in_owner = true, hidden by default
  AnimationPlayer       # optional if using Sprite2D property animation instead of AnimatedSprite2D
  CollisionShape2D
  EffectArea
```

Preferred approach:

- Add an `AnimatedSprite2D` named `PlantAnimator` to each plant scene.
- Assign a scene-authored `SpriteFrames` resource containing `idle`, `bloom`, `active`, and `wither` animations.
- Keep the existing `Sprite2D` as fallback/static visual if an animation resource is missing.
- Set `PlantAnimator.visible = false` by default in the scene.
- Use `texture_filter = 1` and the same `scale = Vector2(0.5, 0.5)` as the existing `Sprite2D`.

Alternative acceptable approach:

- Keep `Sprite2D` only and use an `AnimationPlayer` to animate texture regions, scale, modulate, and frame rectangles.
- This is more tedious across plant-specific sheets but avoids replacing the node type.

Do not replace static sprites in a way that breaks Codex sprite display, placement previews, or `PlantRegistry.sprite_path`.

### 2. Add a Shared Plant Animation Controller

Create:

```text
plants/vfx/plant_animation_controller.gd
```

Suggested responsibility:

- Reference the existing `%Sprite2D`.
- Reference optional `%PlantAnimator`.
- Play `bloom`, `active`, and `wither` by animation name.
- Fall back to safe tweens when animation assets are missing.
- Emit/await completion for one-shot wither so `PlantBase` can queue-free after the visual finishes.

Suggested API:

```gdscript
class_name PlantAnimationController
extends Node

@export var bloom_animation: StringName = &"bloom"
@export var active_animation: StringName = &"active"
@export var wither_animation: StringName = &"wither"

func setup(static_sprite: Sprite2D, animated_sprite: AnimatedSprite2D) -> void:
    pass

func play_bloom() -> void:
    pass

func play_active(trigger_id: StringName = &"") -> void:
    pass

func play_wither() -> Signal:
    pass
```

Keep this controller feature-local under `plants/`, not a global autoload.

### 3. Wire PlantBase Once

Modify `plants/entities/plant_base.gd` narrowly:

- Add optional `@onready var _plant_animator: AnimatedSprite2D = get_node_or_null("%PlantAnimator") as AnimatedSprite2D`
- Add optional `@onready var _animation_controller: PlantAnimationController = get_node_or_null("%PlantAnimationController") as PlantAnimationController`
- In `_ready()`, initialize controller if present and call `play_bloom()` deferred after the plant enters the tree.
- In `_report_ability_triggered(trigger_id)`, after emitting the existing signal, call `_animation_controller.play_active(trigger_id)` if available and the plant is not destroyed/wilted.
- In `_play_wither_animation()`, use the controller if present, await its completion, then `queue_free()`. If no controller/animation exists, keep the current alpha fade fallback.

Do not change plant damage, effect logic, signals, inventory, placement, or save behavior.

### 4. Keep Wither Timing Correct

`destroy()` currently:

1. Cancels tending.
2. Sets `is_destroyed = true`.
3. Plays `plant_destroyed`.
4. Emits `plant_destroyed`.
5. Calls `_play_wither_animation()`.

Keep this order unless you have a specific bug to fix. The placement manager listens to `plant_destroyed` to free the occupied garden tile immediately; this is good gameplay behavior even if the wither animation lingers visually for a fraction of a second.

Make sure the withering plant cannot keep damaging enemies while the animation plays. Existing plant override `destroy()` methods already clear active lists/effects before `super.destroy()`. Preserve that.

### 5. Prevent Animation Spam

Active effects may trigger every tick. Add a short per-plant cooldown inside the animation controller:

```gdscript
@export var active_animation_min_interval: float = 0.35
```

If `active` is currently playing or the last active animation was too recent, skip the new active visual. This prevents Bougainvillea/Bunga Api tick effects and Melati regen from restarting every frame.

### 6. Maintain Vitality and Quality Visuals

`PlantBase` currently uses:

- node `modulate` for vitality wilt/desaturation.
- `_sprite.modulate` for damage flash.
- `_draw()` rings for seed quality.

Preserve these behaviors:

- If the animated node is visible, apply the same parent/node modulate path so vitality affects it too.
- Damage flash should affect whichever visual is currently visible.
- Quality ring drawing should remain unchanged.

---

## Files to Create

| File | Purpose |
|---|---|
| `plants/vfx/plant_animation_controller.gd` | Shared feature-local animation playback/fallback controller |
| `plants/sprites/animations/<plant>_bloom.png` | Bloom sprite sheet for each of the 11 plant entities |
| `plants/sprites/animations/<plant>_active.png` | Active-effect sprite sheet for each of the 11 plant entities |
| `plants/sprites/animations/<plant>_wither.png` | Wither sprite sheet for each of the 11 plant entities |

If using external `.tres` resources instead of embedded scene resources, also create:

| File | Purpose |
|---|---|
| `plants/vfx/sprite_frames/<plant>_sprite_frames.tres` | SpriteFrames resource for each plant |

---

## Files to Modify

| File | Change |
|---|---|
| `plants/entities/plant_base.gd` | Add optional animation controller hooks for bloom, active, and wither |
| `plants/entities/bougainvillea.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/rafflesia.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/bunga_api.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/bunga_bayang.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/melati.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/melati_emas.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/baja_kuning.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/wijaya_kusuma.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/beringin.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/kecombrang.tscn` | Add scene-authored animation nodes/resources |
| `plants/entities/kunyit.tscn` | Add scene-authored animation nodes/resources |
| `docs/design/TASK_BREAKDOWN.md` | Mark VFX-04 Done only after acceptance is met |
| `docs/design/PERSON_TASKS.md` | Add VFX-04 implementation/debug notes only if new debug keys or ownership notes are introduced |

---

## Implementation Steps

### Step 1 - Confirm Plant Scope

Run targeted searches:

```powershell
rg -n "VFX-04|PLANT-05|Plant Animations" docs/design/TASK_BREAKDOWN.md
rg -n "Plant Catalogue|Animation Priorities|bloom" "docs/design/Dianthus Pixie GDD.md"
rg -n "sprite_path|is_hybrid|get_base_plant_ids|get_hybrid_plant_ids" ui/codex/plant_registry.gd
rg -n "SEED_TO_SCENE|plant_placed|plant_destroyed" plants/placement/plant_placement_manager.gd
```

Write down the final 11-plant list before editing. Hybrids are in scope; Dianthus Core is out of this 11-plant entity pass unless the user explicitly expands the task.

### Step 2 - Generate or Author Animation Sheets

For each of the 11 plant entities:

1. Open the current PNG in `plants/sprites/`.
2. Use it as the first visual reference.
3. Create 3 horizontal sprite sheets:
   - `bloom`: 6 frames, 384x64.
   - `active`: 4 frames, 256x64.
   - `wither`: 6 frames, 384x64.
4. Save to `plants/sprites/animations/`.
5. Verify exact dimensions and transparency.

If using PixelLab, generate frames from the current sprite reference where possible. If not possible, use PixelLab for motion concepts only and manually preserve the current sprite in the final output.

### Step 3 - Add the Controller

Create `plants/vfx/plant_animation_controller.gd`.

Controller requirements:

- No hard dependency on a specific plant script.
- Safe if `AnimatedSprite2D` is missing.
- Safe if a named animation is missing.
- Plays `bloom` once and returns to static/idle.
- Plays `active` only if not within cooldown.
- Plays `wither` once and provides a completion path.
- Does not queue-free the plant directly; `PlantBase` owns queue-free.

### Step 4 - Wire PlantBase

Modify `PlantBase`:

- Keep existing signal names and public method names.
- Keep the current fallback fade.
- Add wither await handling without racing multiple queue-free calls.
- Ensure `_flash_damage()` targets the visible sprite/animated sprite.

Suggested helper methods:

```gdscript
func _get_visible_plant_visual() -> CanvasItem:
    if is_instance_valid(_plant_animator) and _plant_animator.visible:
        return _plant_animator
    return _sprite
```

```gdscript
func _play_bloom_animation() -> void:
    if is_instance_valid(_animation_controller):
        _animation_controller.play_bloom()
```

### Step 5 - Author Scene Nodes

For each of the 11 plant entity scenes:

1. Keep `Sprite2D` with the original texture.
2. Add `AnimatedSprite2D` named `PlantAnimator`.
3. Set `unique_name_in_owner = true`.
4. Set `visible = false`.
5. Set `texture_filter = 1`.
6. Set `scale = Vector2(0.5, 0.5)`.
7. Add a child `Node` named `PlantAnimationController`.
8. Attach `plants/vfx/plant_animation_controller.gd`.
9. Assign the plant-specific SpriteFrames resource to `PlantAnimator`.

Do this in `.tscn` files directly where possible. Avoid adding boilerplate node creation in `_ready()`.

### Step 6 - Connect Active Effects Through Existing Hooks

Do not add plant-specific animation calls in every plant script unless a plant lacks `_report_ability_triggered(...)`.

Use the existing `_report_ability_triggered()` path in `PlantBase` so every effect-driven plant gets the active visual automatically.

If a plant's gameplay effect is active but never calls `_report_ability_triggered()`, add the missing call at the exact point where the effect successfully happens. Do not emit on failed checks or empty target lists.

### Step 7 - Verify Wither From Enemy Damage

The acceptance criterion says wither must trigger when destroyed by enemies.

Trace enemy damage path:

- `enemies/fsm/enemy_siege_state.gd` damages `current_siege_target`.
- `enemies/devourer/devourer_dark_pulse.gd` can damage plants.
- Plant damage enters `PlantBase.take_damage(amount)`.
- HP at 0 calls `destroy()`.
- `destroy()` must play the new wither.

Test a plant destroyed by an enemy path, not only by a debug call.

### Step 8 - Update Docs Only After Implementation

If the full acceptance criteria are satisfied:

- Change VFX-04 status in `docs/design/TASK_BREAKDOWN.md` from `Not Started` to `Done`.
- Add/update a concise note in `docs/design/PERSON_TASKS.md` only if it helps future owners understand the files touched.

If some animation assets are still placeholders or any of the 11 plant entities are missing coverage, leave VFX-04 as `In Progress` or `Not Started` and add `TODO: VFX-04` stubs at the exact deferred points.

---

## Acceptance Checklist

### Visual Acceptance

- Every one of the 11 plant entities still visually matches its current static sprite.
- Bloom animation plays once when placed.
- Active-effect animation plays when the plant's real gameplay effect triggers.
- Wither animation plays when plant HP reaches 0.
- Plant is queue-freed only after wither finishes or after the fallback fade finishes.
- No visual node falls back to a default gray/editor placeholder.
- Texture filtering remains nearest/pixel crisp.
- Animation frames stay centered and do not shift the plant off its garden tile.
- Existing quality rings still render.
- Vitality desaturation still affects the plant visual.
- Damage flash still works.

### Gameplay Acceptance

- Plant placement still removes the correct seed and quality tier.
- Existing plant effects remain unchanged numerically.
- Destroyed plants no longer deal damage, slow enemies, buff players, or keep projectiles alive.
- Placement manager frees occupied garden tiles after `plant_destroyed`.
- Save/load of planted plants still works.
- No new autoloads.
- No edits under `addons/`.

### Task Acceptance

- VFX-04 bloom, active effect, and wither coverage exists for all 11 current plant entity scenes.
- Wither triggers through enemy damage path.
- Dianthus Core is not required for this pass unless the user explicitly expands scope beyond the 11 plant entity scenes.
- `TASK_BREAKDOWN.md` is updated only if the task is truly complete.

---

## Validation

Run the smallest checks available:

```powershell
git diff --check
```

If Godot is available:

```powershell
godot --headless --path . --quit
```

If `godot` is not on PATH, try:

```powershell
godot4 --headless --path . --quit
```

If neither works, inspect `.godot/editor/project_metadata.cfg` for the editor binary path and use that path if practical.

Manual in-game checks:

1. Start a scene with `PlantPlacementManager`.
2. Place each of the 11 plant entities during day.
3. Confirm bloom plays once.
4. Trigger each plant's real effect:
   - Bougainvillea: enemy in thorn radius.
   - Rafflesia: enemy enters slow radius.
   - Melati: player in range while energy can regenerate.
   - Wijaya Kusuma: night enemy target available.
   - Beringin: enemy enters root-wall trigger.
   - Kecombrang: player enters boost radius.
   - Kunyit: player enters boost radius.
   - Bunga Api: enemy in fire-thorn radius.
   - Bunga Bayang: night enemy target and enemy slow radius.
   - Melati Emas: player in range while HP or energy can regenerate.
   - Baja Kuning: player enters armor buff radius.
5. Let enemies destroy at least one non-hybrid and one hybrid plant.
6. Confirm wither animation plays and the plant is removed after it finishes.
7. Confirm no parser errors on project startup.

---

## Final Response Requirements For The Implementer

In the final response:

- List the commit hash.
- Summarize created/modified files.
- State whether Godot validation ran or why it did not.
- State whether VFX-04 was marked Done, In Progress, or left Not Started.
- If PixelLab or another generator was used, state which generated assets were based on which current sprite files.
- Mention any explicit TODO stubs left for Core coverage.

---

## Prompt Authoring Record

This planning prompt was created for VFX-04 and intentionally does not mark VFX-04 complete.

Created file:

- `docs/design/VFX_04_PLANT_ANIMATIONS_PROMPT.md`

Current source assets referenced:

- `plants/sprites/Bougainvillea.png`
- `plants/sprites/Rafflesia.png`
- `plants/sprites/Melati.png`
- `plants/sprites/Melati Emas.png`
- `plants/sprites/Wijaya Kusuma.png`
- `plants/sprites/Beringin.png`
- `plants/sprites/Kecombrang.png`
- `plants/sprites/Kunyit.png`
- `plants/sprites/Bunga Api.png`
- `plants/sprites/Bunga Bayang.png`
- `plants/sprites/Baja Kuning.png`
