# PROMPT — ENEMY-03 Phantom Weaver

**Task ID:** ENEMY-03
**Category:** Enemy AI
**Priority:** High
**Effort:** L (~3–5 days)
**Dependencies:** CORE-06 (Shadowling FSM — done), ENEMY-01/02 (Voidrunner + Stonehusk — done), CORE-07 (WaveSpawner multi-pool — done), DIFF-01 (Difficulty Scaling — done)
**GDD Reference:** §8.1 — *Enemy Archetypes*

| Nama | HP | Kecepatan | Damage | FSM Quirk | Kelemahan | Muncul Hari |
|---|---|---|---|---|---|---|
| Phantom Weaver | 60 | Cepat | 12/hit | Teleport saat HP < 30%, re-Scout ulang | Wijaya Kusuma, cahaya area | Hari 6 |

> **GDD Ambiguity (§8.1):** teleport range, cooldown, animation, and "light AoE weakness" are **not specified**. This prompt locks the values listed in §Design Decisions below. Adjust during playtest if needed.

---

## Goal

Implement the **Phantom Weaver** — a fast, medium-HP harasser that teleports once when its HP drops below 30%, then re-enters Scout to re-engage from a new angle. Mechanically distinct from Voidrunner (which never retreats and skips Scout) and Shadowling (which retreats permanently at low HP). Phantom Weaver does **not** retreat — it **relocates** and keeps fighting.

---

## Scope

### In Scope
1. **Phantom Weaver enemy** — new `enemies/phantom_weaver/` scripts + `.tscn`. FSM: `Idle → Scout → Siege → Attack → Teleport`. No Retreat state.
2. **Teleport state** — triggered exactly once per spawn the first time HP crosses below 30%. After teleport completes, transitions back to Scout.
3. **Teleport visuals** — placeholder: 0.3 s fade-out at origin → reposition → 0.3 s fade-in at destination. Brief invulnerability while teleporting (`is_dead`-style guard, not full immortal).
4. **WaveSpawner integration** — add Phantom Weaver to `ENEMY_POOL` (min_day=6, weight=0.4).
5. **Debug F5 cycle** — extend the existing F5 debug spawn to include Phantom Weaver.
6. **Sprite** — use the existing `enemies/phantom_weaver/phantom_weaver.png` placeholder (already imported).
7. **Save/Load** — no schema change. Enemy types are transient.

### Out of Scope
- Real polished VFX/SFX for teleport (covered later by VFX-03 / AUDIO-04). Use a `Tween` on `modulate.a` + `print` log.
- "Light AoE weakness" damage multiplier — GDD lists the weakness but defines no multiplier. Leave a `TODO: ENEMY-WEAKNESS` stub. Mechanical weakness is expressed implicitly: Wijaya Kusuma's homing night projectile naturally tracks Phantom Weaver across teleports, and AoE weapons (Spore Bomb, Bunga Api) hit it before it can relocate.
- Multiple teleports per life or teleport-on-CD — explicitly **one teleport per spawn**, on the 30 % HP crossover. Keeps the encounter readable.
- ENEMY-04 (Swarm Larva), ENEMY-05 (Devourer).

---

## Design Decisions (Locked Values)

| Parameter | Value | Rationale |
|---|---|---|
| `max_hp` | 60 | Per GDD §8.1 |
| `damage` | 12 | Per GDD §8.1 |
| `move_speed` | 60.0 | "Cepat" — between Shadowling (40) and Voidrunner (80) |
| `detection_radius` | 80.0 | Same as Shadowling |
| `attack_range` | 18.0 | Slightly extended melee |
| `attack_cooldown` | 0.8 | Faster than Shadowling (1.0), slower than Voidrunner (0.6) |
| `teleport_threshold` | 0.3 | HP fraction that triggers teleport (HP < 30 %) |
| `teleport_min_distance` | 96.0 px | Lower bound — must clearly relocate |
| `teleport_max_distance` | 160.0 px | Upper bound — stays in zone, doesn't escape |
| `teleport_fade_duration` | 0.3 s | Out and in (total 0.6 s round-trip) |
| `teleport_min_dist_from_player` | 64.0 px | Picks a destination at least this far from the player |
| `teleport_min_dist_from_core` | 48.0 px | Avoids landing inside the Core hitbox |
| `min_day` (spawn) | 6 | Per GDD §8.1 |
| `pool_weight` | 0.4 | Slightly less common than Voidrunner |

