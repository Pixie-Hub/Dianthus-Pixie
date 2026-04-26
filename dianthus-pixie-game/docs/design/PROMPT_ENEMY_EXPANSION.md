# PROMPT — ENEMY-01 / ENEMY-02 + Shadowling FSM Improvement

**Task IDs:** ENEMY-01, ENEMY-02, CORE-06 (improvement)
**Category:** Enemy AI
**Priority:** High
**Effort:** M each (~3–5 days total bundled)
**Dependencies:** CORE-06 (Shadowling FSM — done), CORE-07 (Wave Spawner — done), DIFF-01 (Difficulty Scaling — done), PLANT-09/10/11 (Weapon Behaviors — done)
**GDD Reference:** §8.1 — *Enemy Archetypes*

| Nama | HP | Kecepatan | Damage | FSM Quirk | Kelemahan | Muncul Hari |
|---|---|---|---|---|---|---|
| Shadowling | 40 | Sedang | 8/hit | Standard FSM | Melati, Kecombrang | Hari 1 |
| Voidrunner | 25 | Sangat Cepat | 5/hit | Skip Scouting — langsung Rush | Slow trap, Rafflesia | Hari 2 |
| Stonehusk | 120 | Lambat | 20/hit | Tidak retreat — terus Siege sampai mati | Vine Whip, Crystal Lash | Hari 4 |

**GDD Reference:** §8.2 — *Difficulty Scaling*
- Hari 1–5 (Early): HP +5%/day, spawn +1/wave
- Hari 6–14 (Mid): HP +8%/day, spawn +2, speed +10%, new enemies appear
- Hari 15–29 (Late): HP +12%/day, multi-wave per night, mixed enemy types

---

## Goal

1. **Improve the Shadowling FSM** — add player detection during Scout, stun-awareness in all states, animation playback, and cleaner retreat logic.
2. **Implement Voidrunner (ENEMY-01)** — a fast, fragile enemy that skips Scouting entirely, rushing straight to the Core. Weak to slow effects.
3. **Implement Stonehusk (ENEMY-02)** — a slow, tanky enemy that never retreats. Stays in Siege/Attack until death. Weak to pull effects (Vine Whip / Crystal Lash).
4. **Upgrade WaveSpawner** — support multiple enemy types chosen by `DayNightCycle.day_count`, with weighted random selection.

---

## Scope

### In Scope
1. **Shadowling FSM improvements** — player detection in Scout, stun check in all states, animation calls (`idle`/`walk`/`attack`), better leash/retreat transitions.
2. **Voidrunner enemy** — new `enemies/voidrunner/` scripts + `.tscn`. FSM: Idle → Rush (skip Scout, beeline Core at high speed) → Siege → Attack. No Retreat state. Very fast (`move_speed = 80.0`), low HP (25), low damage (5).
3. **Stonehusk enemy** — new `enemies/stonehusk/` scripts + `.tscn`. FSM: Idle → Scout → Siege → Attack. No Retreat state — `should_retreat()` always returns `false`. Slow (`move_speed = 20.0`), high HP (120), high damage (20). Resistant to knockback (pull distance halved).
4. **Multi-enemy WaveSpawner** — replace `@export var enemy_scene: PackedScene` with an `ENEMY_POOL` configuration that maps day thresholds to available enemy types with spawn weights.
5. **Placeholder visuals** — use existing `.png` sprites (`voidrunner.png`, `stonehusk.png`) already in `enemies/voidrunner/` and `enemies/stonehusk/`. Sprite scale to match Shadowling convention (`0.5, 0.5` scale on `Sprite2D`).
6. **Debug keys** — F5 cycles spawned enemy type (Shadowling → Voidrunner → Stonehusk).
7. **Save/Load** — no schema change needed. Enemy types are transient (not persisted). Wave spawner state is already handled by DayNightCycle day_count.

