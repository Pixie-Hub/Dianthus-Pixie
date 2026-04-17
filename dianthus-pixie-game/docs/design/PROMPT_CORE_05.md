# CORE-05 — Thorn Sword Melee Attack

## Context

| Key | Value |
|-----|-------|
| **Project** | Dianthus Pixie — 2D survival crafting action game |
| **Engine** | Godot 4.6 (Forward Plus) |
| **Viewport** | 640x360, stretch `canvas_items`, integer scale |
| **Art** | 16x16 tiles, 64x64 character sprite frames |
| **Repo root** | `c:\Users\Indra\Programming\GIGA\Dianthus Pixie\dianthus-pixie-game` |

## GDD References

- **§14 Combat:** Thorn Sword = Melee, swing arc 90 degrees.
- **§7.3 Crafting:** Thorn Sword = 3x Petal Shard + 2x Thornvine. Upgrade to Blazeblade (+ Emberfern).
- **§9.1 Stats:** Attack Speed 1.0x base. Emberfern +20%, Blazeblade +15%.
- **§13.3 Energy** (stub only, PLANT-07 not done): +3 energy/hit, +10/kill.
- **§12.2 Animation:** Swing VFX, impact particles.
- **§12.3 SFX:** Enemy hit = impact + thorn effect.

---

## Current State — What Already Exists

> **Do NOT recreate these from scratch.** Only modify or extend as needed.

### 1. Player Controller — `player/scripts/player_controller.gd`

- `CharacterBody2D` with HP system (100 HP), death/respawn, invincibility.
- Animation via `AnimationTree` state machine with `BlendSpace2D` per state.
- States: `idle`, `walk`, `run`, `hurt`, `death`. **No attack state yet.**
- `_travel()` blocks transitions from `hurt` and `death`. Must also block during attack.
- `_update_blend_position()` sets blends on all 5 states — new `attack` state must be added.
- Uses `Sprite2D` with `region_rect` + spritesheet (not `AnimatedSprite2D`).
- `last_direction: Vector2` tracks facing (DOWN/UP/LEFT/RIGHT).
- No `"attack"` input action in `project.godot` yet.
- No energy system (PLANT-07). Energy gain on hit = stub comment only.

Full source: **read `player/scripts/player_controller.gd` directly** (146 lines).

### 2. Player Animation Builder — `player/scripts/player_animation_builder.gd`

`@tool` script that generates animations programmatically:
- `FRAME_SIZE = 64`, direction rows: down=0, left=1, right=2, up=3.
- `DIR_NAMES = ["down", "left", "right", "up"]`
- `ANIM_DEFS` array — each entry: `prefix`, `sheet` (path to `_full.png`), `columns`, `frames[4]`, `loop`, `duration`.
- `build()` creates `AnimationLibrary` with `region_rect` keyframes.
- `build_tree()` creates `AnimationNodeStateMachine` with `AnimationNodeBlendSpace2D` per state, plus transitions.
- Current defs: `idle`, `walk`, `run`, `hurt`, `death`.
- Current transitions: idle<->walk, idle<->run, walk<->run, {idle,walk,run}->hurt, hurt->idle (auto-advance), {idle,walk,run,hurt}->death, death->idle.
- **No attack animation def or transitions exist.**

Full source: **read `player/scripts/player_animation_builder.gd` directly** (158 lines).

### 3. Player Scene — `player/scenes/player.tscn`

```
Player (CharacterBody2D) — collision_layer=4 (PLAYER), collision_mask=2 (TERRAIN)
+-- Sprite2D (unique) — 64x64 region_rect, nearest filter
+-- AnimationPlayer (unique)
+-- AnimationTree (unique) — state machine with blend spaces
+-- CollisionShape2D — CapsuleShape2D (radius 5, height 22)
+-- Camera2D (unique) — zoom (1.5, 1.5), smooth_camera.gd
```