**Single teleport per life:** A bool `_has_teleported` on the Phantom Weaver instance gates the trigger. Once set true, subsequent damage at any HP does not re-teleport. Keeps the mechanic legible.

---

## Existing Architecture Reference

### EnemyBase hooks already in place
- `take_damage(amount)` — single entry point for HP loss. **Override** here to detect the 30 % crossover and request a teleport, **before** calling `super.take_damage`.
- `play_animation(anim_name)` — safe StringName animation playback (no-ops if missing).
- `is_stunned()` — every state must early-return when this is true. Teleport state itself uses its own gate (`_is_teleporting`) instead of stun.
- `should_retreat()` — **override to return `false`**. Phantom Weaver relocates instead of retreating.

### FSM framework
- States are child nodes of `StateMachine`. New `Teleport` state file lives at `enemies/phantom_weaver/states/phantom_weaver_teleport.gd`.
- Transitions: `state_machine.transition_to(&"Teleport")` from `take_damage()` does **not** work directly — `take_damage` runs on the enemy script, not in a state. Solution: set a flag `_pending_teleport = true` in the override, and have **every** state's `physics_update` first-line check `if e._pending_teleport: state_machine.transition_to(&"Teleport"); return`.

### Existing reference enemies
- `enemies/voidrunner/` — single-file FSM template, no retreat. Closest structural sibling.
- `enemies/shadowling/` — full FSM with Scout/Siege/Attack patterns to copy.
- `enemies/phantom_weaver/phantom_weaver.png` — placeholder sprite already imported.

### WaveSpawner pool (`enemies/spawner/wave_spawner.gd`)

Already supports `ENEMY_POOL` weighted-random selection. Just append a new entry:

```gdscript
const ENEMY_SCENES: Dictionary = {
    "shadowling": preload("res://enemies/shadowling/shadowling.tscn"),
    "voidrunner": preload("res://enemies/voidrunner/voidrunner.tscn"),
    "stonehusk": preload("res://enemies/stonehusk/stonehusk.tscn"),
    "phantom_weaver": preload("res://enemies/phantom_weaver/phantom_weaver.tscn"),  # NEW
}

const ENEMY_POOL: Array[Dictionary] = [
    { "type": "shadowling", "weight": 1.0, "min_day": 1 },
    { "type": "voidrunner", "weight": 0.6, "min_day": 2 },
    { "type": "stonehusk", "weight": 0.3, "min_day": 4 },
    { "type": "phantom_weaver", "weight": 0.4, "min_day": 6 },  # NEW
]
```

---

## Implementation Plan

### Phase 1 — Phantom Weaver Script (`enemies/phantom_weaver/phantom_weaver.gd`)

```gdscript
class_name PhantomWeaver
extends EnemyBase

@export var teleport_threshold: float = 0.3
@export var teleport_min_distance: float = 96.0
@export var teleport_max_distance: float = 160.0
@export var teleport_min_dist_from_player: float = 64.0
@export var teleport_min_dist_from_core: float = 48.0

var _has_teleported: bool = false
var _pending_teleport: bool = false
var _is_teleporting: bool = false


func _ready() -> void:
    super._ready()


func activate() -> void:
    var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
    if fsm != null:
        fsm.transition_to(&"Scout")


# Override: Phantom Weaver relocates instead of retreating.
func should_retreat() -> bool:
    return false


# Override: detect 30 % HP crossover; trigger one-time teleport.
func take_damage(amount: int) -> void:
    if is_dead or _is_teleporting:
        # Ignore damage while mid-teleport.
        return
    var hp_before: int = current_hp
    super.take_damage(amount)
    if is_dead:
        return
    if not _has_teleported and hp_before > int(max_hp * teleport_threshold) \
            and current_hp <= int(max_hp * teleport_threshold):
        _has_teleported = true
        _pending_teleport = true


# Picks a teleport destination satisfying all distance constraints.
# Falls back to a random direction if no valid spot is found within MAX_TRIES.
func pick_teleport_destination() -> Vector2:
    const MAX_TRIES: int = 12
    var player_pos: Vector2 = get_player_position()
    var core_pos: Vector2 = get_core_position()
    for _i in MAX_TRIES:
        var angle: float = randf() * TAU
        var dist: float = randf_range(teleport_min_distance, teleport_max_distance)
        var candidate: Vector2 = global_position + Vector2.from_angle(angle) * dist
        if candidate.distance_to(player_pos) < teleport_min_dist_from_player:
            continue
        if candidate.distance_to(core_pos) < teleport_min_dist_from_core:
            continue
        return candidate
    # Fallback — directly opposite the player.
    var away: Vector2 = (global_position - player_pos).normalized()
    if away == Vector2.ZERO:
        away = Vector2.RIGHT
    return global_position + away * teleport_max_distance
```

