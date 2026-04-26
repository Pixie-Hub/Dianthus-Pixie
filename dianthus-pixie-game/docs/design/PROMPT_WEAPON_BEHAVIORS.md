# PROMPT — PLANT-09 / PLANT-10 / PLANT-11: Weapon Behaviors (Spore Bomb · Vine Whip · Petal Shield)

**Task IDs:** PLANT-09, PLANT-10, PLANT-11
**Category:** Combat
**Priority:** High
**Effort:** M (1–3 days each, ~M total when bundled)
**Dependencies:** PLANT-06 (Crafting — done), PLANT-08 (Loadout — done), PLANT-07 (Energy — done), CORE-05 (Thorn Sword — done), CORE-06 (Shadowling — done)
**GDD Reference:** §14 — *Senjata*
- *Thorn Sword — Melee — Serangan jarak dekat, swing arc 90 derajat*
- **Spore Bomb — Ranged / AoE — Lempar bom area, delay 1 detik, slow + damage**
- **Vine Whip — Melee Mid-range — Jangkauan 2.5 tile, bisa pull enemy**
- **Petal Shield — Defensive — Block damage 80%, counter-attack jika timing tepat**
**GDD Reference:** §7.3 — Weapon upgrade paths (Spore Bomb → Void Grenade, Vine Whip → Crystal Lash, Petal Shield → Iron Bloom Shield)

---

## Goal

Replace the placeholder Thorn-Sword-only attack with **per-weapon behavior dispatch**. Each of the three new weapons has a distinct gameplay verb:

- **Spore Bomb (PLANT-09):** Throw an arcing projectile to a target point that lands after **1 s**, explodes for AoE damage, and applies a **2 s slow** to all enemies in the blast radius. Upgrade `void_grenade` increases damage and AoE radius.
- **Vine Whip (PLANT-10):** Mid-range melee swing (2.5 tiles = **40 px**, 45° arc) that damages and **pulls** the first enemy hit toward the player. Upgrade `crystal_lash` extends range to 3 tiles (48 px) and increases damage.
- **Petal Shield (PLANT-11):** Hold-to-block stance that reduces incoming damage by **80%**, draining stamina-like cost while held. A **perfect-timing block** (block raised within a **0.2 s window** before the hit lands) negates damage entirely and triggers a 360° **counter-attack** burst that damages and stuns all adjacent enemies. Upgrade `iron_bloom_shield` raises perfect-block window to 0.3 s and counter damage.

Each weapon is **selected via the existing loadout slots** (1 / 2 keys from PLANT-08) and **fired via the existing `attack` action** (Space / LMB). Behavior branches on `weapon_id` of the currently selected weapon.

---

## Scope

### In Scope
1. **Weapon behavior dispatcher** in `player_controller.gd` — `_start_attack()` reads `_current_weapon.weapon_id` and dispatches to the matching behavior method.
2. **Spore Bomb projectile** — new `combat/projectiles/spore_bomb_projectile.gd` + `.tscn`, with arcing motion, fuse timer, AoE explosion, slow application.
3. **Vine Whip swing** — extend the existing sword hitbox flow with a pull velocity applied to the first hit enemy.
4. **Petal Shield blocking state** — new `is_blocking`, `_block_raised_time` fields; `take_damage()` integrates 80% reduction + perfect-block detection + counter-attack.
5. **Slow status effect on enemies** — new `EnemyBase.apply_slow(multiplier, duration)` that stacks correctly with Rafflesia's group-based slow (use `min` of all active sources, restore to `1.0` when none).
6. **Stun status effect on enemies** — new `EnemyBase.apply_stun(duration)` that disables the FSM for a short time (used by Petal Shield counter).
7. **Pull effect on enemies** — new `EnemyBase.apply_pull(target_pos, duration, distance)` that lerps the enemy toward the target during a short tween, briefly disabling FSM.
8. **All four upgrade variants** (`blazeblade`, `void_grenade`, `crystal_lash`, `iron_bloom_shield`) reuse the same behavior method as their base, only the `WeaponData` numbers differ.
9. **VFX placeholders** — simple ColorRect / Sprite2D flashes for explosion, pull line, block flash, counter ring (real VFX deferred to VFX-05).
10. **Energy gain** — Spore Bomb explosion, Vine Whip pull-damage, and Petal Shield counter all award `ENERGY_PER_HIT` per enemy struck (consistent with Thorn Sword).
11. **Animations** — reuse existing `attack` AnimationTree state for Vine Whip and Spore Bomb throw windup; Petal Shield uses a new `block` flag (animation-state work deferred — sprite tint shift is acceptable for now, leave `TODO (VFX-01)`).

