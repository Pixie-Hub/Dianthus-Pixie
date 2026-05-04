# PROMPT — ENEMY-04 Swarm Larva

**Task ID:** ENEMY-04
**Category:** Enemy AI
**Priority:** High
**Effort:** L (~3–5 days)
**Dependencies:** CORE-06 (Shadowling FSM — done), ENEMY-01/02 (Voidrunner + Stonehusk — done), ENEMY-03 (Phantom Weaver — done), CORE-07 (WaveSpawner multi-pool — done), DIFF-01 (Difficulty Scaling — done)
**GDD Reference:** §8.1 — *Enemy Archetypes*

| Nama | HP | Kecepatan | Damage | FSM Quirk | Kelemahan | Muncul Hari |
|---|---|---|---|---|---|---|
| Swarm Larva | 15 per unit | Cepat | 3/hit | Bergerak 5-10 unit sekaligus | AoE weapon (Spore Bomb / Rafflesia) | Hari 8 |

> **GDD Ambiguity (§8.1):** "GDD §8.1 does not clarify whether each unit has an independent FSM or a shared group FSM." This prompt resolves the ambiguity: **each unit gets its own independent FSM** (see §Design Decisions below for rationale).

---

## Goal

Implement the **Swarm Larva** — a fast, fragile, low-damage enemy that spawns in groups of 5–10 units. Each larva is an independent `EnemyBase` instance with its own FSM, but the group uses **flocking-style cohesion** in their Scout state to produce the visual effect of coordinated movement toward the Core. Mechanically distinct from all existing enemies: individually trivial, dangerous in volume, and countered by AoE weapons (Spore Bomb, Void Grenade, Bougainvillea, Rafflesia).

---

## Scope

