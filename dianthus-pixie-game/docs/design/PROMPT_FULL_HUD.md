# PROMPT — UI-01: Full HUD Implementation

**Task ID:** UI-01
**Category:** UI/HUD
**Priority:** High
**Effort:** L (3–7 days)
**Dependencies:** CORE-10 (Basic HUD — done), PLANT-07 (Energy System — done), CORE-07 (Wave Spawner — done), PLANT-08 (Loadout — done)
**GDD Reference:** §11.1 — full HUD spec
**GDD Reference:** §12.1 — "UI Style: traditional overlay (bukan diegetic); frame HUD bergaya panel kayu alami"
**GDD Reference:** §11.4 — Colorblind Mode (icons alongside color coding)

---

## Goal

Bring the HUD from its current minimalist state (Player HP, Core HP, Energy, Hotbar, Menu Hints) up to the **full GDD §11.1 specification** by adding the three missing elements — **Time-of-Day Indicator**, **Minimap**, and **Wave Counter** — and polishing the existing bars/hotbar to match the "natural wood panel" frame style hinted at in §12.1. All 7 HUD elements must be functional, signal-driven, real-time, and respect the colorblind toggle where relevant.

---

## Scope

### In Scope

1. **Time-of-Day Indicator** (top-right corner)
   - Sun/moon icon that smoothly transitions across an arc/track as `DayNightCycle._phase_timer` progresses
   - At ≥75% progress toward Night transition during DAY phase, the indicator track turns **red** as a warning
   - Shows current `day_count` ("Day 3") and remaining time ("01:23") below the icon

2. **Minimap** (bottom-left corner, ~80×80 px)
   - Shows player position (white dot), Dianthus Core position (pink/cyan dot), garden bounds outline, and active plants (small green dots)
   - **Spawn-direction arrows** rendered along minimap edge — visible only during NIGHT phase
   - Arrows point from minimap edge toward each `WaveSpawner._active_spawn_points` position relative to player
   - Polled or signal-driven — no per-frame node walks beyond the minimap script itself

3. **Wave Counter** (directly above minimap during NIGHT, hidden during DAY)
   - Format: `"Wave 1 / 1   Enemies: 5/8"` — current wave / total nights wave count + alive/total spawn budget
   - Single wave per night per CORE-07; show `Wave 1 / 1` for now and leave a `TODO (DIFF-02)` stub for Surge Night multi-wave
   - Updates via `WaveSpawner.wave_started` / `WaveSpawner.wave_cleared` and `WaveSpawner.enemy_spawned` signals
   - Read alive count via existing `WaveSpawner.get_alive_count()` (poll on `_process` ~5 Hz, or signal-driven if you add `enemy_count_changed`)

4. **HUD Polish — existing elements**
   - Wrap each HUD cluster (Player vitals, Core HP, Hotbar, Minimap+WaveCounter, Time-of-Day) in a **wood-panel-style** `PanelContainer` with a shared `StyleBoxFlat` resource (warm brown bg `Color(0.30, 0.22, 0.15, 0.85)`, golden border `Color(0.65, 0.50, 0.25, 1)`, 2px border, 4px corner radius)
   - Replace the placeholder `[E]` / `HP` / `[S]` colorblind labels with actual icon `TextureRect` placeholders (use `icon.svg` modulated, leave `# TODO (UI-ICONS): swap with sprite`)
   - Smooth-tween Player HP bar like Energy bar already does (0.15s tween)
   - Add a low-HP pulse on Player HP container (modulate red→white) when HP <25%
   - Add a Core HP danger pulse (border tint flash) when Core HP <25%
   - Move existing `MenuHintsContainer` to bottom-center to free the bottom-left for the minimap
   - Standardise font sizes (vitals=6, hotbar=6, hints=5) and ensure no overlap at 640×360 base resolution