References only `Unarmed_*` spritesheets. **No hitbox Area2D for sword attack.**

### 4. Available Sword Spritesheets — `player/sprites/PNG/`

All use 64x64 frames, same 4-row direction layout (down, left, right, up):

| Sheet | Res Path |
|---|---|
| **Sword_attack** (primary) | `res://player/sprites/PNG/Sword_attack/Sword_attack_full.png` |
| Sword_Idle | `res://player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` |
| Sword_Walk | `res://player/sprites/PNG/Sword_Walk/Sword_Walk_full.png` |
| Sword_Run | `res://player/sprites/PNG/Sword_Run/Sword_Run_full.png` |
| Sword_Hurt | `res://player/sprites/PNG/Sword_Hurt/Sword_Hurt_full.png` |
| Sword_Death | `res://player/sprites/PNG/Sword_Death/Sword_Death_full.png` |
| Sword_Walk_Attack (stretch) | `res://player/sprites/PNG/Sword_Walk_Attack/Sword_Walk_Attack_full.png` |
| Sword_Run_Attack (stretch) | `res://player/sprites/PNG/Sword_Run_Attack/Sword_Run_Attack_full.png` |

**Do NOT scan spritesheet images.** Use `FRAME_SIZE = 64` and same direction layout. For `Sword_attack_full.png` frame counts — **ask me or use placeholders I will confirm.**

### 5. Collision Layers

```
layer_1=interactable, layer_2=terrain, layer_3=player, layer_4=enemy, layer_5=projectile
```

`shared/collision_layers.gd`: `INTERACTABLE=1, TERRAIN=2, PLAYER=4, ENEMY=8, PROJECTILE=16`.

Sword hitbox `Area2D`: collision_layer=0, collision_mask detects **layer 4 (enemy)**.

### 6. Combat Folder — `combat/`

```
combat/weapons/thorn_sword/  (empty)
combat/weapons/vine_whip/    (empty)
combat/weapons/spore_bomb/   (empty)
combat/weapons/petal_shield/ (empty)
combat/projectiles/          (empty)
```

### 7. GameManager — `shared/autoloads/game_manager.gd`

Autoload. Has `player` ref via `register_player()`. Signals: `game_state_changed`, `core_hp_changed`, `core_destroyed`, `game_over_triggered`, `player_hp_changed`, `player_died`, `player_respawned`. **No combat signals yet.**

Full source: **read `shared/autoloads/game_manager.gd` directly** (57 lines).

### 8. Autoloads in `project.godot`

```
GameManager, DayNightCycle, SceneTransition
```

Input actions: `move_up`, `move_down`, `move_left`, `move_right`. **No `attack` action.**

---

## Task — What To Build

### Design Decisions (defaults for values not in GDD)

| Parameter | Value | Rationale |
|---|---|---|
| Base damage | **15** | Shadowling = 40 HP (§8.1), ~3 hits to kill |
| Attack cooldown | **0.5 s** | 1.0x base attack speed |
| Hitbox shape | 90-deg arc or rect approximation | GDD §14: swing arc 90 derajat |
| Hitbox range | **1.5 tiles** (24 px) | Short melee |
| Hitbox active window | Only during active frames | No lingering damage |
| Movement during attack | **Stopped** | Commit-to-swing feel |
| Attack input | LMB + Space | Standard action RPG |

### A. Add `"attack"` Input Action — `project.godot`

Add `attack` mapped to Left Mouse Button (button_index=1) and Space key.

### B. Weapon Data Resource — `combat/weapons/weapon_data.gd`

Generic `Resource` class reusable by all 4 weapons:

```gdscript
class_name WeaponData
extends Resource

@export var weapon_name: String = ""
@export var damage: int = 0
@export var cooldown: float = 0.5
@export var attack_range: float = 24.0
@export var arc_degrees: float = 90.0
```

### C. Thorn Sword Data — `combat/weapons/thorn_sword/thorn_sword_data.tres`