### In Scope
1. **Swarm Larva enemy** — new `enemies/swarm_larva/` scripts + `.tscn`. FSM: `Idle → Swarm (custom Scout) → Siege → Attack`. No Retreat state — swarm larva never retreats.
2. **Swarm Scout state** — extends `EnemyScoutState` with flocking cohesion: each larva steers toward the Core but also nudges toward the average position of nearby larva (group cohesion). Produces coordinated-looking group movement without a shared controller.
3. **Batch spawning** — when the WaveSpawner picks `"swarm_larva"`, it spawns a cluster of `SWARM_BATCH_SIZE` (5–10, randomized) units at the same spawn point in quick succession, rather than a single unit.
4. **AoE weakness** — implicit, not a damage multiplier. Low HP (15) means AoE weapons (Spore Bomb 20 DMG, Void Grenade 30 DMG, Bougainvillea 5 DMG/tick, Rafflesia slow) one-shot or rapidly thin the swarm. Leave a `TODO: ENEMY-WEAKNESS` stub for future explicit multiplier system.
5. **WaveSpawner integration** — add Swarm Larva to `ENEMY_POOL` (min_day=8, weight=0.5). Implement batch spawn logic in `_spawn_enemy()`.
6. **Debug F5 cycle** — extend to include Swarm Larva (spawns a batch of 5 on F5).
7. **Sprite** — use `icon.svg` placeholder with `modulate = Color(0.3, 0.4, 0.2, 1)` (worm-like green-brown per `GEMINI_ENEMY_SPRITES_PROMPT.md`) and small scale `(0.35, 0.35)`.
8. **SFX** — wire `swarm_larva_skitter` (SFX #45) on Scout enter and `swarm_larva_death` (SFX #46) on die. These IDs are already registered in `SfxManager` per `SFX_LIST.md`.
9. **Save/Load** — no schema change. Enemy types are transient.

### Out of Scope
- Real polished VFX/SFX assets (covered later by VFX-03 / AUDIO-04). Use placeholder animations and existing registered SFX IDs.
- Shared group FSM / group controller node — explicitly rejected. Each unit is independent (see Design Decisions).
- Damage multiplier for AoE weakness — use `TODO: ENEMY-WEAKNESS` stub.
- ENEMY-05 (The Devourer).

---

## Design Decisions (Locked Values)

### FSM Architecture: Independent per-unit

**Decision:** Each Swarm Larva is a standard `EnemyBase` with its own `StateMachine`. No shared group FSM or group controller node.

**Rationale:**
1. **Consistency** — all other enemies use independent FSMs. A shared controller would be a new pattern requiring new infrastructure.
2. **Simplicity** — group cohesion is achieved cheaply by scanning `"swarm_larvae"` group in each unit's Scout state. No coordinator lifetime management, no edge cases with partial group death.
3. **Robustness** — each larva handles its own stun, slow, pull, death independently. AoE weapons kill individuals without corrupting group state.
4. **Visual cohesion** — flocking via `get_tree().get_nodes_in_group(&"swarm_larvae")` naturally produces coordinated movement. Units that fall behind or get stunned automatically rejoin the nearest cluster.

### Stats

| Parameter | Value | Rationale |
|---|---|---|
| `max_hp` | 15 | Per GDD §8.1 — fragile, AoE one-shots |
| `damage` | 3 | Per GDD §8.1 — individually weak |
| `move_speed` | 55.0 | "Cepat" — between Shadowling (40) and PhantomWeaver (60). Fast enough to overwhelm, slow enough to be catchable. |
| `detection_radius` | 40.0 | Narrow — swarm focuses on Core, not player hunting |
| `attack_range` | 12.0 | Very close range — must swarm target |
| `attack_cooldown` | 0.5 | Fast nibble attacks — death by a thousand cuts |
| `ally_proximity_radius` | 48.0 | Tighter than default — swarm sticks together |
| `min_day` (spawn) | 8 | Per GDD §8.1 |
| `pool_weight` | 0.5 | Moderate — each "pick" spawns 5–10 units, so effective weight is high |
| `SWARM_BATCH_MIN` | 5 | GDD "spawns 5–10 per" |
| `SWARM_BATCH_MAX` | 10 | GDD "spawns 5–10 per" |
| Flocking cohesion weight | 0.3 | How strongly each larva steers toward flock center (0 = ignore flock, 1 = only flock) |
| Flocking radius | 64.0 px | How far to scan for nearby swarm members |

### Sprite Placeholder

Per `GEMINI_ENEMY_SPRITES_PROMPT.md`: Swarm Larva is 32×32 pixel art, `Color(0.3, 0.4, 0.2, 1)` green-brown. Use `icon.svg` placeholder at `scale = (0.35, 0.35)` (smaller than Shadowling's 0.5 to convey "small swarm unit").

---

## Existing Architecture Reference

### EnemyBase hooks already in place
- `take_damage(amount)` — standard. No override needed.
- `die()` — standard. Override `_get_death_sfx_id()` to return `"swarm_larva_death"`.
- `should_retreat()` — **override to return `false`**. Swarm Larva never retreats individually.
- `play_animation(anim_name)` — safe StringName playback.
- `is_stunned()` — every state early-returns when true. Standard.
- `add_to_group(&"enemies")` — automatic in `_ready()`. Additionally call `add_to_group(&"swarm_larvae")` for flocking queries.

### FSM base state classes (refactored)
After the refactor (commit 6dac393), all enemy states extend base classes:
- `EnemyIdleState` — virtual `_get_active_state()→&"Scout"`.
- `EnemyScoutState` — virtuals: `_get_nav_update_interval()`, `_get_wander_angle_max()`, `_get_scout_fallback_state()`, `_check_retreat()`, `_check_player_detection()`, `_pre_checks()`.
- `EnemySiegeState` — virtuals: `_get_scout_fallback_state()`, `_check_retreat()`, `_pre_checks()`.
- `EnemyAttackState` — virtuals: `_get_leash_multiplier()`, `_get_chase_speed_multiplier()`, `_get_scout_fallback_state()`, `_get_player_dead_fallback_state()`, `_check_retreat()`, `_pre_checks()`.
- `EnemyRetreatState` — not used for Swarm Larva.

Swarm Larva states override only the necessary virtuals (no retreat, custom Scout with flocking).

### WaveSpawner batch spawn

The existing `_spawn_enemy()` spawns one unit per call. For Swarm Larva, we need batch spawning:
- When `_pick_enemy_scene()` returns a swarm_larva scene, spawn `randi_range(SWARM_BATCH_MIN, SWARM_BATCH_MAX)` units at the same spawn point with slight position offsets.
- Each unit counts toward `_enemies_alive` and `_enemies_spawned` individually.
- The `_current_wave_total` absorbs these extra spawns — a swarm "pick" consumes multiple slots from the wave budget.

### Existing reference enemies (post-refactor)
- Shadowling states: pure one-liners extending base classes (all defaults).
- Phantom Weaver states: extend base classes + override `_check_retreat()→false` + `_pre_checks()` for teleport flag.
- Voidrunner: Idle overrides `_get_active_state()→&"Rush"`.

---

## Implementation Plan

### Phase 1 — Swarm Larva Script (`enemies/swarm_larva/swarm_larva.gd`)

```gdscript
class_name SwarmLarva
extends EnemyBase

# TODO: ENEMY-WEAKNESS — GDD §8.1 lists AoE weapons (Spore Bomb, Rafflesia) as weakness.
# Implement damage multiplier here once the generic weakness-multiplier system is built.
# Mechanical weakness is already implicit: 15 HP means Spore Bomb (20 DMG) and
# Void Grenade (30 DMG) one-shot; Bougainvillea (5 DMG/tick) kills in 3 ticks;
# Rafflesia slow keeps the swarm in AoE zones longer.


func _ready() -> void:
    super._ready()
    add_to_group(&"swarm_larvae")


func activate() -> void:
    SfxManager.play_at("swarm_larva_skitter", global_position)
    var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
    if fsm != null:
        fsm.transition_to(&"Idle")


# Override: Swarm Larva never retreats.
func should_retreat() -> bool:
    return false


func _get_death_sfx_id() -> String:
    return "swarm_larva_death"


func _get_seed_drop_table() -> Array[Dictionary]:
    # Low individual drop chance — balanced by high kill volume.
    return [
        {"item": "rafflesia_seed", "chance": 0.05},
        {"item": "bougainvillea_seed", "chance": 0.05},
    ]
```

### Phase 2 — Swarm Larva Scene (`enemies/swarm_larva/swarm_larva.tscn`)

Mirror the structure of `shadowling.tscn`:
- Root: `CharacterBody2D` with `swarm_larva.gd` script.
- `%Sprite2D` — texture `res://icon.svg`, scale `(0.35, 0.35)`, modulate `Color(0.3, 0.4, 0.2, 1)`.
- `%CollisionShape2D` — CapsuleShape2D radius=1.5, height=3.0 (smaller than Shadowling's 2.0/4.0).
- `%AnimationPlayer` — at minimum `RESET`, `idle`, `walk`, `attack` (placeholder scale tweens).
- `%NavigationAgent2D` — default config.
- `StateMachine` (Node) with children: `Idle`, `Swarm` (custom Scout), `Siege`, `Attack`. **No Retreat state.**
- `DetectionArea` + `AttackArea` — same structure as Shadowling but smaller radii (detection=40, attack=12).
- `@export` overrides on root: `max_hp=15`, `damage=3`, `move_speed=55.0`, `detection_radius=40.0`, `attack_range=12.0`, `attack_cooldown=0.5`, `ally_proximity_radius=48.0`.
- `uid="uid://swarm_larva_01"`.

### Phase 3 — States (`enemies/swarm_larva/states/`)

#### 3a. `swarm_larva_idle.gd`
Extends `EnemyIdleState`. Default behavior — waits for night, transitions to `Swarm` (custom Scout state).

```gdscript
extends EnemyIdleState


func _get_active_state() -> StringName:
    return &"Swarm"
```

#### 3b. `swarm_larva_swarm.gd` — CUSTOM SCOUT STATE

This is the key differentiating state. Extends `EnemyScoutState` and overrides `_move()` to add flocking cohesion.

```gdscript
extends EnemyScoutState

const FLOCK_COHESION_WEIGHT: float = 0.3
const FLOCK_RADIUS: float = 64.0


func _get_wander_angle_max() -> float:
    return deg_to_rad(20.0)


func _get_scout_fallback_state() -> StringName:
    return &"Swarm"


func _check_retreat(_e: EnemyBase) -> bool:
    return false


func _move(e: EnemyBase, _delta: float) -> void:
    var direction: Vector2
    var has_path: bool = (not _use_direct_steering
        and is_instance_valid(_nav_agent)
        and _nav_agent.get_current_navigation_path().size() > 1)
    if has_path:
        direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
    else:
        direction = (e.get_core_position() - e.global_position).normalized()

    var wander_max: float = _get_wander_angle_max()
    if wander_max > 0.0:
        var wander_angle: float = randf_range(-wander_max, wander_max)
        direction = direction.rotated(wander_angle)

    # Flocking: steer toward center of nearby swarm members.
    var flock_center: Vector2 = Vector2.ZERO
    var flock_count: int = 0
    for node in e.get_tree().get_nodes_in_group(&"swarm_larvae"):
        if node == e or not is_instance_valid(node):
            continue
        if e.global_position.distance_to(node.global_position) <= FLOCK_RADIUS:
            flock_center += node.global_position
            flock_count += 1
    if flock_count > 0:
        flock_center /= float(flock_count)
        var to_flock: Vector2 = (flock_center - e.global_position).normalized()
        direction = (direction * (1.0 - FLOCK_COHESION_WEIGHT) + to_flock * FLOCK_COHESION_WEIGHT).normalized()

    e.velocity = direction * e.get_effective_speed()
    e.move_and_slide()
```

> **Flocking cost:** `get_nodes_in_group` is O(N) where N = swarm_larvae alive. At 10–20 units this is negligible. If performance becomes an issue at scale, cache the group query per-frame via a static or autoload — but premature for ENEMY-04.

#### 3c. `swarm_larva_siege.gd`

Extends `EnemySiegeState`. No retreat, fallback state is `Swarm`.

```gdscript
extends EnemySiegeState


func _get_scout_fallback_state() -> StringName:
    return &"Swarm"


func _check_retreat(_e: EnemyBase) -> bool:
    return false
```

#### 3d. `swarm_larva_attack.gd`

Extends `EnemyAttackState`. No retreat. Very short leash — returns to swarming the Core quickly. Fallback state is `Swarm`.

```gdscript
extends EnemyAttackState


func _get_leash_multiplier() -> float:
    return 1.0


func _get_chase_speed_multiplier() -> float:
    return 1.0


func _get_scout_fallback_state() -> StringName:
    return &"Swarm"


func _get_player_dead_fallback_state() -> StringName:
    return &"Swarm"


func _check_retreat(_e: EnemyBase) -> bool:
    return false
```

### Phase 4 — WaveSpawner Batch Spawn Integration

Modify `enemies/spawner/wave_spawner.gd`:

1. Add `"swarm_larva": preload("res://enemies/swarm_larva/swarm_larva.tscn")` to `ENEMY_SCENES`.
2. Append `{ "type": "swarm_larva", "weight": 0.5, "min_day": 8 }` to `ENEMY_POOL`.
3. Add batch spawn constants and modify `_spawn_enemy()` to handle swarm batching.

**Batch spawn logic:**

```gdscript
const SWARM_BATCH_MIN: int = 5
const SWARM_BATCH_MAX: int = 10

# Modified _spawn_enemy:
# After picking scene, check if it's a swarm_larva scene.
# If so, spawn SWARM_BATCH_MIN..MAX units at same base_pos with slight offsets.
# Each unit counts individually toward _enemies_spawned and _enemies_alive.
```

**Implementation approach:** Add a helper `_get_batch_size(scene_type: String) -> int` that returns `randi_range(5, 10)` for `"swarm_larva"` and `1` for everything else. Modify the spawn loop in `_process()` to account for batch sizes when checking `_enemies_spawned < _current_wave_total`.

Alternatively, refactor `_spawn_enemy()` to accept an optional `batch_override: int = 1` parameter. The simpler approach: make `_spawn_enemy` return the number of units spawned, and call the inner spawn logic in a loop when swarm_larva is selected.

**Recommended approach (minimal change):**

Replace the single `_pick_enemy_scene()` call in `_spawn_enemy()` with a two-step process:

```gdscript
func _spawn_enemy() -> void:
    if _active_spawn_points.is_empty():
        return
    var picked_type: String = _pick_enemy_type()
    var batch: int = _get_batch_size(picked_type)
    var base_pos: Vector2 = _active_spawn_points[randi() % _active_spawn_points.size()]
    for _b in batch:
        if _enemies_spawned >= _current_wave_total:
            break
        _spawn_single_enemy(ENEMY_SCENES[picked_type], base_pos)


func _pick_enemy_type() -> String:
    # Same weighted random logic as _pick_enemy_scene, but returns type string
    ...


func _get_batch_size(enemy_type: String) -> int:
    if enemy_type == "swarm_larva":
        return randi_range(SWARM_BATCH_MIN, SWARM_BATCH_MAX)
    return 1


func _spawn_single_enemy(scene: PackedScene, base_pos: Vector2) -> void:
    # All existing spawn logic from current _spawn_enemy(), extracted
    ...
```

This refactors `_spawn_enemy()` into `_pick_enemy_type()` + `_get_batch_size()` + `_spawn_single_enemy()`. The `_process()` loop stays unchanged.

### Phase 5 — Debug Cycle (`player/scripts/player_controller.gd`)

Extend `DEBUG_ENEMY_SCENES` to include the new scene path:

```gdscript
const DEBUG_ENEMY_SCENES: Array[String] = [
    "res://enemies/shadowling/shadowling.tscn",
    "res://enemies/voidrunner/voidrunner.tscn",
    "res://enemies/stonehusk/stonehusk.tscn",
    "res://enemies/phantom_weaver/phantom_weaver.tscn",
    "res://enemies/swarm_larva/swarm_larva.tscn",  # NEW
]
```

**F5 behavior for Swarm Larva:** When the cycle reaches swarm_larva, spawn a batch of 5 units at mouse position (with small random offsets). This gives a visual preview of the swarm behavior. All other enemy types spawn 1 unit as before.

### Phase 6 — Documentation

- `docs/design/PERSON_TASKS.md` — F5 row: append "→ Swarm Larva (×5)" to the cycle description.
- `docs/design/TASK_BREAKDOWN.md` — change ENEMY-04 status from `Not Started` to `Done`.

---

## Files to Create

| File | Purpose |
|---|---|
| `enemies/swarm_larva/swarm_larva.gd` | Entity script (extends EnemyBase). Adds to `swarm_larvae` group. No retreat. Low seed drop chance. |
| `enemies/swarm_larva/swarm_larva.tscn` | Scene: `CharacterBody2D` + Sprite2D + CollisionShape2D + AnimationPlayer + NavigationAgent2D + StateMachine(Idle, Swarm, Siege, Attack). No Retreat. |
| `enemies/swarm_larva/states/swarm_larva_idle.gd` | Idle → Swarm on night. |
| `enemies/swarm_larva/states/swarm_larva_swarm.gd` | Custom Scout with flocking cohesion. No retreat. |
| `enemies/swarm_larva/states/swarm_larva_siege.gd` | Siege, no retreat, fallback → Swarm. |
| `enemies/swarm_larva/states/swarm_larva_attack.gd` | Attack, no retreat, short leash (1.0×), fallback → Swarm. |

## Files to Modify

| File | Change |
|---|---|
| `enemies/spawner/wave_spawner.gd` | Add `swarm_larva` to `ENEMY_SCENES` and `ENEMY_POOL` (weight 0.5, min_day 8). Refactor `_spawn_enemy()` into `_pick_enemy_type()` + `_get_batch_size()` + `_spawn_single_enemy()` to support batch spawning. |
| `player/scripts/player_controller.gd` | Append swarm_larva scene path to `DEBUG_ENEMY_SCENES`. Modify F5 handler to spawn batch of 5 when swarm_larva is selected. |
| `docs/design/PERSON_TASKS.md` | Update F5 debug row to include "→ Swarm Larva (×5)". |
| `docs/design/TASK_BREAKDOWN.md` | ENEMY-04 status → Done. |

---

## Acceptance Criteria

1. Swarm Larva instance spawns with **HP 15**, **DMG 3**, **speed 55**, **attack_cooldown 0.5**, **detection_radius 40**, **attack_range 12**.
2. Each Swarm Larva is an independent `EnemyBase` instance in the `"enemies"` AND `"swarm_larvae"` groups.
3. On `activate()`, FSM enters `Idle`; once `DayNightCycle.is_night()`, transitions to `Swarm`.
4. `Swarm` state moves toward Core with flocking cohesion: each larva steers 70% toward Core + 30% toward average position of nearby swarm_larvae within 64 px. Visual result: clumped movement in the same direction.
5. Swarm state transitions to `Siege` when Core is within `attack_range`, to `Attack` when player is within `detection_radius`. Standard barricade detection applies.
6. `should_retreat()` returns `false` — swarm larva never retreats.
7. No `Retreat` state node in the scene's StateMachine.
8. WaveSpawner spawns Swarm Larvae from **Day 8** onward at pool weight **0.5**.
9. When `"swarm_larva"` is picked by the weighted random, **5–10 units** are spawned at the same spawn point with slight position offsets. Each unit counts individually toward `_enemies_alive`/`_enemies_spawned`.
10. Batch spawning respects `_current_wave_total` — if only 3 slots remain and a batch of 7 is rolled, only 3 larvae spawn.
11. All standard difficulty scaling (HP/DMG/speed multipliers from DifficultyManager + per-day growth + endless mode) applies to each larva individually.
12. AoE weapons effectively counter the swarm: Spore Bomb (20 DMG) one-shots, Void Grenade (30 DMG) one-shots, Bougainvillea (5 DMG/tick) kills in 3 ticks, Rafflesia slow keeps the swarm in kill zones.
13. F5 debug spawn cycles `Shadowling → Voidrunner → Stonehusk → Phantom Weaver → Swarm Larva (×5) → …` and adds all spawns to `YSortLayer`.
14. SFX: `"swarm_larva_skitter"` plays on activate; `"swarm_larva_death"` plays on die (both already registered IDs in SfxManager).
15. Seed drops: 5% chance for `rafflesia_seed`, 5% chance for `bougainvillea_seed` per killed larva. Volume-balanced — many kills, low per-unit rate.
16. Wave start log includes `"swarm_larva"` in `available_types` from Day 8.

---

## Notes & Risks

- **Performance at scale:** 10–20 swarm larvae each calling `get_nodes_in_group(&"swarm_larvae")` per physics frame at 0.5s intervals is ~20–40 group lookups per second. Godot handles this efficiently for groups under ~100. No optimization needed for ENEMY-04 scope.
- **Wave budget consumption:** A single swarm pick consumes 5–10 slots from `_current_wave_total`. On Day 8 with ~13 total enemies, one swarm pick could consume most of the budget. This is intentional — it creates "swarm nights" vs "mixed nights" variety.
- **Flocking without separation:** The current flocking only has cohesion (steer toward center), not separation (steer away from overlapping). This means larvae can overlap visually. Acceptable for a small 32×32 sprite at 0.35 scale — the overlapping swarm pile reads as "dense group" which is thematically correct. Add separation force later if it looks bad during playtest.
- **No wander dampening in flock:** The `WANDER_ANGLE_MAX = 20°` combined with `FLOCK_COHESION_WEIGHT = 0.3` produces a jittery-but-cohesive movement pattern. This actually looks good for insect swarm behavior. Reduce cohesion weight if the movement feels too snappy.
- **Batch spawn and wave_spawner refactor:** The refactor from `_spawn_enemy()` to `_pick_enemy_type()` + `_spawn_single_enemy()` is a mild breaking change to the spawn method signature. All existing behavior is preserved — non-swarm types return batch size 1. Test by playing a full night on Days 1–7 to confirm no regression.
- **Sprite scale asymmetry:** At `0.35` scale, the `icon.svg` placeholder will appear noticeably smaller than Shadowling (0.5). This is intentional — "small and numerous" is the visual identity. Replace with real 32×32 sprite per `GEMINI_ENEMY_SPRITES_PROMPT.md`.
- **SFX IDs:** `swarm_larva_skitter` (#45) and `swarm_larva_death` (#46) are already registered in `SfxManager` per `SFX_LIST.md`. If no audio files are loaded yet, `SfxManager.play_at()` will silently no-op — no crash.
- **`TODO: ENEMY-WEAKNESS` stub:** Add a comment in `swarm_larva.gd` documenting the GDD-listed weakness (AoE weapons) for the future weakness-multiplier system. Same pattern as Phantom Weaver's `TODO: ENEMY-WEAKNESS`.
- **No save schema bump:** confirmed — Swarm Larva state is purely runtime. Enemies are not persisted across save/load.
- **Idle → Swarm (not Scout):** The custom Scout state is named `Swarm` in the StateMachine to clearly differentiate from standard Scout behavior. The Idle state overrides `_get_active_state()` to return `&"Swarm"`.
