# CORE-07 — Wave Spawner (1 Wave, 1–3 Entry Points) — Implementation Prompt

**Project:** Dianthus Pixie  
**Engine:** Godot 4.6 (GDScript)  
**Effort:** M (1–3 days)  
**Priority:** Critical  
**Dependencies:** CORE-06 (Shadowling Enemy FSM — Done)  
**Downstream dependents:** CORE-09 (Win Condition: Survive Night), DIFF-01 (Difficulty Scaling), DIFF-02 (Surge Night)

---

## 1. Objective

Implement a **Wave Spawner** system that activates at the start of each Night phase and spawns enemies from randomized cardinal entry points around the garden. This is the first implementation of the night-defense loop — the core gameplay mechanic of Dianthus Pixie. This task must produce:

1. A **WaveSpawner** node/script (`enemies/spawner/wave_spawner.gd`) that manages enemy spawning during Night.
2. A **spawn point marker** system with 4 cardinal entry points (North, South, East, West) placed at the zone edges.
3. A **wave configuration** data structure (Resource or Dictionary) defining how many enemies spawn per wave and from which points.
4. **Signal-based wave lifecycle**: wave starts → enemies spawn in staggered bursts → wave cleared when all enemies dead/despawned → night survived signal.
5. Integration with the **DayNightCycle** autoload (Night triggers spawn, Morning cancels/cleans up).
6. **Debug keys** for testing wave spawning manually.

---

## 2. GDD Requirements (§10.3 + §8.2)

- Night phase triggers the spawner.
- **1–3 of 4 cardinal entry points** activate randomly each night.
- A `wave_cleared` signal fires **only** when all spawned enemies have died or despawned.
- The spawner resets cleanly for the next night (no leftover state, no orphan nodes).
- For this task, implement **1 wave per night** with Shadowlings only. Multi-wave and enemy-type variety will be added in DIFF-01 and DIFF-02.

---

## 3. Spawn Point Layout

The current zone is `meadow_edge` (40×30 tiles, 16 px/tile = 640×480 px world area). The Dianthus Core sits near the center.

Define **4 cardinal spawn points** at the edges of the zone:

| Point ID | Direction | Approximate Position | Notes |
|----------|-----------|---------------------|-------|
| `north`  | Top       | `Vector2(320, -16)` | Just above the top edge of the zone |
| `south`  | Bottom    | `Vector2(320, 496)` | Just below the bottom edge |
| `east`   | Right     | `Vector2(656, 240)` | Just past the right edge |
| `west`   | Left      | `Vector2(-16, 240)` | Just past the left edge |

These positions should be configurable (either via `Marker2D` nodes placed in the zone scene, or via exported `Vector2` arrays in the spawner). Using `Marker2D` nodes is preferred for visual placement in the editor.

**Each night**, the spawner randomly selects **1 to 3** of these 4 points to be active. Enemies only spawn from active points.

---

## 4. Wave Configuration

For the vertical-slice (Phase 1), use a simple data-driven approach:

```gdscript
# Default wave config for Day 1 vertical slice
var wave_config: Dictionary = {
    "enemy_scene": preload("res://enemies/shadowling/shadowling.tscn"),
    "total_enemies": 5,            # Total enemies to spawn this wave
    "min_entry_points": 1,         # Minimum active spawn points
    "max_entry_points": 3,         # Maximum active spawn points
    "spawn_interval": 1.5,         # Seconds between individual spawns
    "spawn_batch_size": 1,         # Enemies spawned per interval tick
    "spawn_offset_radius": 24.0,   # Random position jitter around the spawn point (px)
}
```

**Design decisions for tuning (not in GDD):**
- **Total enemies per wave:** 5 for Day 1. DIFF-01 will later scale this by day count.
- **Spawn interval:** 1.5 s between spawns. Enemies should not appear all at once — staggered spawning gives the player time to react and creates visual interest.
- **Spawn offset:** Each enemy is offset by a random vector within `spawn_offset_radius` of the entry point marker, so they don't stack on the exact same pixel.

Store these values as `@export` variables or a Resource so they're easy to tune from the editor and from DIFF-01 later.

---

## 5. WaveSpawner Architecture

### 5a. File: `enemies/spawner/wave_spawner.gd`

`extends Node`, `class_name WaveSpawner`

**Exports:**
- `enemy_scene: PackedScene` — The scene to instantiate (default: `shadowling.tscn`).
- `total_enemies: int = 5` — Number of enemies per wave.
- `min_entry_points: int = 1`
- `max_entry_points: int = 3`
- `spawn_interval: float = 1.5` — Seconds between spawn ticks.
- `spawn_batch_size: int = 1` — Enemies spawned per tick.
- `spawn_offset_radius: float = 24.0`

