# CORE-06 — Shadowling Enemy FSM — Implementation Prompt

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** L (3–7 days)
**Priority:** Critical
**Dependencies:** FOUND-03 (Player Controller — Done)
**Downstream dependents:** CORE-07 (Wave Spawner), ENEMY-01/02/03/04 (all other enemy FSMs reuse this base), VFX-03 (Enemy Animations)

---

## 1. Objective

Implement the **Shadowling** — the first and most standard enemy in the game — as a `CharacterBody2D` with a **reusable finite state machine** architecture. The Shadowling is the template enemy; all 5 other enemy types (Voidrunner, Stonehusk, Phantom Weaver, Swarm Larva, Devourer) will later derive from or follow the same FSM pattern established here. This task must produce:

1. A **generic, reusable FSM framework** under `enemies/fsm/` that any enemy can use.
2. A **base enemy class** (`EnemyBase`) with shared logic (HP, damage, signals, collision, death).
3. The **Shadowling** entity with its own stats resource and 5 FSM states.
4. A **Shadowling scene** (`.tscn`) ready to be instantiated by the future Wave Spawner (CORE-07).
5. A **debug key** to manually spawn a Shadowling for testing.

---

## 2. Shadowling Stats (GDD §8.1)

| Stat | Value |
|------|-------|
| HP | 40 |
| Damage per hit | 8 |
| Move speed (Scout) | ~2.5 tiles/sec (40 px/s) |
| Move speed (Siege/Attack) | ~3 tiles/sec (48 px/s) |
| Detection radius (player) | 80 px (5 tiles) |
| Attack range | 20 px (~1.25 tiles) |
| Attack cooldown | 1.0 s |
| Ally proximity radius | 96 px (6 tiles) — **design decision** (GDD §15 does not specify) |
| Retreat HP threshold | < 20% HP (i.e. < 8 HP) |
| Retreat ally threshold | < 2 allies within proximity radius |

---

## 3. FSM Architecture

### 3a. Reusable FSM Framework (`enemies/fsm/`)

Create a lightweight, script-based state machine. **Do NOT use AnimationTree for FSM logic** — keep it code-driven.

**Files to create:**

- `enemies/fsm/state_machine.gd` — The FSM controller. Attached as a child node of the enemy.
  - Holds a `Dictionary` of state name → `State` node references.
  - Has `current_state: State`, calls `enter()`, `exit()`, `update(delta)`, `physics_update(delta)` on the active state.
  - `transition_to(state_name: StringName)` method handles exit → enter flow.
  - Initializes to a configurable `initial_state` export.

- `enemies/fsm/state.gd` — Abstract base class for all states.
  - `extends Node`
  - Properties: `enemy: CharacterBody2D` (set by StateMachine on ready), `state_machine: StateMachine`.
  - Virtual methods: `enter() -> void`, `exit() -> void`, `update(delta: float) -> void`, `physics_update(delta: float) -> void`.

### 3b. Base Enemy Class (`enemies/enemy_base.gd`)

`extends CharacterBody2D`, `class_name EnemyBase`

**Responsibilities:**
- Exports: `max_hp`, `damage`, `move_speed`, `detection_radius`, `attack_range`, `attack_cooldown`, `ally_proximity_radius`.
- Variables: `current_hp`, `is_dead`.
- Signals: `hp_changed(current_hp, max_hp)`, `enemy_died(enemy)`, `damage_dealt(target, amount)`.
- `take_damage(amount: int)` — Reduce HP, flash sprite red (same pattern as player/core), emit `hp_changed`. If HP <= 0, call `die()`.
- `die()` — Set `is_dead = true`, emit `enemy_died`, play death anim, then `queue_free()` after anim completes. Award `+10 energy` stub comment for PLANT-07.
- `get_core_position() -> Vector2` — Returns `GameManager.dianthus_core.global_position`.
- `get_player_position() -> Vector2` — Returns `GameManager.player.global_position`.
- `distance_to_player() -> float` — Distance from self to player.
- `distance_to_core() -> float` — Distance from self to core.
- `count_nearby_allies(radius: float) -> int` — Count other `EnemyBase` nodes in the `"enemies"` group within radius. Use `get_tree().get_nodes_in_group("enemies")` and distance check.
- `should_retreat() -> bool` — Returns `true` if `current_hp < max_hp * 0.2` **OR** `count_nearby_allies(ally_proximity_radius) < 2`.
- On `_ready()`: add self to group `"enemies"`.
- On death / `queue_free()`: the node naturally leaves the group.