5. **Colorblind Mode Integration**
   - Existing `colorblind_mode_changed` toggle must continue to show icon labels next to HP / Energy / Core
   - Time-of-Day indicator: when colorblind, append "DAY" / "NIGHT" text label (don't rely solely on icon shape)
   - Wave Counter: already text-based, no extra work needed

### Out of Scope

- Real wood-panel sprite art (use procedural `StyleBoxFlat` per §12.1 placeholder style; leave `# TODO (UI-ICONS)` for sprite swap)
- Minimap zoom controls or fog-of-war
- DIFF-02 Surge Night multi-wave display (leave stub)
- Quest tracker (UI-03)
- Save schema bump (this is a pure presentation layer — no persisted state)

---

## Existing Architecture Reference

### Current HUD — `ui/hud/hud.gd` & `ui/hud/hud.tscn`

- `CanvasLayer` (layer=10), instanced in `world/zones/meadow_edge/meadow_edge.tscn`
- Already wires: `GameManager.player_hp_changed`, `core_hp_changed`, `colorblind_mode_changed`, `player_energy_changed`, `loadout_changed`, `DayNightCycle.phase_changed`
- Helper methods to keep: `_shake(node)`, `_apply_hotbar_border(panel, selected)`, `_hotbar_label(weapon_id)`
- Unique-named nodes: `%PlayerHPBar`, `%PlayerHPLabel`, `%CoreHPBar`, `%EnergyBar`, `%WeaponSlot1/2`, `%SkillSlotPanel`, `%PlayerHPIcon`, `%CoreHPIcon`, `%EnergyIcon`, etc.
- Existing menu hints container (`%MenuHintsContainer`) — bottom-left, **must be relocated** to make room for minimap

### Available Signals & Polling Sources

```gdscript
# DayNightCycle (autoload)
signal phase_changed(phase: String)              # "DAY" | "NIGHT"
func get_time_remaining() -> float                # seconds until next phase
func get_phase_progress() -> float                # 0.0..1.0 within current phase
func is_night() -> bool
var day_count: int
var current_phase: Phase                          # enum DAY/NIGHT

# WaveSpawner (in scene tree at meadow_edge.tscn root)
signal wave_started()
signal wave_cleared()
signal enemy_spawned(enemy: EnemyBase)
func get_alive_count() -> int
var _active_spawn_points: Array[Vector2]          # PRIVATE — add public getter
var _current_wave_total: int                      # PRIVATE — add public getter

# GameManager (autoload)
signal player_hp_changed(current_hp, max_hp)
signal core_hp_changed(current_hp, max_hp)
signal player_energy_changed(current_energy, max_energy)
signal loadout_changed(weapon_slots, skill_id, selected_slot)
signal colorblind_mode_changed(enabled: bool)
var player: Node                                  # Player2D for minimap position
var dianthus_core: Node                           # Core for minimap position
```

### WaveSpawner — Required Public API Additions

The HUD needs read-only access; **add these getters** to `enemies/spawner/wave_spawner.gd`:

```gdscript
func get_active_spawn_points() -> Array[Vector2]:
    return _active_spawn_points.duplicate()

func get_wave_total() -> int:
    return _current_wave_total

func is_wave_active() -> bool:
    return _wave_active
```

### Plant Discovery for Minimap Dots

- `plants/placement/plant_placement_manager.gd` already has `_occupied_tiles: Dictionary` mapping `Vector2i` → plant Node2D
- Expose a getter: `func get_active_plants() -> Array[Node2D]` returning the live plants for minimap rendering
- Garden bounds: use existing `_garden_origin: Vector2` and `_garden_size: Vector2i * GRID_SIZE`

---

## Implementation Steps

### Step 1 — Wood-Panel Theme StyleBox

Create `ui/hud/wood_panel_stylebox.tres` (or inline as sub-resource in `hud.tscn`):

```gdscript
StyleBoxFlat:
  bg_color = Color(0.30, 0.22, 0.15, 0.85)
  border_color = Color(0.65, 0.50, 0.25, 1.0)
  border_width_* = 2
  corner_radius_* = 4
  shadow_color = Color(0, 0, 0, 0.4)
  shadow_size = 2
```

Wrap `PlayerHPContainer`, `CoreHPContainer`, `HotbarContainer`, the new `TimeOfDayContainer`, and the new `MinimapContainer` each in a `PanelContainer` using this stylebox.

### Step 2 — Time-of-Day Indicator

Create `ui/hud/time_of_day_indicator.gd` extending `Control`:

```gdscript
extends Control

@onready var _icon: TextureRect = %ToDIcon
@onready var _track: ColorRect = %ToDTrack       # background bar
@onready var _label: Label = %ToDLabel           # "Day 3" / "01:23"

const NIGHT_WARNING_THRESHOLD := 0.75
const TRACK_NORMAL_COLOR := Color(0.20, 0.40, 0.60, 0.7)
const TRACK_WARNING_COLOR := Color(0.80, 0.20, 0.20, 0.9)

func _process(_delta: float) -> void:
    var progress := DayNightCycle.get_phase_progress()
    var is_night := DayNightCycle.is_night()
    # Move icon along the track based on progress
    _icon.position.x = lerp(0.0, _track.size.x - _icon.size.x, progress)
    # Warning tint when DAY phase ≥75% → night incoming
    if not is_night and progress >= NIGHT_WARNING_THRESHOLD:
        _track.color = TRACK_WARNING_COLOR
    else:
        _track.color = TRACK_NORMAL_COLOR
    # Label
    var remaining := int(DayNightCycle.get_time_remaining())
    var mm := remaining / 60
    var ss := remaining % 60
    _label.text = "Day %d  %s  %02d:%02d" % [DayNightCycle.day_count, "NIGHT" if is_night else "DAY", mm, ss]
```

Position: top-right anchor, ~120×40 px. Use `icon.svg` modulated yellow for sun, modulated cool-blue for moon (swap on `phase_changed`). Leave `TODO (UI-ICONS)` for art swap.

### Step 3 — Minimap

Create `ui/hud/minimap.gd` extending `Control`:

```gdscript
extends Control

const MAP_SIZE := Vector2(80, 80)
const WORLD_TO_MAP_SCALE := 0.08          # world px → minimap px (tune)
const PLAYER_DOT_COLOR := Color(1, 1, 1)
const CORE_DOT_COLOR := Color(1.0, 0.4, 0.7)
const PLANT_DOT_COLOR := Color(0.3, 0.9, 0.3)
const SPAWN_ARROW_COLOR := Color(0.95, 0.25, 0.25)
const BOUNDS_COLOR := Color(0.65, 0.50, 0.25, 0.9)

var _spawner: WaveSpawner = null
var _plant_manager: Node = null

func _ready() -> void:
    custom_minimum_size = MAP_SIZE
    # Cache references via group lookup (deferred)
    call_deferred("_cache_refs")

func _cache_refs() -> void:
    var scene_root := get_tree().current_scene
    _spawner = scene_root.find_child("WaveSpawner", true, false) as WaveSpawner
    _plant_manager = scene_root.find_child("PlantPlacementManager", true, false)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    # 1. Garden bounds rectangle
    # 2. Plant dots (read from _plant_manager.get_active_plants())
    # 3. Core dot
    # 4. Player dot (always center? or world-mapped — pick one and document)
    # 5. Spawn-direction arrows ONLY if DayNightCycle.is_night() AND _spawner.is_wave_active()
    pass
```

**Centering convention:** map player at minimap center; transform other entities relative to player. World-pos `wp` → minimap `mp = (wp - player.global_position) * WORLD_TO_MAP_SCALE + MAP_SIZE * 0.5`. Clamp dots to map bounds.

**Spawn arrows:** for each spawn point in `_spawner.get_active_spawn_points()`, compute direction vector from player → spawn, project onto map edge (clamp to box), draw a small triangle pointing outward.

### Step 4 — Wave Counter

Create `ui/hud/wave_counter.gd` extending `Control`:

```gdscript
extends Control

@onready var _label: Label = %WaveCounterLabel
var _spawner: WaveSpawner = null
var _alive: int = 0
var _total: int = 0

func _ready() -> void:
    visible = false
    DayNightCycle.phase_changed.connect(_on_phase_changed)
    call_deferred("_connect_spawner")

func _connect_spawner() -> void:
    _spawner = get_tree().current_scene.find_child("WaveSpawner", true, false) as WaveSpawner
    if _spawner:
        _spawner.wave_started.connect(_on_wave_started)
        _spawner.wave_cleared.connect(_on_wave_cleared)
        _spawner.enemy_spawned.connect(_on_enemy_spawned)

func _process(_delta: float) -> void:
    if not visible or _spawner == null:
        return
    _alive = _spawner.get_alive_count()
    _label.text = "Wave 1 / 1   Enemies: %d / %d" % [_alive, _total]
    # TODO (DIFF-02): replace "1 / 1" with real wave_index / wave_count for Surge Night

func _on_phase_changed(phase: String) -> void:
    visible = (phase == "NIGHT")

func _on_wave_started() -> void:
    _total = _spawner.get_wave_total()

func _on_wave_cleared() -> void:
    _alive = 0

func _on_enemy_spawned(_e: EnemyBase) -> void:
    pass  # _process polls alive count
```

Position: directly above minimap (anchor bottom-left, offset y to sit above the 80px minimap with 4px gap).

### Step 5 — HUD Polish on existing elements

- Tween Player HP bar value (`create_tween().tween_property(_player_bar, "value", float(current_hp), 0.15)`) — match Energy bar
- Add low-HP pulse: when `_prev_player_hp` ≤ 25, repeat-tween container modulate `Color(1,0.5,0.5)` ↔ `Color.WHITE` at 0.5s per cycle; stop when HP recovers
- Add Core HP <25% danger pulse — pulse the wood-panel border color from gold → red and back
- Move `MenuHintsContainer` from bottom-left to bottom-center (anchor 0.5, offset_left = -56, anchor_bottom = 1.0)
- Apply wood-panel stylebox to all containers
- Replace `_player_hp_icon` / `_core_hp_icon` / `_energy_icon` Labels with TextureRect children (icon.svg, modulated to match bar color); preserve unique names so `_on_colorblind_changed` still works (just toggle visibility)

### Step 6 — Colorblind Time-of-Day text

In `time_of_day_indicator.gd`, listen to `GameManager.colorblind_mode_changed` and prepend the phase name into the label always (already done in step 2 baseline — keep it).

### Step 7 — Wire it up in `hud.tscn`

Instance three new sub-scenes (or inline nodes) into `hud.tscn`:
- `TimeOfDayContainer` (top-right, anchored 1,0)
- `MinimapContainer` (bottom-left, anchored 0,1) wrapping `Minimap` Control
- `WaveCounterContainer` (just above minimap, anchored 0,1) wrapping `WaveCounter` Control

Keep all wood-panel `PanelContainer` wrappers and respect 640×360 base resolution layout (no overlap, 4px margins).

### Step 8 — Update WaveSpawner & PlantPlacementManager getters

- Add `get_active_spawn_points()`, `get_wave_total()`, `is_wave_active()` to `wave_spawner.gd`
- Add `get_active_plants() -> Array[Node2D]` to `plants/placement/plant_placement_manager.gd` (return values of `_occupied_tiles`)

### Step 9 — Documentation

- Mark UI-01 → **Done** in `docs/design/TASK_BREAKDOWN.md`
- Add UI-01 row to `docs/design/PERSON_TASKS.md` Quick Reference
- Update memory record with the new HUD architecture

---

## Acceptance Criteria

1. All 7 HUD elements visible during gameplay: Player HP, Core HP, Energy, Time-of-Day, Hotbar (2 weapons + 1 skill), Minimap, Wave Counter
2. Time-of-Day icon moves smoothly across track; track turns red at ≥75% DAY progress; phase label shows DAY/NIGHT + timer
3. Minimap displays player, core, plants, garden bounds at all times; **spawn-direction arrows visible ONLY at night**
4. Wave Counter visible at night only; shows correct alive/total enemies in real time; hides cleanly on DAY transition
5. Existing Player HP / Core HP / Energy bars still update correctly with shake on damage; HP bar now smooth-tweens; low-HP pulse triggers <25%
6. Hotbar still updates on `loadout_changed`; selection border highlights selected slot; locked tint at night
7. Wood-panel `StyleBoxFlat` applied uniformly across HUD clusters
8. Colorblind mode toggles supplemental text/icons on HP, Core, Energy, **and** Time-of-Day
9. No layout overlap at 640×360 base viewport; HUD scales correctly with viewport stretch
10. No new errors/warnings in Godot debugger; all signals disconnected on tree exit (use `is_inside_tree()` guards in deferred connects)

---

## Files To Create

- `ui/hud/time_of_day_indicator.gd`
- `ui/hud/time_of_day_indicator.tscn`
- `ui/hud/minimap.gd`
- `ui/hud/minimap.tscn`
- `ui/hud/wave_counter.gd`
- `ui/hud/wave_counter.tscn`
- `ui/hud/wood_panel_stylebox.tres` (optional — can be sub-resource in hud.tscn)

## Files To Modify

- `ui/hud/hud.tscn` — add three new sub-scenes, wrap clusters in PanelContainer with wood-panel stylebox, relocate MenuHintsContainer
- `ui/hud/hud.gd` — add HP smooth tween, low-HP pulse, Core danger pulse; replace icon Labels with TextureRect references
- `enemies/spawner/wave_spawner.gd` — add `get_active_spawn_points()`, `get_wave_total()`, `is_wave_active()` public getters; remove the `TODO (UI-01)` line on `get_alive_count()`
- `plants/placement/plant_placement_manager.gd` — add `get_active_plants() -> Array[Node2D]` getter
- `docs/design/TASK_BREAKDOWN.md` — UI-01 status `Not Started` → `Done`
- `docs/design/PERSON_TASKS.md` — append UI-01 entry

---

## Notes & Pitfalls

- **Deferred ref caching:** WaveSpawner / PlantPlacementManager exist as siblings of HUD's CanvasLayer in `meadow_edge.tscn`. Use `call_deferred` and `get_tree().current_scene.find_child(...)` rather than `@onready` (which fires before the scene tree is fully built when HUD is loaded as part of the zone scene)
- **Per-frame draw cost:** `Minimap._process` calling `queue_redraw()` every frame is fine at ~80×80 px with <30 dots; profile if dots scale beyond ~50
- **Don't** poll `WaveSpawner` private fields directly — use the new public getters so future refactors don't break the HUD
- **Test path:** start zone → walk around → confirm minimap moves; trigger night via debug skip (DayNightCycle.debug_skip_phase) → confirm wave counter appears + spawn arrows render → kill enemies → counter decrements → wave_cleared → counter hides on DAY
- **No save schema bump.** This is purely presentation. Existing v7 save remains valid.
- **Lint note:** `WaveSpawner` / `EnemyBase` "type not in scope" in new HUD scripts may appear until Godot reloads — known IDE lag pattern (same as ENEMY-01/03 memos).

---

## Quick Reference — Debug Keys to Verify

| Key | Action | Verification |
|-----|--------|--------------|
| (existing) DayNightCycle.debug_skip_phase via console | Force phase change | Time-of-Day color/label flips, minimap arrows toggle |
| F5 | Spawn debug enemy | Wave Counter alive count increments at night |
| (existing colorblind toggle in Settings) | Toggle colorblind | Icons/text appear next to HP/Core/Energy/Time-of-Day |