### Out of Scope
- Real polished VFX/SFX (covered by VFX-05 / AUDIO-04). Use placeholder shapes/colors and `print` for logs.
- Active-skill versions of these weapons (PLANT-08 placeholder skill stays as-is — this task is about the **attack** action).
- Network-synced or replay-deterministic timing.
- Aim cursor / mouse-targeting UI for Spore Bomb beyond the current mouse position read.
- New crafting recipes (already exist via PLANT-06).

---

## Existing Architecture Reference

### Player Controller — `player/scripts/player_controller.gd`

- `_current_weapon: WeaponData` is set by `select_weapon_slot()` from `weapon_slots[selected_weapon_slot]`.
- `_start_attack()` is currently **hard-coded for melee sword behavior** (positions `_sword_hitbox`, awaits cooldown ticks). It must become a dispatcher.
- Existing constants: `ENERGY_PER_HIT = 3`, `ENERGY_PER_KILL = 10`, `TILE_SIZE = 16`.
- `attack_speed_bonus` (from Kecombrang) and `bonus_melee_damage` (from Kunyit) already wrap the sword damage/cooldown — keep these honored for Vine Whip (melee) and Petal Shield counter; Spore Bomb is ranged so attack-speed bonus applies to cooldown only, **not** to projectile damage (Kunyit melee bonus does NOT apply).
- `take_damage(amount)` already applies `damage_reduction`. Petal Shield will **temporarily raise** `damage_reduction` while blocking, plus a perfect-block branch.
- `_on_sword_hitbox_body_entered()` handles per-hit damage + energy gain — Vine Whip reuses this, with an extra `apply_pull` call on the body.

### WeaponData (`combat/weapons/weapon_data.gd`)

```gdscript
class_name WeaponData
extends Resource
@export var weapon_id: String = ""
@export var weapon_name: String = ""
@export var damage: int = 0
@export var cooldown: float = 0.5
@export var attack_range: float = 24.0
@export var arc_degrees: float = 90.0
```

**No schema change required** — existing `attack_range` is reused as AoE radius for Spore Bomb, pull range for Vine Whip, and counter radius for Petal Shield.

### Existing `.tres` Files (PLANT-06)

| File | weapon_id | damage | cooldown | range | arc |
|---|---|---|---|---|---|
| `combat/weapons/thorn_sword/thorn_sword_data.tres` | thorn_sword | 10 | 0.5 | 24 | 90 |
| `combat/weapons/thorn_sword/blazeblade_data.tres` | blazeblade | 20 | 0.4 | 24 | 90 |
| `combat/weapons/spore_bomb/spore_bomb_data.tres` | spore_bomb | 20 | 2.0 | 80 | 360 |
| `combat/weapons/spore_bomb/void_grenade_data.tres` | void_grenade | 30 | 2.5 | 96 | 360 |
| `combat/weapons/vine_whip/vine_whip_data.tres` | vine_whip | 12 | 0.7 | 40 | 45 |
| `combat/weapons/vine_whip/crystal_lash_data.tres` | crystal_lash | 18 | 0.6 | 48 | 45 |
| `combat/weapons/petal_shield/petal_shield_data.tres` | petal_shield | 5 | 0.3 | 16 | 180 |
| `combat/weapons/petal_shield/iron_bloom_shield_data.tres` | iron_bloom_shield | 8 | 0.3 | 16 | 180 |

For Petal Shield, the **damage** field is the **counter-attack damage**, **cooldown** is the **post-counter cooldown**, **attack_range** is the counter radius (in px). Document these reinterpretations in code comments.

### EnemyBase (`enemies/enemy_base.gd`)

- `speed_modifier: float = 1.0`, `get_effective_speed()` already used by FSM.
- `take_damage(amount)`, `die()` exist.
- Rafflesia uses **group-based slow** (`get_tree().get_nodes_in_group(&"rafflesias")` + `_recalculate_slow`). Our timed slow must coexist with this aura slow — see implementation note below.