**Collision setup:**
- `collision_layer = 8` (enemy layer, per `project.godot` layer 4)
- `collision_mask = 6` (terrain + player, i.e. layers 2 + 3)
- Match the existing `CollisionLayers` constants: `ENEMY = 8`, `MASK_ENEMY = TERRAIN | PLAYER`.

**Scene tree structure for Shadowling (and all enemies):**
```
Shadowling (CharacterBody2D) [enemy_base.gd or shadowling.gd]
├── Sprite2D (%Sprite2D)
├── CollisionShape2D (CapsuleShape2D, ~8×12 px for 32×48 character)
├── AnimationPlayer (%AnimationPlayer)
├── StateMachine (Node) [state_machine.gd]
│   ├── Idle (Node) [shadowling_idle.gd]
│   ├── Scout (Node) [shadowling_scout.gd]
│   ├── Siege (Node) [shadowling_siege.gd]
│   ├── Attack (Node) [shadowling_attack.gd]
│   └── Retreat (Node) [shadowling_retreat.gd]
├── DetectionArea (Area2D) — circle shape, radius = detection_radius
├── AttackArea (Area2D) — circle shape, radius = attack_range
├── NavigationAgent2D (%NavigationAgent2D) — for pathfinding toward Core/Player
└── HitFlashTimer (Timer) — optional, for damage flash duration
```

---

## 4. FSM States — Detailed Behaviour

### 4a. Idle (`enemies/shadowling/states/shadowling_idle.gd`)

- **Enter:** Enemy has just spawned. Play idle animation. Face a random cardinal direction.
- **Behaviour:** Do nothing. Wait for activation.
- **Transition → Scout:** Immediate on `enter()` if `DayNightCycle.is_night()` is true. Otherwise, connect to `DayNightCycle.phase_changed` and transition when Night begins. Also transition if an external `activate()` method is called (for Wave Spawner use in CORE-07).

### 4b. Scout (`enemies/shadowling/states/shadowling_scout.gd`)

- **Enter:** Start moving toward the Dianthus Core.
- **Behaviour:**
  - Set `NavigationAgent2D.target_position` to `get_core_position()`. Update target every ~0.5 s (not every frame, for performance).
  - Move at `move_speed` (40 px/s) along the navigation path.
  - Apply slight random wander offset (±15° from direct path) to avoid all enemies stacking on the exact same line.
  - Play walk animation.
- **Transitions:**
  - **→ Attack:** `distance_to_player() <= detection_radius` (80 px).
  - **→ Siege:** `distance_to_core() <= attack_range` (20 px).
  - **→ Retreat:** `should_retreat()` returns true.
- Check transitions in `physics_update(delta)`.

### 4c. Siege (`enemies/shadowling/states/shadowling_siege.gd`)