**Signals:**
- `wave_started()` — Emitted when the night wave begins spawning.
- `wave_cleared()` — Emitted when **all** spawned enemies for this wave have died or despawned (no enemies remain in the `"enemies"` group that belong to this wave).
- `enemy_spawned(enemy: EnemyBase)` — Emitted each time an enemy is instantiated.

**Internal state:**
- `_active_spawn_points: Array[Vector2]` — The subset of entry points chosen for this night.
- `_spawn_point_markers: Array[Marker2D]` — References to the 4 Marker2D children (discovered on `_ready()`).
- `_enemies_alive: int = 0` — Counter tracking how many wave enemies are still alive.
- `_enemies_spawned: int = 0` — Counter tracking how many have been spawned so far.
- `_spawn_timer: float = 0.0` — Countdown to next spawn tick.
- `_wave_active: bool = false` — True while a wave is in progress.
- `_spawned_enemies: Array[EnemyBase]` — References to track spawned enemies for cleanup.

**Lifecycle:**

1. **`_ready()`:**
   - Discover all `Marker2D` children and store them in `_spawn_point_markers`.
   - Connect to `DayNightCycle.phase_changed` signal.
   - If the current phase is already Night (e.g., scene loaded mid-night), start the wave immediately.

2. **`_on_phase_changed(phase: String)`:**
   - If `phase == "NIGHT"`: Call `start_wave()`.
   - If `phase == "MORNING"`: Call `_cleanup_wave()` (force-end any remaining enemies if the night ended early, e.g., via debug skip).

3. **`start_wave()`:**
   - If `_wave_active`, return (prevent double-start).
   - Set `_wave_active = true`, reset counters.
   - Randomly select `randi_range(min_entry_points, max_entry_points)` spawn points from `_spawn_point_markers`. Store their `global_position` values in `_active_spawn_points`.
   - Emit `wave_started`.
   - Print debug info: `"Wave started! Active spawn points: %d, Total enemies: %d"`.
   - Begin spawning via `_process(delta)` or a Timer.

4. **`_process(delta)` (spawning loop):**
   - If not `_wave_active` or `_enemies_spawned >= total_enemies`: return.
   - Decrement `_spawn_timer` by delta.
   - When `_spawn_timer <= 0`: spawn `spawn_batch_size` enemies, reset timer to `spawn_interval`.
   - After spawning all `total_enemies`, stop the spawn loop (but wave remains active until all enemies die).

5. **`_spawn_enemy()`:**
   - Pick a random position from `_active_spawn_points`.
   - Add a random offset: `position += Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0, spawn_offset_radius)`.
   - Instantiate `enemy_scene`, set `global_position`, add to the **current scene tree** (use `get_tree().current_scene.add_child(enemy)` or a designated enemy container node).
   - Call `enemy.activate()` if the method exists (transitions Shadowling from Idle → Scout).
   - Connect to `enemy.enemy_died` signal → `_on_enemy_died`.
   - Also connect to `enemy.tree_exiting` signal → `_on_enemy_removed` as a safety net (catches `queue_free()` from retreat despawn which may not emit `enemy_died`).
   - Increment `_enemies_spawned` and `_enemies_alive`.
   - Append to `_spawned_enemies`.
   - Emit `enemy_spawned(enemy)`.

6. **`_on_enemy_died(enemy: EnemyBase)`:**
   - Decrement `_enemies_alive`.
   - Call `_check_wave_cleared()`.

7. **`_on_enemy_removed()`:**
   - This is the `tree_exiting` callback. Only decrement `_enemies_alive` if it wasn't already decremented by `_on_enemy_died`. Use a flag or check if the enemy is still in `_spawned_enemies`.
   - Call `_check_wave_cleared()`.

8. **`_check_wave_cleared()`:**
   - If `_enemies_alive <= 0` and `_enemies_spawned >= total_enemies`:
     - Set `_wave_active = false`.
     - Emit `wave_cleared`.
     - Print: `"Wave cleared!"`.

9. **`_cleanup_wave()`:**
   - Force-kill all remaining wave enemies (for when night ends early via debug or other means).
   - For each enemy in `_spawned_enemies`: if `is_instance_valid(enemy)` and not `enemy.is_dead`, call `enemy.queue_free()`.
   - Reset all counters and set `_wave_active = false`.
   - Clear `_spawned_enemies`.

---

## 6. Scene Tree Integration

### 6a. WaveSpawner scene structure (added to zone scene)