### Out of Scope
- Real polished VFX/SFX for new enemies (covered by VFX-03 / AUDIO-04). Use placeholder animations and `print`.
- ENEMY-03 (Phantom Weaver), ENEMY-04 (Swarm Larva), ENEMY-05 (Devourer).
- Navigation mesh setup (enemies use direct steering fallback when NavigationAgent2D has no path — keep this behavior).
- Weakness-specific damage multipliers (e.g., "Stonehusk takes extra damage from Vine Whip"). The GDD lists these as weaknesses but does not define a multiplier system. Leave `TODO: ENEMY-WEAKNESS` stub comments for a future elemental/weakness system.

---

## Existing Architecture Reference

### EnemyBase (`enemies/enemy_base.gd`)

```gdscript
class_name EnemyBase
extends CharacterBody2D

@export var max_hp: int = 40
@export var damage: int = 8
@export var move_speed: float = 40.0
@export var detection_radius: float = 80.0
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var ally_proximity_radius: float = 96.0

# Already has: take_damage, die, get_effective_speed, is_stunned,
# apply_timed_slow, apply_stun, apply_pull, should_retreat,
# get_core_position, get_player_position, distance_to_player, distance_to_core,
# count_nearby_allies, _flash_damage, _play_death_animation
```

- `should_retreat()` returns `true` when HP < 20% AND < 2 allies nearby. Override in Stonehusk to always return `false`.
- `get_effective_speed()` already handles `speed_modifier * timed_slow`. No change needed.
- `apply_pull()` already disables FSM physics briefly. Stonehusk should halve the pull distance.

### FSM Framework (`enemies/fsm/`)

- `StateMachine` — reads child `State` nodes by name, calls `enter()`/`exit()`/`update(delta)`/`physics_update(delta)`. Transitions via `transition_to(state_name: StringName)`.
- `State` — base class with `enemy`, `state_machine` refs. Override `enter`, `exit`, `update`, `physics_update`.

### Shadowling Current States (`enemies/shadowling/states/`)

| State | File | Behavior |
|---|---|---|
| `Idle` | `shadowling_idle.gd` | Waits for night, transitions to Scout |
| `Scout` | `shadowling_scout.gd` | Moves toward Core using nav agent or direct steering; wander offset. Transitions: → Siege (at Core range), → Retreat (low HP + few allies) |
| `Siege` | `shadowling_siege.gd` | Attacks Core on cooldown. Transitions: → Attack (player in range), → Retreat, → Scout (Core moved out of range) |
| `Attack` | `shadowling_attack.gd` | Chases and attacks player. Transitions: → Retreat, → Scout (player too far = leash × 1.5) |
| `Retreat` | `shadowling_retreat.gd` | Flees away from Core for 5s or until 300px away, then `queue_free()` |

**Issues to fix:**
1. **No player detection in Scout** — enemy walks past the player toward Core without reacting. Should transition to Attack when player is within `detection_radius`.
2. **No stun awareness** — stunned enemies still try to move in FSM states. Each state's `physics_update` should early-return when `enemy.is_stunned()`.
3. **No animation calls** — `_anim_player` exists in the scene but states never call `play()`.
4. **Retreat always queue_frees** — enemies that retreat should despawn cleanly but still count toward wave tracking (already handled by `tree_exiting` signal in WaveSpawner).

### WaveSpawner (`enemies/spawner/wave_spawner.gd`)

Currently only spawns one enemy type via `@export var enemy_scene: PackedScene = preload("res://enemies/shadowling/shadowling.tscn")`. Must be upgraded to support multiple types.

### Collision Layers

```
INTERACTABLE = 1, TERRAIN = 2, PLAYER = 4, ENEMY = 8, PROJECTILE = 16
```

All enemy types use `collision_layer = ENEMY`, `collision_mask = PLAYER`.

### Existing Sprites

- `enemies/voidrunner/voidrunner.png` — already imported
- `enemies/stonehusk/stonehusk.png` — already imported
- `enemies/shadowling/shadowling.png` — in use

---

## Implementation Plan