- **Enter:** Enemy is within attack range of the Dianthus Core. Start attack timer.
- **Behaviour:**
  - Face toward Core. Play attack animation on each hit.
  - Every `attack_cooldown` (1.0 s), call `GameManager.dianthus_core.take_damage(enemy.damage)`.
  - If Core moves out of range (unlikely, it's static), transition back to Scout.
- **Transitions:**
  - **→ Attack:** `distance_to_player() <= detection_radius` (player enters proximity while sieging).
  - **→ Retreat:** `should_retreat()` returns true.

### 4d. Attack (`enemies/shadowling/states/shadowling_attack.gd`)

- **Enter:** Player detected. Switch target to player.
- **Behaviour:**
  - Chase `get_player_position()` using NavigationAgent2D. Update target every ~0.3 s.
  - Move at siege/attack speed (48 px/s).
  - When within `attack_range` (20 px), stop and deal `enemy.damage` (8) to player on `attack_cooldown` (1.0 s). Call `GameManager.player.take_damage(enemy.damage)`.
  - Play walk animation while chasing, attack animation when striking.
- **Transitions:**
  - **→ Scout:** Player moves beyond `detection_radius * 1.5` (120 px) — leash/disengage, resume Core assault.
  - **→ Retreat:** `should_retreat()` returns true.

### 4e. Retreat (`enemies/shadowling/states/shadowling_retreat.gd`)

- **Enter:** HP dropped below 20% or too few allies nearby.
- **Behaviour:**
  - Calculate flee direction: `(global_position - get_core_position()).normalized()`.
  - Move in flee direction at `move_speed * 1.5` (60 px/s).
  - Play walk animation (could be tinted or sped up to visually distinguish retreat).
  - After **5 seconds** or if position is far enough from Core (> 300 px), call `enemy.queue_free()` to despawn.
- **Transitions:** None — this is a terminal state ending in despawn.

---

## 5. Existing Codebase Context

You must integrate with these existing systems. **Do NOT modify them unless absolutely necessary.**

### Autoloads (already registered in `project.godot`):
- **`GameManager`** (`shared/autoloads/game_manager.gd`) — Access `GameManager.dianthus_core`, `GameManager.player`, `GameManager.current_state`, `GameManager.set_state()`. Signals: `game_state_changed`, `core_hp_changed`, `player_died`, etc.
- **`DayNightCycle`** (`core/day_night/day_night_cycle.gd`) — Access `DayNightCycle.is_night()`, `DayNightCycle.current_phase`, signal `phase_changed(phase: String)`.
- **`SceneTransition`** (`core/transitions/scene_transition.gd`).

### Collision Layers (from `project.godot`):
- Layer 1: interactable
- Layer 2: terrain
- Layer 3: player
- Layer 4: enemy
- Layer 5: projectile

Constant reference in `shared/collision_layers.gd`:
- `ENEMY = 8` (layer 4)
- `MASK_ENEMY = TERRAIN | PLAYER` = `6` (layers 2+3)

### Player (`player/scripts/player_controller.gd`):
- `extends CharacterBody2D`
- Has `take_damage(amount: int)` — already handles invincibility check, HP reduction, death.
- Has `is_dead`, `is_invincible` flags.
- `TILE_SIZE = 16`, `SPEED = 80.0` (5 tiles/sec).
- Registered via `GameManager.register_player(self)`.

### Dianthus Core (`core/dianthus_core/dianthus_core.gd`):
- `extends StaticBody2D`
- Has `take_damage(amount: int)` — reduces HP, emits signals, triggers `core_destroyed` at 0 HP.
- `MAX_HP = 200`.
- Registered via `GameManager.register_core(self)`.
- `DamageArea` (Area2D) already detects enemy layer (mask = 8) — currently only prints. You may use this or let the Shadowling call `take_damage()` directly.

### WeaponData (`combat/weapons/weapon_data.gd`):
- `class_name WeaponData extends Resource`
- Fields: `weapon_name`, `damage`, `cooldown`, `attack_range`, `arc_degrees`.

### Player attack hitbox:
- `SwordHitbox` (Area2D) on player calls `body.take_damage(damage)` if body has the method. This means `EnemyBase.take_damage()` will be called automatically when the player hits an enemy — no extra wiring needed.

---

## 6. File Structure to Create

```
enemies/
├── enemy_base.gd              # Base class for all enemies
├── enemy_base.gd.uid
├── fsm/
│   ├── state_machine.gd       # Reusable FSM controller
│   ├── state_machine.gd.uid
│   ├── state.gd               # Abstract base state
│   └── state.gd.uid
└── shadowling/
    ├── shadowling.gd           # Shadowling-specific overrides (if any), or just use enemy_base.gd
    ├── shadowling.gd.uid
    ├── shadowling.tscn         # Scene file
    └── states/
        ├── shadowling_idle.gd
        ├── shadowling_scout.gd
        ├── shadowling_siege.gd
        ├── shadowling_attack.gd
        └── shadowling_retreat.gd
```

---

## 7. Placeholder Visuals

No Shadowling sprite art exists yet. Use a **placeholder**:
- A `Sprite2D` using `res://icon.svg` scaled down (`scale = Vector2(0.2, 0.2)`), tinted dark purple (`modulate = Color(0.4, 0.2, 0.6)`).
- Or create a simple `ColorRect` (16×16 dark purple square) as a child.
- The sprite just needs to be visible and distinguishable from the player and Core.

For **animations**, use simple tweens or a minimal `AnimationPlayer` with:
- `idle` — subtle bob/pulse (scale oscillation).
- `walk` — same bob but faster.
- `attack` — quick lunge forward (position offset + return).
- `death` — fade out (`modulate.a` → 0 over 0.5 s), then `queue_free()`.

---

## 8. Debug / Testing Integration

Add a debug spawn key for testing (consistent with existing debug keys F1–F4):

- **F5** — Spawn a Shadowling at the mouse cursor position (or 100px to the right of the player). Immediately activate it (transition to Scout).
- **F6** — Kill all Shadowlings (call `get_tree().call_group("enemies", "die")`).

Add this to `player_controller.gd` in `_unhandled_input()` alongside the existing F3/F4 debug keys, OR create a small debug autoload. Prefer adding to `player_controller.gd` for consistency.

---

## 9. Acceptance Criteria

1. **Stats correct:** Shadowling has 40 HP, deals 8 DMG per hit.
2. **FSM complete:** All 5 states (Idle, Scout, Siege, Attack, Retreat) implemented with correct transitions.
3. **Takes damage from player:** Player's Thorn Sword hitbox (`SwordHitbox`) triggers `take_damage()` on Shadowling. Shadowling flashes red on hit.
4. **Deals damage to Core:** In Siege state, Shadowling calls `take_damage(8)` on the Core every 1.0 s. Core HP bar updates.
5. **Deals damage to Player:** In Attack state, Shadowling calls `take_damage(8)` on the player every 1.0 s.
6. **Retreat works:** Below 20% HP or < 2 allies nearby → flees away from Core and despawns.
7. **Death cleanup:** On death, plays death animation, emits `enemy_died` signal, removes from `"enemies"` group, frees node. No orphan nodes or errors.
8. **Reusable FSM:** The `state_machine.gd` and `state.gd` framework is generic — not Shadowling-specific. Future enemies (ENEMY-01 through ENEMY-04) can create their own state scripts and plug into the same StateMachine node.
9. **No regressions:** Player controller, Core, Day/Night cycle, and HUD all remain functional.
10. **Debug spawn:** F5 spawns a Shadowling, F6 clears all enemies.

---

## 10. Design Decisions (Resolving GDD Ambiguities)

The GDD (§15) does not specify:
- **Ally proximity radius for retreat:** Using **96 px (6 tiles)**. This is wide enough that a small cluster of 3+ enemies won't retreat, but a lone straggler will.
- **Detection radius for player:** Using **80 px (5 tiles)**. Enough to aggro when the player engages nearby but not so large that enemies cross the whole map to chase.
- **Leash distance (disengage from player):** Using **1.5× detection radius = 120 px**. Prevents enemies from chasing infinitely.
- **Retreat duration before despawn:** **5 seconds** or **300 px from Core**, whichever comes first.

If you disagree with any of these values, implement them as exported variables or constants at the top of `enemy_base.gd` so they're easy to tune.

---

## 11. Important Constraints

- **GDScript only** — no C#, no GDExtension.
- **Do NOT use `@onready` for nodes that might not exist** — use `%UniqueNameInOwner` syntax where possible, and null-check otherwise.
- **Do NOT add NavigationRegion2D** — if one doesn't exist in the current zone scene, use direct steering (`move_toward` / `move_and_slide`) instead of NavigationAgent2D. Keep NavigationAgent2D in the scene tree but fall back to direct movement if no navigation map is available.
- **Keep all enemy logic self-contained** — the Shadowling scene should work when instanced into any zone scene.
- **Signals over direct references** — use `GameManager` to access player/core, and signals for communication where possible.
- **Match existing code style** — see `player_controller.gd` and `dianthus_core.gd` for conventions: tabs for indentation, type hints on all parameters and return types, `_` prefix for private methods/vars.