`.tres` using `WeaponData`: weapon_name="Thorn Sword", damage=15, cooldown=0.5, attack_range=24.0, arc_degrees=90.0.

### D. Add Attack Animation to Animation Builder — `player/scripts/player_animation_builder.gd`

Add new entry to `ANIM_DEFS`:

```gdscript
{
    "prefix": "attack",
    "sheet": "res://player/sprites/PNG/Sword_attack/Sword_attack_full.png",
    "columns": <PLACEHOLDER>,
    "frames": [<PLACEHOLDER>, <PLACEHOLDER>, <PLACEHOLDER>, <PLACEHOLDER>],
    "loop": false,
    "duration": 0.4,
},
```

> **Frame count placeholders:** Ask me for the actual values, or open the spritesheet in Aseprite to count. Use the same convention: columns = max frames in any row, frames = [down, left, right, up].

Add transitions in `build_tree()`:
- `idle` -> `attack`, `walk` -> `attack`, `run` -> `attack` (normal transitions)
- `attack` -> `idle` (auto-advance, `ADVANCE_MODE_AUTO`)
- Do NOT allow `attack` -> `hurt` transition (let hurt interrupt via `_travel()` logic instead)

Add `"attack"` to `_update_blend_position()` in `player_controller.gd`.

### E. Add Sword Hitbox to Player Scene — `player/scenes/player.tscn`

Add child nodes to Player:

```
Player (CharacterBody2D)
+-- ... (existing)
+-- SwordHitbox (Area2D) — unique_name_in_owner = true
    +-- CollisionShape2D — disabled by default
```

Configuration:
- `Area2D` collision_layer = 0, collision_mask = 8 (enemy layer 4, bit value 8)
- `CollisionShape2D`: `RectangleShape2D` size ~(20, 20), positioned 16-24 px in front of player center. **Disabled** by default — only enabled during active attack frames.
- The hitbox position must **rotate** based on `last_direction` to face the correct direction (down/up/left/right). This can be done by changing `SwordHitbox.position` or `SwordHitbox.rotation` in code when attacking.

### F. Attack Logic in Player Controller — `player/scripts/player_controller.gd`

Add to the existing script:

**New variables:**
- `var is_attacking: bool = false`
- `var _attack_cooldown_timer: float = 0.0`
- `@onready var _sword_hitbox: Area2D = %SwordHitbox`
- `var _current_weapon: WeaponData = null` (loaded with thorn_sword_data.tres by default)

**New signal:**
- `signal attack_hit(target: Node, damage: int)` — emitted each time hitbox connects

**Modify `_physics_process()`:**
- Decrement `_attack_cooldown_timer` by `delta`.
- If `is_attacking`: set `velocity = Vector2.ZERO`, skip movement input, still call `move_and_slide()`.

**Modify `_travel()`:**
- Also block transitions when `is_attacking` (current == &"attack").

**Modify `_unhandled_input()` or add `_input()`:**
- On `Input.is_action_just_pressed("attack")`: if not `is_dead`, not `is_attacking`, and `_attack_cooldown_timer <= 0`: call `_start_attack()`.

**New methods:**

1. `_start_attack() -> void`:
   - `is_attacking = true`
   - `velocity = Vector2.ZERO`
   - `_state_machine.travel("attack")`
   - `_update_blend_position()`
   - Position `_sword_hitbox` based on `last_direction` (e.g. down=Vector2(0,16), up=Vector2(0,-16), left=Vector2(-16,0), right=Vector2(16,0))
   - Enable hitbox collision after a short delay (hitbox_start_frame timing)
   - Use `await` or a timer to disable hitbox after active frames end
   - After full animation duration: `_end_attack()`

2. `_end_attack() -> void`:
   - `is_attacking = false`
   - `_attack_cooldown_timer = _current_weapon.cooldown`
   - Disable `_sword_hitbox` collision shape
   - `_state_machine.travel("idle")`