### CollisionLayers — `shared/collision_layers.gd`

Layers already defined: PLAYER, ENEMY, INTERACTABLE, etc. The Spore Bomb explosion Area2D should use `collision_mask = ENEMY` only.

### DayNightCycle

- `is_night()` / `is_day()` available — **all three weapons usable during both phases**, no time gate required.

---

## Implementation Plan

### 1. Weapon Behavior Dispatcher

In `player_controller.gd`, replace `_start_attack()` with a dispatcher:

```gdscript
func _start_attack() -> void:
    if _current_weapon == null:
        return
    match _current_weapon.weapon_id:
        "thorn_sword", "blazeblade":
            _attack_melee_sword()  # existing behavior, extracted unchanged
        "vine_whip", "crystal_lash":
            _attack_vine_whip()
        "spore_bomb", "void_grenade":
            _attack_spore_bomb()
        "petal_shield", "iron_bloom_shield":
            _attack_petal_shield()  # toggles block stance
        _:
            push_warning("[Player] Unknown weapon_id: %s" % _current_weapon.weapon_id)
```

Keep `_end_attack()` and `_on_sword_hitbox_body_entered()` shared. Each branch sets up its own hitbox parameters before awaiting the existing animation-frame cadence.

### 2. PLANT-10 — Vine Whip