### Phase 1 — Shadowling FSM Improvements

Modify existing state files in `enemies/shadowling/states/`:

#### 1a. All States — Stun Guard

Add early-return to `physics_update` in every state:

```gdscript
func physics_update(delta: float) -> void:
    var e: EnemyBase = enemy as EnemyBase
    if e == null or e.is_stunned():
        return
    # ... rest of state logic
```

#### 1b. Scout — Player Detection

Add player detection check in `shadowling_scout.gd`, after the retreat check:

```gdscript
func physics_update(delta: float) -> void:
    var e: EnemyBase = enemy as EnemyBase
    if e == null or e.is_stunned():
        return
    if e.should_retreat():
        state_machine.transition_to(&"Retreat")
        return
    # NEW: Detect player — switch to Attack if player is close
    if e.distance_to_player() <= e.detection_radius:
        state_machine.transition_to(&"Attack")
        return
    if e.distance_to_core() <= e.attack_range:
        state_machine.transition_to(&"Siege")
        return
    # ... nav + move logic unchanged
```

#### 1c. Animation Calls

- **Idle:** play `idle` on enter
- **Scout:** play `walk` on enter
- **Attack:** play `walk` while moving, play `attack` on each hit (check if `_anim_player` has the animation before calling)
- **Siege:** play `attack` on each Core hit
- **Retreat:** play `walk` on enter

Use a helper on `EnemyBase`:

```gdscript
func play_animation(anim_name: StringName) -> void:
    if is_instance_valid(_anim_player) and _anim_player.has_animation(anim_name):
        if _anim_player.current_animation != anim_name:
            _anim_player.play(anim_name)
```

#### 1d. Siege — Attack Animation on Hit

In `shadowling_siege.gd`, play `attack` animation when dealing damage to Core:

```gdscript
if _attack_timer <= 0.0:
    _attack_timer = e.attack_cooldown
    e.play_animation(&"attack")
    if is_instance_valid(GameManager.dianthus_core):
        GameManager.dianthus_core.take_damage(e.damage)
        e.damage_dealt.emit(GameManager.dianthus_core, e.damage)
```

### Phase 2 — Voidrunner (ENEMY-01)

**Concept:** Glass cannon speedster. Skips Scouting, immediately rushes the Core at double Shadowling speed. Dies quickly, but if it reaches the Core, it hammers away with fast attacks. Weak to slow effects (Rafflesia, Spore Bomb) that negate its speed advantage.

#### 2a. New Files

| File | Purpose |
|---|---|
| `enemies/voidrunner/voidrunner.gd` | `class_name Voidrunner extends EnemyBase` |
| `enemies/voidrunner/voidrunner.tscn` | Scene: CharacterBody2D + Sprite2D + CollisionShape2D + AnimationPlayer + StateMachine(Idle, Rush, Siege, Attack) + DetectionArea + AttackArea + NavigationAgent2D |
| `enemies/voidrunner/states/voidrunner_idle.gd` | Same as Shadowling idle |
| `enemies/voidrunner/states/voidrunner_rush.gd` | Replaces Scout — beeline to Core at full speed, no wander. Transitions: → Siege (Core in range), → Attack (player in detection_radius AND player blocks path, i.e., player is closer than Core) |
| `enemies/voidrunner/states/voidrunner_siege.gd` | Attacks Core. Transitions: → Attack (player in range). No retreat check. |
| `enemies/voidrunner/states/voidrunner_attack.gd` | Attacks player. Transitions: → Rush (player too far). No retreat check. Short leash — returns to rushing Core quickly. |

#### 2b. Voidrunner Script

```gdscript
class_name Voidrunner
extends EnemyBase


func _ready() -> void:
    super._ready()


func activate() -> void:
    var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
    if fsm != null:
        fsm.transition_to(&"Rush")


# Override: Voidrunner never retreats.
func should_retreat() -> bool:
    return false
```

#### 2c. Voidrunner Stats (set in .tscn or @export overrides)