### Phase 2 — Phantom Weaver Scene (`enemies/phantom_weaver/phantom_weaver.tscn`)

Mirror the structure of `voidrunner.tscn`:
- Root: `CharacterBody2D` with `phantom_weaver.gd` script, `unique_name_in_owner` on inner nodes.
- `%Sprite2D` — texture `res://enemies/phantom_weaver/phantom_weaver.png`, scale `(0.5, 0.5)`, modulate `Color(0.85, 0.7, 1.0, 1)` (purple tint to differentiate).
- `%CollisionShape2D` — CircleShape2D r=8.
- `%AnimationPlayer` — at minimum `RESET`, `idle`, `walk`, `attack` (placeholder scale tweens like Shadowling).
- `%NavigationAgent2D` — default config.
- `StateMachine` (Node) with children: `Idle`, `Scout`, `Siege`, `Attack`, `Teleport` (each pointing at the matching `phantom_weaver_*.gd`).
- `@export` overrides on root: `max_hp=60`, `damage=12`, `move_speed=60.0`, `detection_radius=80.0`, `attack_range=18.0`, `attack_cooldown=0.8`.
- `uid="uid://phantom_weaver_01"`.

### Phase 3 — States (`enemies/phantom_weaver/states/`)

#### 3a. `phantom_weaver_idle.gd`
Identical to `voidrunner_idle.gd` but transitions to `&"Scout"` (not Rush) once `DayNightCycle.is_night()` returns true.