3. `_on_sword_hitbox_body_entered(body: Node2D) -> void`:
   - Connect this to `SwordHitbox.body_entered` signal.
   - If body has `take_damage()` method: call `body.take_damage(_current_weapon.damage)`.
   - Emit `attack_hit(body, _current_weapon.damage)`.
   - `# TODO (PLANT-07): Add +3 energy per hit here.`
   - Trigger hit VFX (see section G).
   - Each body should only be hit **once per swing**. Track hit bodies in a local array, clear it on `_start_attack()`.

### G. Swing VFX — Placeholder

The `Sword_attack_full.png` spritesheet already includes swing trail baked in. No extra VFX node needed for vertical slice. Add comment: `# TODO (VFX-05): Add impact particles on hit.`

### H. Hit SFX — Placeholder

Add `AudioStreamPlayer2D` named `SwordSFX` to Player scene, stream = null. Call `SwordSFX.play()` in `_start_attack()` only if stream assigned. Future drop-in ready.

### I. Debug Testing

- Thorn Sword **auto-equipped** on start (vertical slice, no loadout system yet).
- Print `"DEBUG: Attack! Damage: %d, Direction: %s"` on swing.
- Print `"DEBUG: Hit %s for %d damage"` on body hit.

---

## Technical Standards

- **Static typing everywhere**
- **Unique name references** (`%NodeName`), mark new nodes `unique_name_in_owner = true`
- **Godot 4 signal syntax**
- **No new comments/docs** unless specified (exception: TODO stubs above)
- **No deletion** of existing `.tscn` data — only add/modify
- **Prefer minimal edits** — extend existing files, don't rewrite

---

## File Checklist

| Action | File | Reason |
|--------|------|--------|
| **Modify** | `project.godot` | Add `attack` input action (LMB + Space) |
| **Create** | `combat/weapons/weapon_data.gd` | Generic weapon Resource class |
| **Create** | `combat/weapons/thorn_sword/thorn_sword_data.tres` | Thorn Sword stats |
| **Modify** | `player/scripts/player_animation_builder.gd` | Add `attack` ANIM_DEF + transitions in `build_tree()` |
| **Modify** | `player/scripts/player_controller.gd` | Add attack input, `is_attacking`, `_start_attack()`, `_end_attack()`, hitbox logic, cooldown, blend position for attack state |
| **Modify** | `player/scenes/player.tscn` | Add `SwordHitbox` (Area2D + CollisionShape2D) and `SwordSFX` (AudioStreamPlayer2D) nodes |

---

## Acceptance Criteria

Run the project and confirm:

1. **Attack input works.** Press Space or LMB — player plays attack animation in current facing direction. Movement stops during swing.
2. **Attack cooldown.** Cannot spam attack faster than 0.5 s intervals.
3. **Hitbox activates.** Hitbox only active during middle frames of attack animation, disabled before and after.
4. **Hitbox direction.** Hitbox appears in front of player based on facing direction (down/up/left/right).
5. **Damage dealt.** Enemies in hitbox receive 15 damage (tested via debug prints since CORE-06 enemies don't exist yet — test with a dummy `StaticBody2D` on enemy layer).
6. **Single hit per swing.** Each enemy hit only once per attack, not multiple times.
7. **Animation plays.** Attack animation plays fully, then returns to idle. No animation glitches.
8. **Blend directions.** Attack animation faces correct direction for all 4 cardinal directions.
9. **Cannot attack while dead.** If `is_dead`, attack input is ignored.
10. **Cannot attack during hurt.** If in hurt state, attack input is ignored.
11. **VFX.** Swing visual from spritesheet renders during attack.
12. **No regression.** Walk, idle, hurt, death, respawn, invincibility all still work correctly.

### Post-Implementation

13. **Update `TASK_BREAKDOWN.md`.** Mark CORE-05 as `Done`.