| Stat | Value | Notes |
|---|---|---|
| `max_hp` | 25 | Fragile |
| `damage` | 5 | Low per hit |
| `move_speed` | 80.0 | ~2× Shadowling (40) |
| `detection_radius` | 48.0 | Narrow — focuses on Core |
| `attack_range` | 16.0 | Close-range melee |
| `attack_cooldown` | 0.6 | Fast attacks |

#### 2d. Rush State (key difference from Scout)

```gdscript
extends State

const NAV_UPDATE_INTERVAL: float = 0.3

var _nav_timer: float = 0.0
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false


func enter() -> void:
    _nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
    _use_direct_steering = _nav_agent == null
    _nav_timer = NAV_UPDATE_INTERVAL
    _update_target()
    var e: EnemyBase = enemy as EnemyBase
    if e != null:
        e.play_animation(&"walk")


func physics_update(delta: float) -> void:
    var e: EnemyBase = enemy as EnemyBase
    if e == null or e.is_stunned():
        return
    if e.distance_to_core() <= e.attack_range:
        state_machine.transition_to(&"Siege")
        return
    # Only switch to Attack if player is CLOSER than Core and within detection range.
    if e.distance_to_player() <= e.detection_radius and e.distance_to_player() < e.distance_to_core():
        state_machine.transition_to(&"Attack")
        return

    _nav_timer -= delta
    if _nav_timer <= 0.0:
        _nav_timer = NAV_UPDATE_INTERVAL
        _update_target()
    _move(e)


func _update_target() -> void:
    var target: Vector2 = (enemy as EnemyBase).get_core_position()
    if not _use_direct_steering and is_instance_valid(_nav_agent):
        _nav_agent.target_position = target


func _move(e: EnemyBase) -> void:
    var direction: Vector2
    var has_path: bool = (not _use_direct_steering
        and is_instance_valid(_nav_agent)
        and _nav_agent.get_current_navigation_path().size() > 1)
    if has_path:
        direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
    else:
        direction = (e.get_core_position() - e.global_position).normalized()
    # No wander angle — pure beeline.
    e.velocity = direction * e.get_effective_speed()
    e.move_and_slide()
```

### Phase 3 — Stonehusk (ENEMY-02)

**Concept:** Damage sponge siege engine. Slow and inevitable. Never retreats. Deals massive damage to Core and player. Weak to Vine Whip / Crystal Lash pull effects that disrupt its advance, but pull distance is halved.

#### 3a. New Files

| File | Purpose |
|---|---|
| `enemies/stonehusk/stonehusk.gd` | `class_name Stonehusk extends EnemyBase` |
| `enemies/stonehusk/stonehusk.tscn` | Scene: CharacterBody2D + Sprite2D + CollisionShape2D + AnimationPlayer + StateMachine(Idle, Scout, Siege, Attack) + DetectionArea + AttackArea + NavigationAgent2D |
| `enemies/stonehusk/states/stonehusk_idle.gd` | Same as Shadowling idle |
| `enemies/stonehusk/states/stonehusk_scout.gd` | Like Shadowling scout but NO retreat check. Slower wander. |
| `enemies/stonehusk/states/stonehusk_siege.gd` | Attacks Core. NO retreat check. |
| `enemies/stonehusk/states/stonehusk_attack.gd` | Attacks player. NO retreat check. Shorter leash (returns to Scout faster). |

#### 3b. Stonehusk Script

```gdscript
class_name Stonehusk
extends EnemyBase


func _ready() -> void:
    super._ready()


func activate() -> void:
    var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
    if fsm != null:
        fsm.transition_to(&"Scout")


# Override: Stonehusk never retreats.
func should_retreat() -> bool:
    return false


# Override: Stonehusk resists pull — halve the pull distance.
func apply_pull(toward: Vector2, duration: float, distance: float) -> void:
    super.apply_pull(toward, duration, distance * 0.5)
```

#### 3c. Stonehusk Stats