#### 3b. `phantom_weaver_scout.gd`
Copy `shadowling_scout.gd`, then **add** the teleport-pending check at the top of `physics_update` and **remove** the retreat check (Phantom Weaver doesn't retreat):

```gdscript
func physics_update(delta: float) -> void:
    var e: PhantomWeaver = enemy as PhantomWeaver
    if e == null or e.is_stunned():
        return
    if e._pending_teleport:
        state_machine.transition_to(&"Teleport")
        return
    if e.distance_to_player() <= e.detection_radius:
        state_machine.transition_to(&"Attack")
        return
    if e.distance_to_core() <= e.attack_range:
        state_machine.transition_to(&"Siege")
        return
    # ... nav update + move (copy unchanged from shadowling_scout) ...
```

#### 3c. `phantom_weaver_siege.gd`
Copy `shadowling_siege.gd`, **remove** the retreat check, **add** the teleport-pending check at the top of `physics_update`. Keeps the Core attack loop unchanged.

#### 3d. `phantom_weaver_attack.gd`
Copy `shadowling_attack.gd`, **remove** the retreat check, **add** the teleport-pending check at the top, leash transitions back to `&"Scout"` (unchanged from Shadowling).

#### 3e. `phantom_weaver_teleport.gd` — NEW STATE

```gdscript
extends State

const FADE_DURATION: float = 0.3


func enter() -> void:
    var e: PhantomWeaver = enemy as PhantomWeaver
    if e == null:
        return
    e._pending_teleport = false
    e._is_teleporting = true
    e.velocity = Vector2.ZERO
    e.play_animation(&"idle")
    _do_teleport(e)


func physics_update(_delta: float) -> void:
    # Movement frozen during teleport — keep velocity zero.
    var e: PhantomWeaver = enemy as PhantomWeaver
    if e != null:
        e.velocity = Vector2.ZERO
        e.move_and_slide()


func _do_teleport(e: PhantomWeaver) -> void:
    var sprite: Sprite2D = e.get_node_or_null("%Sprite2D") as Sprite2D
    var destination: Vector2 = e.pick_teleport_destination()
    print("[PhantomWeaver] Teleport %s -> %s" % [e.global_position, destination])

    # Fade out.
    if is_instance_valid(sprite):
        var tween_out: Tween = e.create_tween()
        tween_out.tween_property(sprite, "modulate:a", 0.0, FADE_DURATION)
        await tween_out.finished
    if not is_instance_valid(e) or e.is_dead:
        return

    # Reposition.
    e.global_position = destination
    var nav: NavigationAgent2D = e.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
    if is_instance_valid(nav):
        nav.target_position = e.get_core_position()

    # Fade in.
    if is_instance_valid(sprite):
        var tween_in: Tween = e.create_tween()
        tween_in.tween_property(sprite, "modulate:a", 1.0, FADE_DURATION)
        await tween_in.finished
    if not is_instance_valid(e) or e.is_dead:
        return

    e._is_teleporting = false
    state_machine.transition_to(&"Scout")
```

> **Why use `await` here?** State transitions are not on a hot path — the teleport intentionally takes ~0.6 s. While `_is_teleporting` is true, `take_damage` early-returns (incoming attacks miss the Phantom Weaver), and the FSM stays parked in this state with zero velocity. This is safe.

> **TODO (VFX-03):** replace the alpha tween with a real teleport particle/shader effect.

### Phase 4 — WaveSpawner Integration

Modify `enemies/spawner/wave_spawner.gd`:
1. Add `"phantom_weaver": preload("res://enemies/phantom_weaver/phantom_weaver.tscn")` to `ENEMY_SCENES`.
2. Append `{ "type": "phantom_weaver", "weight": 0.4, "min_day": 6 }` to `ENEMY_POOL`.

No further changes — `_pick_enemy_scene()` already filters by `min_day` and rolls weighted random.

### Phase 5 — Debug Cycle (`player/scripts/player_controller.gd`)

Extend `DEBUG_ENEMY_SCENES` to include the new scene path:

```gdscript
const DEBUG_ENEMY_SCENES: Array[String] = [
    "res://enemies/shadowling/shadowling.tscn",
    "res://enemies/voidrunner/voidrunner.tscn",
    "res://enemies/stonehusk/stonehusk.tscn",
    "res://enemies/phantom_weaver/phantom_weaver.tscn",  # NEW
]
```

The existing F5 cycle handler does not need any other change.

### Phase 6 — Documentation

- `docs/design/PERSON_TASKS.md` — F5 row: append "→ Phantom Weaver" to the cycle description.
- `docs/design/TASK_BREAKDOWN.md` — change ENEMY-03 status from `Not Started` to `Done`.

---

## Files to Create

| File | Purpose |
|---|---|
| `enemies/phantom_weaver/phantom_weaver.gd` | Entity script (extends EnemyBase). Owns teleport trigger + destination picker. |
| `enemies/phantom_weaver/phantom_weaver.tscn` | Scene: `CharacterBody2D` + Sprite2D + CollisionShape2D + AnimationPlayer + NavigationAgent2D + StateMachine(Idle, Scout, Siege, Attack, Teleport). |
| `enemies/phantom_weaver/states/phantom_weaver_idle.gd` | Idle → Scout on night. |
| `enemies/phantom_weaver/states/phantom_weaver_scout.gd` | Scout, no retreat, teleport-pending check. |
| `enemies/phantom_weaver/states/phantom_weaver_siege.gd` | Siege, no retreat, teleport-pending check. |
| `enemies/phantom_weaver/states/phantom_weaver_attack.gd` | Attack, no retreat, teleport-pending check, leash → Scout. |
| `enemies/phantom_weaver/states/phantom_weaver_teleport.gd` | Fade-out → reposition → fade-in → return to Scout. |

## Files to Modify

| File | Change |
|---|---|
| `enemies/spawner/wave_spawner.gd` | Add `phantom_weaver` to `ENEMY_SCENES` and `ENEMY_POOL` (weight 0.4, min_day 6). |
| `player/scripts/player_controller.gd` | Append phantom_weaver scene path to `DEBUG_ENEMY_SCENES`. |
| `docs/design/PERSON_TASKS.md` | Update F5 debug row to include Phantom Weaver. |
| `docs/design/TASK_BREAKDOWN.md` | ENEMY-03 status → Done. |

---

## Acceptance Criteria

1. Phantom Weaver instance spawns with **HP 60**, **DMG 12**, **speed 60**, **attack_cooldown 0.8**.
2. On `activate()`, FSM enters `Idle`; once `DayNightCycle.is_night()`, transitions to `Scout`.
3. Scout/Siege/Attack states use the Shadowling-equivalent logic but **never** call `should_retreat()` — `should_retreat()` returns `false`.
4. Each non-Teleport state's `physics_update` early-returns on `is_stunned()` and transitions to `Teleport` when `_pending_teleport` is true.
5. The first time `take_damage()` causes `current_hp` to cross from above to at-or-below `30 %` of `max_hp`, `_pending_teleport` is set to true and `_has_teleported` is set to true.
6. Subsequent HP drops below 30 % do **not** retrigger teleport — exactly one teleport per spawn.
7. Damage taken while `_is_teleporting == true` is fully ignored (the override returns early). The Phantom Weaver cannot die mid-teleport.
8. Teleport state: fades sprite alpha to 0 over 0.3 s, repositions `global_position` to a destination satisfying `pick_teleport_destination()` constraints, retargets `NavigationAgent2D`, fades alpha back to 1 over 0.3 s, then transitions to `Scout`.
9. Teleport destination is between **96** and **160** px from origin, at least **64** px from the player, and at least **48** px from the Core. Falls back to "directly opposite the player at max distance" if no valid candidate is found in 12 random tries.
10. WaveSpawner spawns Phantom Weavers from Day 6 onward at weight 0.4. Day 1–5 do **not** spawn them. Wave start log includes `"phantom_weaver"` in `available_types` from Day 6.
11. F5 debug spawn cycles `Shadowling → Voidrunner → Stonehusk → Phantom Weaver → Shadowling …` and adds the spawn to `YSortLayer`.
12. Difficulty scaling (HP/DMG/speed multipliers from DifficultyManager + per-day growth) applies normally — Phantom Weaver is just another `EnemyBase`.
13. Wijaya Kusuma's night auto-attack projectile correctly retargets the Phantom Weaver after teleport (Wijaya scans `enemies` group every fire — already group-membership-based, no fix needed).

---

## Notes & Risks

- **Single-teleport gating:** intentionally one-shot. Multiple teleports per life would require a cooldown timer plus a re-trigger condition (e.g., on every 25 % HP loss). Out of scope here — keep it readable until playtest demands more.
- **`take_damage` override placement:** the HP-threshold detection must read `current_hp` **before and after** `super.take_damage` to detect the crossover in a single call. A pure post-check (`if current_hp < threshold and not _has_teleported`) would still work, but the explicit crossover form makes the trigger condition unambiguous and defends against edge cases like spawning already-damaged enemies.
- **Teleport invulnerability:** implemented as a `take_damage` early-return when `_is_teleporting`. It does **not** make the enemy invulnerable to instant `die()` calls or mass `queue_free` — only to direct damage. This is fine for the current combat surface.
- **Pull / Stun interaction:** if a `Vine Whip` pull or `Petal Shield` counter-stun lands during the brief 0.6 s teleport window, the damage component is ignored but the pull/stun timers still update. After teleport completes, if `is_stunned()` is true, every state will early-return as expected — no crash, just a stationary phantom that resumes when the stun ends.
- **No retreat / no `Retreat` state node:** Phantom Weaver scene must **not** include a `Retreat` child of `StateMachine`. Any `transition_to(&"Retreat")` call from a copy-pasted state file is a bug — review each pasted state.
- **Animation safety:** `play_animation()` already guards on `has_animation()`. If the placeholder `phantom_weaver.tscn` lacks `attack`, only the `play()` call is skipped; the damage application still fires. Add a `TODO (VFX-03)` near the placeholder animations.
- **Teleport destination clamping:** the random angle picker can occasionally choose a tile outside the playable zone. Acceptable for placeholder behavior — enemies clip to navmesh on the next physics frame. If gameplay requires strict zone clamping, post-process the destination through the active zone's bounds (deferred to WORLD-04 cleanup).
- **`TODO: ENEMY-WEAKNESS` stub:** add a comment in `phantom_weaver.gd` documenting the GDD-listed weaknesses (Wijaya Kusuma + light AoE) for the future weakness-multiplier system.
- **No save schema bump:** confirmed — Phantom Weaver state (`_has_teleported`, `_pending_teleport`, `_is_teleporting`) is purely runtime. Enemies are not persisted across save/load.
- **VFX-03 follow-up:** the alpha-tween fade is a placeholder. Real implementation will likely use a particle burst plus a brief shader-driven dissolve. Mark the tween blocks with `TODO (VFX-03)` for easy grep later.