```
MeadowEdge (Node2D) [meadow_edge.gd]
├── ... (existing children: TileMapLayer, Player, DianthusCore, etc.)
├── WaveSpawner (Node) [wave_spawner.gd]
│   ├── SpawnNorth (Marker2D) — position = (320, -16)
│   ├── SpawnSouth (Marker2D) — position = (320, 496)
│   ├── SpawnEast (Marker2D) — position = (656, 240)
│   └── SpawnWest (Marker2D) — position = (-16, 240)
└── EnemyContainer (Node2D) — optional container for spawned enemies (keeps scene tree tidy)
```

The `WaveSpawner` can be either:
- **Option A:** A node added directly to the `meadow_edge.tscn` scene (simplest for vertical slice).
- **Option B:** A standalone `.tscn` that gets instanced into any zone. Preferred for reuse in Dusk Forest, Ruins, etc.

**Use Option B** — create `enemies/spawner/wave_spawner.tscn` with the 4 Marker2D children. Each zone can then instance this scene and reposition the markers to fit the zone layout.

### 6b. Enemy Container

Spawned enemies should be added to a dedicated `Node2D` container (e.g., `EnemyContainer`) that is a sibling or child of the spawner. This prevents clutter in the scene tree and makes bulk operations easy. If no container is found, fall back to `get_tree().current_scene`.

Approach:
- Add an `@export var enemy_container_path: NodePath = NodePath("")` to `wave_spawner.gd`.
- In `_ready()`, resolve it: `_enemy_container = get_node_or_null(enemy_container_path)`. If null, use `get_tree().current_scene`.

---

## 7. Integration with Existing Systems

### 7a. DayNightCycle

The spawner listens to `DayNightCycle.phase_changed(phase: String)`:
- `"NIGHT"` → `start_wave()`
- `"MORNING"` → `_cleanup_wave()`

The Night phase lasts **90 seconds** (per `DayNightCycle.PHASE_DURATIONS`). All enemies must be spawned and cleared within this window, or remaining enemies get cleaned up on morning transition.

### 7b. GameManager

- `GameManager.set_state(GameManager.GameState.DEFENSE)` is already called by DayNightCycle when Night begins. The spawner does NOT need to call `set_state` — it just reacts to the phase signal.
- The `wave_cleared` signal should be connected by the zone or a future `NightManager` to determine when the night is "survived" (CORE-09 will handle this).

### 7c. Shadowling (`enemies/shadowling/shadowling.gd`)

- Already has `activate()` method that transitions FSM from Idle → Scout.
- Already has `enemy_died` signal (from `EnemyBase`).
- Already adds itself to `"enemies"` group on `_ready()` and removes on `die()`.
- **Important:** The retreat state (`shadowling_retreat.gd`) calls `enemy.queue_free()` directly without calling `die()`. This means `enemy_died` will NOT fire for retreating enemies. The spawner MUST also connect to `tree_exiting` to catch this case.

### 7d. EnemyBase — Retreat Despawn Tracking

Currently `shadowling_retreat.gd` calls `e.queue_free()` directly at line 28. This bypasses `die()` and thus `enemy_died` is never emitted for retreating enemies. Two options:

- **Option A (preferred, minimal change):** In `wave_spawner.gd`, connect to **both** `enemy_died` and `tree_exiting` on each spawned enemy. Use a `Dictionary` or `Array` to track which enemies have already been counted as dead, preventing double-decrement.
- **Option B:** Modify `shadowling_retreat.gd` to call `enemy.die()` instead of `enemy.queue_free()`. This is cleaner but changes CORE-06 behavior (retreat would award kill energy/XP, which may not be desired).

**Use Option A** — do not modify CORE-06 files.

---

## 8. Existing Codebase Context (Verbatim File References)

### Autoloads (registered in `project.godot`):
- **`GameManager`** (`shared/autoloads/game_manager.gd`) — `GameState` enum: `EXPLORATION`, `PREPARATION`, `DEFENSE`, `GAME_OVER`, `TRANSITIONING`. Access `GameManager.dianthus_core`, `GameManager.player`.
- **`DayNightCycle`** (`core/day_night/day_night_cycle.gd`) — Signals: `phase_changed(phase: String)`. Methods: `is_night()`, `get_phase_name()`. Phase names are uppercase strings: `"MORNING"`, `"AFTERNOON"`, `"NIGHT"`. Night duration: 90 s.
- **`SceneTransition`** (`core/transitions/scene_transition.gd`).

### Collision Layers (from `project.godot` and `shared/collision_layers.gd`):
- Layer 1: interactable (1)
- Layer 2: terrain (2)
- Layer 3: player (4)
- Layer 4: enemy (8)
- Layer 5: projectile (16)