| Stat | Value | Notes |
|---|---|---|
| `max_hp` | 120 | Tanky |
| `damage` | 20 | Heavy hitter |
| `move_speed` | 20.0 | Half of Shadowling |
| `detection_radius` | 60.0 | Moderate detection |
| `attack_range` | 18.0 | Slightly less than Shadowling |
| `attack_cooldown` | 1.5 | Slow but devastating |

#### 3d. Stonehusk State Notes

All four states (Idle, Scout, Siege, Attack) are structurally identical to Shadowling's, **except**:
- **No `should_retreat()` calls** in any state — remove those branches entirely.
- **Scout:** Reduce `WANDER_ANGLE_MAX` to `deg_to_rad(5.0)` — Stonehusk marches more directly.
- **Attack:** Reduce `LEASH_MULTIPLIER` to `1.2` — gives up chasing the player sooner and returns to Core siege.
- **All states:** Include stun guard and animation calls.

### Phase 4 — Multi-Enemy WaveSpawner

#### 4a. Enemy Pool Configuration

Replace the single `enemy_scene` export with a data-driven pool:

```gdscript
const ENEMY_SCENES: Dictionary = {
    "shadowling": preload("res://enemies/shadowling/shadowling.tscn"),
    "voidrunner": preload("res://enemies/voidrunner/voidrunner.tscn"),
    "stonehusk": preload("res://enemies/stonehusk/stonehusk.tscn"),
}

# Each entry: { "type": String, "weight": float, "min_day": int }
const ENEMY_POOL: Array[Dictionary] = [
    { "type": "shadowling", "weight": 1.0, "min_day": 1 },
    { "type": "voidrunner", "weight": 0.6, "min_day": 2 },
    { "type": "stonehusk", "weight": 0.3, "min_day": 4 },
]
```

#### 4b. Spawn Selection

In `_spawn_enemy()`, select a random enemy type from the pool (filtered by current day_count) using weighted random:

```gdscript
func _pick_enemy_scene() -> PackedScene:
    var day: int = DayNightCycle.day_count
    var pool: Array[Dictionary] = []
    var total_weight: float = 0.0
    for entry: Dictionary in ENEMY_POOL:
        if day >= entry["min_day"]:
            pool.append(entry)
            total_weight += entry["weight"]
    if pool.is_empty():
        return ENEMY_SCENES["shadowling"]  # fallback
    var roll: float = randf() * total_weight
    var cumulative: float = 0.0
    for entry: Dictionary in pool:
        cumulative += entry["weight"]
        if roll <= cumulative:
            return ENEMY_SCENES[entry["type"]]
    return ENEMY_SCENES[pool.back()["type"]]
```

Replace the line in `_spawn_enemy()`:
```gdscript
# Before:
var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
# After:
var enemy: EnemyBase = _pick_enemy_scene().instantiate() as EnemyBase
```

Keep the existing `@export var enemy_scene` for backward compatibility but deprecate it — if `ENEMY_POOL` is non-empty, use the pool; otherwise fall back to `enemy_scene`.

#### 4c. Wave Composition Logging

Update the `start_wave` print to include the enemy pool info:

```gdscript
var available_types: Array[String] = []
for entry: Dictionary in ENEMY_POOL:
    if day >= entry["min_day"]:
        available_types.append(entry["type"])
print("[WaveSpawner] Wave started. Day: %d, Types: %s, Enemies: %d" % [day, available_types, _current_wave_total])
```

### Phase 5 — Debug Keys

Update `player_controller.gd`:

| Key | Action |
|---|---|
| F5 | Cycle debug spawn type: Shadowling → Voidrunner → Stonehusk. Spawn at mouse position. |

Currently F5 spawns a Shadowling at mouse. Change to cycle through all three types:

```gdscript
var _debug_enemy_index: int = 0
const DEBUG_ENEMY_SCENES: Array[String] = [
    "res://enemies/shadowling/shadowling.tscn",
    "res://enemies/voidrunner/voidrunner.tscn",
    "res://enemies/stonehusk/stonehusk.tscn",
]

# In the F5 handler:
if event.keycode == KEY_F5:
    var scene_path: String = DEBUG_ENEMY_SCENES[_debug_enemy_index]
    var scene: PackedScene = load(scene_path)
    var e: EnemyBase = scene.instantiate() as EnemyBase
    e.global_position = get_global_mouse_position()
    # ... add to YSortLayer, call activate() ...
    _debug_enemy_index = (_debug_enemy_index + 1) % DEBUG_ENEMY_SCENES.size()
    print("[Debug] Spawned %s at mouse" % scene_path.get_file().get_basename())
```

---

## Files to Create

| File | Purpose |
|---|---|
| `enemies/voidrunner/voidrunner.gd` | Voidrunner entity script (extends EnemyBase) |
| `enemies/voidrunner/voidrunner.tscn` | Voidrunner scene (CharacterBody2D + FSM) |
| `enemies/voidrunner/states/voidrunner_idle.gd` | Idle state (waits for night → Rush) |
| `enemies/voidrunner/states/voidrunner_rush.gd` | Rush state (beeline to Core, no wander) |
| `enemies/voidrunner/states/voidrunner_siege.gd` | Siege state (attacks Core, no retreat) |
| `enemies/voidrunner/states/voidrunner_attack.gd` | Attack state (attacks player, short leash) |
| `enemies/stonehusk/stonehusk.gd` | Stonehusk entity script (extends EnemyBase) |
| `enemies/stonehusk/stonehusk.tscn` | Stonehusk scene (CharacterBody2D + FSM) |
| `enemies/stonehusk/states/stonehusk_idle.gd` | Idle state (waits for night → Scout) |
| `enemies/stonehusk/states/stonehusk_scout.gd` | Scout state (tight march, no retreat) |
| `enemies/stonehusk/states/stonehusk_siege.gd` | Siege state (attacks Core, no retreat) |
| `enemies/stonehusk/states/stonehusk_attack.gd` | Attack state (attacks player, short leash, no retreat) |

## Files to Modify

| File | Change |
|---|---|
| `enemies/enemy_base.gd` | Add `play_animation()` helper method |
| `enemies/shadowling/states/shadowling_idle.gd` | Add animation call |
| `enemies/shadowling/states/shadowling_scout.gd` | Add stun guard, player detection → Attack, animation call |
| `enemies/shadowling/states/shadowling_siege.gd` | Add stun guard, attack animation call |
| `enemies/shadowling/states/shadowling_attack.gd` | Add stun guard, animation calls |
| `enemies/shadowling/states/shadowling_retreat.gd` | Add stun guard, animation call |
| `enemies/spawner/wave_spawner.gd` | Add `ENEMY_SCENES`, `ENEMY_POOL`, `_pick_enemy_scene()`; replace single-scene spawn with pool-based selection |
| `player/scripts/player_controller.gd` | Update F5 debug to cycle enemy types |
| `docs/design/PERSON_TASKS.md` | Mark ENEMY-01/02 ✅; update F5 debug key description |
| `docs/design/TASK_BREAKDOWN.md` | ENEMY-01, ENEMY-02 status → Done |

---

## Acceptance Criteria

### Shadowling FSM Improvements
1. Shadowling in Scout state detects the player within `detection_radius` (80 px) and transitions to Attack.
2. All five Shadowling states early-return in `physics_update` when `enemy.is_stunned()` — enemy stands still while stunned.
3. AnimationPlayer plays `idle` in Idle, `walk` in Scout/Attack(moving)/Retreat, `attack` on each Core/player hit.
4. Existing Shadowling behavior (Siege, Attack, Retreat, wave tracking) remains unchanged.