**Behavior:**
- 45° arc (narrower than Thorn Sword's 90°) at 40 px range.
- Reuse the `_sword_hitbox` Area2D, but **resize the CollisionShape2D** to a longer/narrower rectangle (16 wide × 40 tall toward `last_direction`). Restore default size in `_end_attack()`.
- On first enemy hit (`_on_sword_hitbox_body_entered`), in addition to damage, call `body.apply_pull(global_position, 0.25, 24.0)` — pulls the enemy 24 px toward the player over 0.25 s.
- Honor `bonus_melee_damage` (Kunyit) and `attack_speed_bonus` (Kecombrang) — same as sword.

**Add to `EnemyBase`:**

```gdscript
var _pull_tween: Tween = null

func apply_pull(toward: Vector2, duration: float, distance: float) -> void:
    if is_dead:
        return
    var dir: Vector2 = (toward - global_position).normalized()
    var target: Vector2 = global_position + dir * distance
    if is_instance_valid(_pull_tween):
        _pull_tween.kill()
    _pull_tween = create_tween()
    _pull_tween.tween_property(self, "global_position", target, duration)
    # Briefly disable FSM physics so the pull is uninterrupted.
    var fsm: Node = get_node_or_null("StateMachine")
    if fsm != null:
        fsm.set_physics_process(false)
        await get_tree().create_timer(duration).timeout
        if is_instance_valid(self) and not is_dead:
            fsm.set_physics_process(true)
```

**Placeholder VFX:** draw a green Line2D from player to pulled enemy for 0.15 s (use `Line2D` node added under player, or a scripted `_draw()` on a helper Node2D). Acceptable to skip and leave `TODO (VFX-05)` if too noisy.

### 3. PLANT-09 — Spore Bomb

**New files:**
- `combat/projectiles/spore_bomb_projectile.gd` (Area2D)
- `combat/projectiles/spore_bomb_projectile.tscn`

**Projectile script:**

```gdscript
class_name SporeBombProjectile
extends Area2D

@export var fuse_time: float = 1.0
@export var damage: int = 20
@export var aoe_radius: float = 32.0
@export var slow_multiplier: float = 0.6
@export var slow_duration: float = 2.0
@export var arc_height: float = 24.0

var _start_pos: Vector2
var _target_pos: Vector2
var _t: float = 0.0
@onready var _sprite: Node2D = %Sprite

func launch(from_pos: Vector2, to_pos: Vector2) -> void:
    _start_pos = from_pos
    _target_pos = to_pos
    global_position = from_pos

func _physics_process(delta: float) -> void:
    _t += delta
    var u: float = clamp(_t / fuse_time, 0.0, 1.0)
    var lin: Vector2 = _start_pos.lerp(_target_pos, u)
    # Parabolic arc (offset Y by sin curve).
    lin.y -= sin(u * PI) * arc_height
    global_position = lin
    if _t >= fuse_time:
        _explode()

func _explode() -> void:
    set_physics_process(false)
    # Damage + slow all enemies within aoe_radius.
    for body in get_tree().get_nodes_in_group(&"enemies"):
        if body is EnemyBase and not body.is_dead:
            if global_position.distance_to(body.global_position) <= aoe_radius:
                body.take_damage(damage)
                if body.has_method("apply_timed_slow"):
                    body.apply_timed_slow(slow_multiplier, slow_duration)
                if is_instance_valid(GameManager.player):
                    GameManager.player.add_energy(GameManager.player.ENERGY_PER_HIT)
    # Placeholder VFX: spawn an expanding ColorRect ring.
    _spawn_explosion_vfx()
    await get_tree().create_timer(0.4).timeout
    queue_free()
```

**Player launch logic (`_attack_spore_bomb`):**

```gdscript
func _attack_spore_bomb() -> void:
    is_attacking = true
    _state_machine.travel("attack")
    var target: Vector2 = get_global_mouse_position()
    # Clamp throw distance to weapon attack_range (e.g., 80 px).
    var dir: Vector2 = (target - global_position)
    if dir.length() > _current_weapon.attack_range:
        target = global_position + dir.normalized() * _current_weapon.attack_range
    var proj: SporeBombProjectile = preload(
        "res://combat/projectiles/spore_bomb_projectile.tscn").instantiate()
    proj.damage = _current_weapon.damage
    proj.aoe_radius = _current_weapon.attack_range * 0.4  # tune ratio
    proj.launch(global_position, target)
    var parent: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
    if parent == null:
        parent = get_tree().current_scene
    parent.add_child(proj)
    # Brief windup, then end attack so player can move again.
    await get_tree().create_timer(0.2).timeout
    is_attacking = false
    _attack_cooldown_timer = _current_weapon.cooldown * (1.0 - attack_speed_bonus)
    _state_machine.travel("idle")
```

**Variant tuning:** `void_grenade` has `damage = 30, attack_range = 96` so `aoe_radius = 38.4` automatically.

### 4. PLANT-11 — Petal Shield

**Behavior:** The `attack` action **toggles** a block stance.

**Player additions:**

```gdscript
const PETAL_SHIELD_DR: float = 0.8
const PETAL_SHIELD_PERFECT_WINDOW: float = 0.2  # iron_bloom_shield: 0.3
const PETAL_SHIELD_COUNTER_STUN: float = 0.6

var is_blocking: bool = false
var _block_raised_time: float = -1.0
var _saved_damage_reduction: float = 0.0

func _attack_petal_shield() -> void:
    if is_blocking:
        _drop_block()
    else:
        _raise_block()

func _raise_block() -> void:
    is_blocking = true
    _block_raised_time = Time.get_ticks_msec() / 1000.0
    _saved_damage_reduction = damage_reduction
    damage_reduction = max(damage_reduction, PETAL_SHIELD_DR)
    _sprite.modulate = Color(0.8, 0.9, 1.0)  # placeholder VFX
    print("[Player] Block raised (%s)" % _current_weapon.weapon_id)

func _drop_block() -> void:
    is_blocking = false
    _block_raised_time = -1.0
    damage_reduction = _saved_damage_reduction
    _sprite.modulate = Color.WHITE
    print("[Player] Block dropped")
```

**`take_damage` override:**

```gdscript
func take_damage(amount: int) -> void:
    if is_dead or is_invincible:
        return
    if is_blocking:
        var window: float = PETAL_SHIELD_PERFECT_WINDOW
        if _current_weapon != null and _current_weapon.weapon_id == "iron_bloom_shield":
            window = 0.3
        var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _block_raised_time
        if elapsed <= window:
            print("[Player] Perfect block! Counter-attack.")
            _trigger_petal_counter()
            return  # full negate
    var reduced: int = int(float(amount) * (1.0 - damage_reduction))
    reduced = max(reduced, 1)
    current_hp = max(current_hp - reduced, 0)
    hp_changed.emit(current_hp, MAX_HP)
    # ... existing flash + die code unchanged ...
```

**Counter-attack:**

```gdscript
func _trigger_petal_counter() -> void:
    var radius: float = _current_weapon.attack_range
    var dmg: int = _current_weapon.damage
    for body in get_tree().get_nodes_in_group(&"enemies"):
        if body is EnemyBase and not body.is_dead:
            if global_position.distance_to(body.global_position) <= radius:
                body.take_damage(dmg)
                if body.has_method("apply_stun"):
                    body.apply_stun(PETAL_SHIELD_COUNTER_STUN)
                add_energy(ENERGY_PER_HIT)
    # Placeholder VFX: spawn a brief expanding ColorRect ring.
    _spawn_counter_vfx(radius)
```

**Drop block when player moves / takes a non-perfect hit:** Auto-drop block on movement input is **out of scope** — the player must press attack again to drop. Document this so playtesters know.

**Loadout-switch & death cleanup:** in `select_weapon_slot()` and `_die()`, if `is_blocking`, call `_drop_block()` to restore `damage_reduction`.

### 5. EnemyBase Status Effects

Add to `enemies/enemy_base.gd`:

```gdscript
var _timed_slow_until: float = 0.0
var _timed_slow_value: float = 1.0
var _stun_until: float = 0.0

func apply_timed_slow(multiplier: float, duration: float) -> void:
    if is_dead:
        return
    var until: float = (Time.get_ticks_msec() / 1000.0) + duration
    # Take the strongest of the new and current timed slows.
    if multiplier < _timed_slow_value or until > _timed_slow_until:
        _timed_slow_value = min(_timed_slow_value, multiplier)
        _timed_slow_until = max(_timed_slow_until, until)

func apply_stun(duration: float) -> void:
    if is_dead:
        return
    _stun_until = max(_stun_until, (Time.get_ticks_msec() / 1000.0) + duration)

func is_stunned() -> bool:
    return (Time.get_ticks_msec() / 1000.0) < _stun_until
```

**Slow integration:** `get_effective_speed()` becomes:

```gdscript
func get_effective_speed() -> float:
    var now: float = Time.get_ticks_msec() / 1000.0
    var timed: float = _timed_slow_value if now < _timed_slow_until else 1.0
    if now >= _timed_slow_until:
        _timed_slow_value = 1.0  # reset
    return move_speed * speed_modifier * timed
```

This stacks multiplicatively with Rafflesia's `speed_modifier` aura — both can apply simultaneously. Stun is honored by the FSM by checking `enemy.is_stunned()` in each state's `_physics_process` early-return (or simpler: have `EnemyBase._physics_process` zero out velocity if stunned). Recommended: add a base `_physics_process(delta)` on `EnemyBase` that returns `move_and_slide()` with `velocity = Vector2.ZERO` when stunned, and let the FSM run normally otherwise — most existing FSM states already use `get_effective_speed()`.

### 6. Debug Keys

Update `player_controller.gd`:

| Key | Action |
|---|---|
| `Shift+1` | Equip Spore Bomb to slot 1 (`equip_weapon(0, "spore_bomb")`) |
| `Shift+2` | Equip Vine Whip to slot 1 |
| `Shift+3` | Equip Petal Shield to slot 1 |

(Use these inside the existing `event is InputEventKey` block; respect `DayNightCycle.is_night()` lock by calling `equip_weapon`, which already handles it.)

### 7. Acceptance — Save/Load

**No schema bump needed.** Loadout already persists weapon IDs (PLANT-08 schema v7). Verify after load that `_current_weapon` is correctly resolved for non-sword IDs.

---

## Files to Create

| File | Purpose |
|---|---|
| `combat/projectiles/spore_bomb_projectile.gd` | Arcing AoE projectile with fuse + slow |
| `combat/projectiles/spore_bomb_projectile.tscn` | Projectile scene (Area2D + Sprite + CollisionShape2D) |

## Files to Modify

| File | Change |
|---|---|
| `player/scripts/player_controller.gd` | Replace `_start_attack()` with weapon dispatcher; add `_attack_melee_sword`, `_attack_vine_whip`, `_attack_spore_bomb`, `_attack_petal_shield`; add `is_blocking`, `_block_raised_time`, `_saved_damage_reduction`, `_raise_block`, `_drop_block`, `_trigger_petal_counter`, `_spawn_counter_vfx`; override `take_damage` for perfect-block; debug Shift+1/2/3 |
| `enemies/enemy_base.gd` | Add `apply_timed_slow`, `apply_stun`, `apply_pull`, `is_stunned`; update `get_effective_speed`; honor stun in `_physics_process` |
| `docs/design/PERSON_TASKS.md` | Mark PLANT-09/10/11 ✅; add Shift+1/2/3 debug rows |
| `docs/design/TASK_BREAKDOWN.md` | PLANT-09, PLANT-10, PLANT-11 status → Done |

---

## Acceptance Criteria

### PLANT-09 — Spore Bomb
1. Selecting `spore_bomb` and pressing attack throws an arcing projectile from the player toward the mouse cursor (clamped to `attack_range = 80 px`).
2. After **1 s fuse**, the projectile detonates: all enemies within the AoE radius (≈32 px for Spore Bomb, ≈38 px for Void Grenade) take `damage` and receive a **0.6× slow for 2 s**.
3. A placeholder explosion VFX (expanding ring) is visible on detonation.
4. Cooldown (2.0 s base, 2.5 s for Void Grenade) honored; `attack_speed_bonus` reduces it.
5. Energy gain (+3) is awarded per enemy struck by the explosion.
6. Player regains control immediately after the 0.2 s windup (does not lock for the full fuse).

### PLANT-10 — Vine Whip
1. Selecting `vine_whip` and pressing attack swings a 45° arc at 40 px range (48 px for `crystal_lash`).
2. The first enemy hit is **pulled 24 px toward the player over 0.25 s**, with FSM physics paused during the pull.
3. Damage = `WeaponData.damage + bonus_melee_damage` (Kunyit honored).
4. Cooldown honors `attack_speed_bonus` (Kecombrang).
5. Energy gain (+3) per enemy struck (existing sword logic).

### PLANT-11 — Petal Shield
1. Pressing attack with `petal_shield` selected **toggles** a block stance (raise/drop).
2. While blocking, incoming damage is reduced by 80% (`damage_reduction` clamped to ≥0.8).
3. Receiving damage **within 0.2 s of raising** the block (0.3 s for `iron_bloom_shield`) **fully negates** the hit and triggers a 360° counter-attack: all enemies within `attack_range` (16 px) take `weapon.damage` and are stunned for 0.6 s.
4. Block stance persists until the player presses attack again, dies, or switches weapon slot.
5. On block drop, `damage_reduction` is restored to its pre-block value (preserving Baja Kuning's 30% if applicable).
6. Placeholder counter VFX (expanding ring) plays on perfect-block trigger.
7. Energy gain (+3) per enemy hit by the counter.

### Cross-cutting
8. Switching weapon slots (`1`/`2`) while blocking automatically drops the block.
9. Dying while blocking restores `damage_reduction` correctly on respawn.
10. Slow effects from Spore Bomb and Rafflesia stack correctly: an enemy in both ends up at the lower of the two `speed_modifier × timed_slow` values, and recovers properly when both expire.
11. Stunned enemies stop moving and attacking until stun expires.
12. All four upgrade variants (`blazeblade`, `void_grenade`, `crystal_lash`, `iron_bloom_shield`) share the same dispatcher branch as their base and only differ via `WeaponData` numbers.
13. `Shift+1` / `Shift+2` / `Shift+3` debug-equip Spore Bomb / Vine Whip / Petal Shield to slot 1, blocked at night per existing loadout lock.

---

## Notes & Risks

- **Block-stance UX:** A toggle (rather than hold-LMB) is recommended because the existing `attack` action is single-press. If a hold-block feel is desired later, switch to `Input.is_action_pressed("attack")` polling in `_physics_process` — but this conflicts with how the other three weapons fire on `just_pressed`. Toggle is the cleaner first pass.
- **Spore Bomb projectile parent:** Add to `YSortLayer` so it renders in correct depth order with player/enemies (per the existing Y-sort architecture).
- **Pull + FSM race condition:** If an enemy is pulled into a wall, `move_and_slide` will not be called during the pull (we tween `global_position` directly). Acceptable for placeholder feel; revisit if collisions feel broken.
- **Perfect-block detection:** Uses `Time.get_ticks_msec()` to avoid frame-rate dependency. Document the window in code comments.
- **WeaponData reinterpretation for Petal Shield:** Add a header comment in `petal_shield_data.tres` and `iron_bloom_shield_data.tres` explaining: `damage` = counter damage, `attack_range` = counter radius, `cooldown` = post-counter cooldown.
- **VFX-05 dependency:** `docs/design/TASK_BREAKDOWN.md` lists VFX-05 as a downstream polish task — leave `TODO (VFX-05)` markers wherever placeholders are used.