### Zone: Meadow Edge (`world/zones/meadow_edge/meadow_edge.gd`):
- `extends Node2D`, constants: `ZONE_WIDTH = 40`, `ZONE_HEIGHT = 30`, `TILE_SIZE = 16`.
- World bounds: 0,0 to 640,480.
- Registers Core and Player with `GameManager` in `_ready()`.
- Has `DebugOverlay` with phase/day/timer labels.
- Has `CanvasModulate` for day/night tinting.

### Shadowling scene (`enemies/shadowling/shadowling.tscn`):
- UID: `uid://d3nm4wr5o2abe`
- `CharacterBody2D` with FSM states, collision_layer=8, collision_mask=6.
- `activate()` method transitions from Idle → Scout.

### EnemyBase (`enemies/enemy_base.gd`):
- Signals: `hp_changed`, `enemy_died(enemy: EnemyBase)`, `damage_dealt`.
- `die()` sets `is_dead = true`, emits `enemy_died`, removes from `"enemies"` group, plays death anim, then `queue_free()`.
- `take_damage()` → `die()` if HP <= 0.

### Retreat despawn (`enemies/shadowling/states/shadowling_retreat.gd`):
- Calls `e.queue_free()` directly (line 28) — does **NOT** call `die()`, does **NOT** emit `enemy_died`.

### Player debug keys (`player/scripts/player_controller.gd`):
- F3: Player take 25 damage
- F4: Player heal 25
- F5: Spawn Shadowling at mouse
- F6: Kill all enemies (`call_group("enemies", "die")`)
- F7: Skip current phase

---

## 9. File Structure to Create

```
enemies/
└── spawner/
    ├── wave_spawner.gd          # WaveSpawner class — spawn logic, wave lifecycle
    ├── wave_spawner.gd.uid      # Auto-generated by Godot
    └── wave_spawner.tscn        # Scene with 4 Marker2D spawn points
```

### Files to Modify

- **`world/zones/meadow_edge/meadow_edge.tscn`** — Instance the `wave_spawner.tscn` as a child node. Add an `EnemyContainer` (Node2D) as a sibling for spawned enemies.
- **`world/zones/meadow_edge/meadow_edge.gd`** — Optionally connect `WaveSpawner.wave_cleared` and `wave_started` signals for debug logging or future CORE-09 integration. Add a `_wave_spawner` reference.
- **`player/scripts/player_controller.gd`** — Add **F8** debug key to manually trigger a wave (calls `WaveSpawner.start_wave()` for testing outside of Night phase). Add **F9** to force-clear current wave.

---

## 10. Debug / Testing Integration

Extend the existing debug key pattern (F1–F7 already used):

| Key | Action | Implementation |
|-----|--------|----------------|
| **F8** | Force-start a wave | Find the `WaveSpawner` in the scene tree and call `start_wave()`. Useful for testing during daytime. |
| **F9** | Force-clear current wave | Call `_cleanup_wave()` on the WaveSpawner. Kills all remaining wave enemies. |

Add these to `player_controller.gd` in `_unhandled_input()`:

```gdscript
elif event.keycode == KEY_F8:
    var spawner: Node = get_tree().current_scene.find_child("WaveSpawner", true, false)
    if spawner != null and spawner.has_method("start_wave"):
        spawner.start_wave()
        print("DEBUG: Force-started wave.")
    else:
        push_warning("DEBUG: WaveSpawner not found in scene.")
elif event.keycode == KEY_F9:
    var spawner: Node = get_tree().current_scene.find_child("WaveSpawner", true, false)
    if spawner != null and spawner.has_method("cleanup_wave"):
        spawner.cleanup_wave()
        print("DEBUG: Force-cleared wave.")
    else:
        push_warning("DEBUG: WaveSpawner not found in scene.")
```

Also print debug messages from the spawner itself:
- On wave start: `"[WaveSpawner] Wave started. Entry points: %d, Enemies: %d"`
- On each spawn: `"[WaveSpawner] Spawned enemy %d/%d at %s"`
- On enemy death/despawn: `"[WaveSpawner] Enemy removed. Remaining: %d"`
- On wave clear: `"[WaveSpawner] Wave cleared!"`

---

## 11. Acceptance Criteria