### ENEMY-01 — Voidrunner
5. Voidrunner spawns with 25 HP, 5 DMG, 80 speed, 0.6s attack cooldown.
6. On activation, transitions directly to Rush (skips Scout). Beelines toward Core with no wander offset.
7. When Core is within `attack_range` (16 px), transitions to Siege and attacks.
8. When player is within `detection_radius` (48 px) AND closer than the Core, briefly transitions to Attack; returns to Rush when player escapes.
9. `should_retreat()` always returns `false` — never retreats.
10. Difficulty scaling (HP/DMG/Speed multipliers from DifficultyManager + per-day growth) applies correctly.
11. Slow effects from Rafflesia and Spore Bomb are especially effective — `get_effective_speed()` correctly reduces the Voidrunner's high base speed.

### ENEMY-02 — Stonehusk
12. Stonehusk spawns with 120 HP, 20 DMG, 20 speed, 1.5s attack cooldown.
13. Uses standard Scout → Siege → Attack FSM flow (like Shadowling) but **never retreats**.
14. `should_retreat()` always returns `false`.
15. `apply_pull()` halves the pull distance (overrides `super.apply_pull` with `distance * 0.5`).
16. Scout state uses a tighter wander angle (`5°` vs Shadowling's `15°`) for a more direct march.
17. Attack state uses a shorter leash multiplier (`1.2×` vs `1.5×`) — returns to Core focus sooner.
18. Difficulty scaling applies correctly.

### Multi-Enemy WaveSpawner
19. Day 1: Only Shadowlings spawn.
20. Day 2+: Voidrunners added to the pool (weight 0.6).
21. Day 4+: Stonerusks added to the pool (weight 0.3).
22. Enemy selection uses weighted random — Shadowlings remain the most common.
23. All spawned enemies receive difficulty HP/DMG/speed scaling as before.
24. All spawned enemies call `activate()` and connect `enemy_died` / `tree_exiting` signals correctly.
25. Wave start log prints available enemy types for the current day.

### Debug
26. F5 spawns enemies at mouse, cycling Shadowling → Voidrunner → Stonehusk on each press.
27. Spawned debug enemies are added to YSortLayer and call `activate()`.

---

## Notes & Risks

- **Shared vs duplicated states:** Voidrunner and Stonehusk states are structurally similar to Shadowling's but with key behavioral differences (no retreat, no wander, different leash). **Duplicate the state files** per enemy type rather than trying to parameterize — this keeps each enemy's FSM self-contained and easy to tweak independently. If a shared base emerges later, refactor then.
- **Animation safety:** Not all enemy `.tscn` files may have all animation names (`idle`/`walk`/`attack`). The `play_animation()` helper checks `has_animation()` before calling `play()` to avoid runtime errors. Voidrunner and Stonehusk `.tscn` files should include at minimum a RESET + idle + walk + attack animation library (can be simple scale/position tweens like Shadowling).
- **Weighted spawn balance:** The weights (1.0 / 0.6 / 0.3) are tuning values — expect them to change during playtesting. Keep them as constants in `wave_spawner.gd` for easy adjustment. A future task could move them to a `.tres` resource.
- **Stonehusk pull resistance:** The `distance * 0.5` override is a simple approach. A more robust system would add a `pull_resistance: float` export — but that's over-engineering for two enemy types. Add `TODO: ENEMY-WEAKNESS` if desired.
- **No weakness damage multipliers:** The GDD lists weaknesses per enemy, but no multiplier values. This prompt does NOT implement a damage type / weakness system. Weaknesses are expressed through gameplay (slow counters speed, pull disrupts tanks) rather than damage bonuses. If explicit multipliers are needed later, add a `weakness_tags: Array[StringName]` system on `EnemyBase`.
- **WaveSpawner backward compat:** The `@export var enemy_scene` is kept but becomes a fallback. Existing `.tscn` references to the WaveSpawner node in `meadow_edge.tscn` remain valid. The `ENEMY_POOL` constant takes priority.
- **VFX-03 dependency:** Leave `TODO (VFX-03)` markers wherever placeholder animations are used (scale/position tweens as stand-ins for proper sprite animations).