1. **Night triggers spawn:** When DayNightCycle transitions to Night, the WaveSpawner automatically starts spawning Shadowlings.
2. **Random entry points:** Each night, 1–3 of the 4 cardinal spawn points are randomly selected. Enemies only appear from active points.
3. **Staggered spawning:** Enemies spawn one at a time (or in small batches) with a configurable interval (default 1.5 s), not all at once.
4. **Enemies activate on spawn:** Each spawned Shadowling immediately calls `activate()` and begins moving toward the Core (Scout state).
5. **Wave cleared signal:** `wave_cleared` emits only after ALL spawned enemies have died (via combat) or despawned (via retreat `queue_free()`). No premature firing.
6. **Clean reset:** After a wave clears or morning arrives, the spawner resets to a clean state. Starting a new night produces a fresh wave with no leftover references.
7. **No orphan nodes:** All spawned enemies are properly freed. No leaked references. No errors in the console after wave completion.
8. **Morning cleanup:** If the night phase ends (e.g., via F7 debug skip) while enemies are still alive, the spawner force-clears all remaining enemies.
9. **Reusable across zones:** The `wave_spawner.tscn` can be instanced in any zone. Spawn point positions are set via Marker2D nodes, not hardcoded.
10. **Debug keys:** F8 force-starts a wave, F9 force-clears a wave. Both work correctly.
11. **No regressions:** Player controller, Core, Day/Night cycle, HUD, and Shadowling FSM all remain functional. Existing F1–F7 debug keys still work.

---

## 12. Design Decisions (Resolving GDD Ambiguities)

The GDD (§10.3) does not fully specify:

- **Number of enemies per wave:** Using **5** for the Day 1 vertical slice. DIFF-01 will scale this later (e.g., `base_count + day_count * 2`).
- **Spawn interval:** Using **1.5 seconds** between spawns. This gives the player ~7.5 s of total spawn time for 5 enemies, leaving ~82.5 s of Night for combat.
- **Spawn point selection algorithm:** Using `randi_range(min, max)` to pick how many points, then `array.shuffle()` and `.slice(0, count)` to pick which ones. Simple, fair, unpredictable.
- **Spawn offset jitter:** Using **24 px radius** around each Marker2D. Prevents visual stacking without scattering enemies too far from the intended entry corridor.
- **Multi-wave support:** NOT implemented in this task. The spawner handles exactly 1 wave per night. DIFF-01 and DIFF-02 will extend this to multiple waves and varying enemy types. The architecture should make this extension trivial (e.g., a `waves: Array[Dictionary]` config replacing the single config).
- **Enemy container:** Spawned enemies go into a dedicated `EnemyContainer` Node2D for scene tree cleanliness. If not found, fall back to `get_tree().current_scene`.

---

## 13. Future Extension Points (Do NOT Implement Now)

These are noted here so the architecture can accommodate them, but they are **out of scope** for CORE-07:

- **CORE-09 (Win Condition):** Will connect to `wave_cleared` to show the "Night Survived" result screen and transition to Morning.
- **DIFF-01 (Difficulty Scaling):** Will replace the hardcoded `total_enemies = 5` with a function of `DayNightCycle.day_count`. Will also introduce mixed enemy types per wave.
- **DIFF-02 (Surge Night):** Every 7th night, all 4 entry points active, 3× enemy count, all one tier stronger. The spawner should have a `force_all_entry_points()` or `override_entry_point_count(4)` method stub.
- **UI-01 (Wave Counter):** HUD will display wave number and remaining enemy count. The spawner's `_enemies_alive` should be readable via a getter or signal.
- **AUDIO-03 (Dynamic Music):** Night music layer intensity tied to enemy count. The spawner should expose `get_alive_count() -> int`.

Add `# TODO` comments at the appropriate locations for these future hooks.

---

## 14. Important Constraints

- **GDScript only** — no C#, no GDExtension.
- **Do NOT modify CORE-06 files** (`enemy_base.gd`, `shadowling.gd`, `shadowling_*.gd` states, `state.gd`, `state_machine.gd`) unless absolutely necessary for integration. If a change is needed, document and explain it.
- **Do NOT use `@onready` for nodes that might not exist** — use `get_node_or_null()` or `%UniqueNameInOwner` syntax with null checks.
- **Signals over direct references** — the zone scene should connect to `wave_started` / `wave_cleared` via signals, not by calling spawner internals directly.
- **Keep the spawner self-contained** — it should work in any zone scene as long as it has Marker2D children for spawn points.
- **Match existing code style** — tabs for indentation, type hints on all parameters and return types, `_` prefix for private methods/vars. Reference `player_controller.gd` and `enemy_base.gd` for conventions.
- **Performance:** Use `get_nodes_in_group("enemies")` sparingly. The spawner tracks its own enemies via `_spawned_enemies` array and `_enemies_alive` counter — do not poll the group every frame.
