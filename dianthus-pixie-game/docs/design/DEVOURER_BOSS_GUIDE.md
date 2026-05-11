# ENEMY-05 — The Devourer Boss: Implementation Guide

> **Task:** ENEMY-05 | **Effort:** XL | **Status:** Not Started
> **Dependencies:** ENEMY-01 ✅, ENEMY-02 ✅, ENEMY-03 ✅, ENEMY-04 (Not Started)
> **GDD Reference:** §8.1 enemy table row, §8.2 Spike Nights

---

## 1. What the GDD Defines

| Field | Value |
|---|---|
| HP | 1200 |
| Speed | Slow–Medium (lambat-sedang) |
| Damage | 50/hit |
| FSM Quirk | Boss unik — 3 phases, summons minions |
| Weakness | Dianthus Pollen weapon |
| Trigger | Final Night (triggered by story quest) |

The GDD also states:
- "Malam Final (tergantarkan oleh story quest): The Devourer — boss bermekanik 3 fase"
- The True Ending requires defeating The Devourer on Day 30+.
- BGM `devourer_boss.mp3` has three 30-second segments mapped to the 3 phases.

**What the GDD does NOT define** (flagged in `Konsul.md`):
- HP thresholds for phase transitions
- Attack patterns per phase
- Minion types and spawn cadence
- Exact trigger condition for the final story night

---

## 2. Design Decisions (Proposed)

These fill the GDD gaps. Review and adjust before implementation.

### 2.1 Phase Thresholds

| Phase | HP Range | Theme |
|---|---|---|
| Phase 1: Approach | 1200–840 (100%–70%) | Slow, probing; BGM 0–30s |
| Phase 2: Fury | 840–360 (70%–30%) | Aggressive, chaotic; BGM 30–60s |
| Phase 3: Desperation | 360–0 (30%–0%) | All-out, Core-targeting; BGM 60–90s |

### 2.2 Phase 1 — "The Approach"

- **Movement:** Walks slowly toward the Dianthus Core (speed ~30 px/s).
- **Attack — Void Slam:** Melee AoE around self (radius ~40px). 50 DMG to player, 30 DMG to plants in range. Cooldown 2.5s.
- **Minion Summon:** Every 15s, summons 2 Shadowlings at random spawn points.
- **Behavior:** Primarily Siege-focused. Will switch to Attack state if player is within melee range, but always re-targets Core when player moves away.
- **Visual:** Dark purple modulate, pulsing aura.

### 2.3 Phase 2 — "The Fury" (HP drops below 70%)

- **Speed increases** to ~45 px/s.
- **Attack — Void Slam** cooldown reduced to 1.8s.
- **New Attack — Dark Pulse:** Ranged AoE projectile aimed at player position. Radius 32px on impact, 35 DMG. Cooldown 4s. Telegraphed by a 0.8s charge-up visual.
- **Minion Summon:** Every 12s, summons 1 Voidrunner + 1 Shadowling.
- **Behavior:** More aggressive player targeting. Will chase player for up to 3s before re-routing to Core.
- **Visual:** Intensified aura, sprite modulate shifts redder.

### 2.4 Phase 3 — "Desperation" (HP drops below 30%)

- **Speed increases** to ~55 px/s.
- **Void Slam** cooldown reduced to 1.2s, damage increased to 60.
- **Dark Pulse** cooldown reduced to 3s, damage increased to 45.
- **New Attack — Devour Surge:** At 15% HP, performs a one-time channeled attack on the Core dealing 100 DMG over 3s if not interrupted. Player can interrupt by dealing any damage during the channel. Telegraphed with a visible tether from Devourer to Core.
- **Minion Summon:** Every 10s, summons 2 Voidrunners.
- **Behavior:** Desperately targets Core. Only attacks player if they are directly blocking the path.
- **Visual:** Sprite flashes, unstable aura, screen-edge vignette effect.

### 2.5 Dianthus Pollen Weakness

- Attacks from any weapon crafted with Dianthus Pollen deal **1.5× damage** to The Devourer.
- Currently no "Dianthus Pollen weapon" exists in the crafting system — this should be implemented as a damage multiplier check on the boss's `take_damage()`.
- Possible implementation: check `CraftingManager` for whether the equipped weapon's recipe includes `dianthus_pollen`, or add a `is_pollen_weapon: bool` field to `WeaponData`.
- Pollen-weapon crafting opens after Story 06 “Petals of Power”, which harvests Dianthus Pollen from the Sacred Bloom Core at Meadow Edge.

### 2.6 Trigger Condition

The Devourer fight is triggered by the story quest chain:
1. `story_06_pollen` completes → auto-starts `story_07_devourer` ("The Final Bloom").
2. The **next night** after `story_07_devourer` becomes active, the WaveSpawner should detect the active quest and replace the normal wave with a Devourer boss encounter.
3. Quest objective `devourer_defeated` (event_id `&"devourer_defeated"`) fires when the boss's `die()` is called.

Integration point: `WaveSpawner._on_phase_changed("NIGHT")` checks `QuestManager.is_quest_active(&"story_07_devourer")` → if true, calls `_start_devourer_fight()` instead of `start_wave()`.

---

## 3. Existing Patterns to Follow

### 3.1 Enemy Script Pattern

All enemies follow this structure (see `shadowling.gd`, `phantom_weaver.gd`):

```gdscript
class_name TheDevourer
extends EnemyBase

func _ready() -> void:
    super._ready()

func activate() -> void:
    var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
    if fsm != null:
        fsm.transition_to(&"Phase1")

func should_retreat() -> bool:
    return false

func _get_death_sfx_id() -> String:
    return "devourer_death"  # TODO: Register in SfxManager

func _get_seed_drop_table() -> Array[Dictionary]:
    return []  # Boss drops handled via quest reward
```

### 3.2 FSM State Pattern

All enemy states extend base classes in `enemies/fsm/`:
- `EnemyIdleState` — waits for night, transitions to active state
- `EnemyScoutState` — navigates toward Core with wander
- `EnemySiegeState` — attacks Core/barricades at range
- `EnemyAttackState` — chases and attacks player

For The Devourer, **custom states are needed** since it doesn't follow the standard Scout→Siege→Attack flow. Recommended states:

| State | Extends | Purpose |
|---|---|---|
| `DevourerIdle` | `State` (direct) | Entry point; waits for activation |
| `DevourerPhase1` | `State` (direct) | Phase 1 movement + Void Slam + minion summon |
| `DevourerPhase2` | `State` (direct) | Phase 2 adds Dark Pulse + faster minions |
| `DevourerPhase3` | `State` (direct) | Phase 3 Desperation + Devour Surge |

Phase transitions are driven by HP thresholds checked in `take_damage()` override:

```gdscript
func take_damage(amount: int) -> void:
    # Apply Dianthus Pollen weakness multiplier
    var effective_amount: int = amount
    if _is_pollen_damage:
        effective_amount = int(amount * 1.5)
    super.take_damage(effective_amount)
    if is_dead:
        return
    _check_phase_transition()

func _check_phase_transition() -> void:
    var ratio: float = float(current_hp) / float(max_hp)
    var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
    if fsm == null:
        return
    if _current_phase == 1 and ratio <= 0.7:
        _current_phase = 2
        fsm.transition_to(&"Phase2")
    elif _current_phase == 2 and ratio <= 0.3:
        _current_phase = 3
        fsm.transition_to(&"Phase3")
```

### 3.3 Scene Structure (.tscn)

Based on existing enemies like `phantom_weaver.tscn`:

```
TheDevourer (CharacterBody2D) [script: the_devourer.gd]
├── Sprite2D [unique_name_in_owner, texture: the_devourer.png]
├── CollisionShape2D [CircleShape2D, radius ~16-20px]
├── AnimationPlayer [unique_name_in_owner]
│   ├── RESET
│   ├── idle
│   ├── walk
│   ├── attack
│   ├── charge (for Dark Pulse telegraph)
│   └── channel (for Devour Surge)
├── NavigationAgent2D [unique_name_in_owner]
├── StateMachine
│   ├── Idle [script: devourer_idle.gd]
│   ├── Phase1 [script: devourer_phase1.gd]
│   ├── Phase2 [script: devourer_phase2.gd]
│   └── Phase3 [script: devourer_phase3.gd]
├── VoidSlamArea (Area2D) [collision_mask = PLAYER | BARRICADE]
│   └── CollisionShape2D [CircleShape2D, radius ~40px, disabled by default]
└── BossHPBar (optional in-scene or driven by HUD)
```

### 3.4 Collision Layers

From `shared/collision_layers.gd`:
- Boss body: `collision_layer = CollisionLayers.ENEMY` (8), `collision_mask = CollisionLayers.MASK_ENEMY` (PLAYER | BARRICADE = 36)
- VoidSlamArea: `collision_mask = CollisionLayers.PLAYER` (4) — detect player for melee AoE
- Dark Pulse projectile (if separate scene): `collision_layer = CollisionLayers.PROJECTILE` (16)

---

## 4. File Plan

### 4.1 New Files

| Path | Purpose |
|---|---|
| `enemies/devourer/the_devourer.gd` | Boss script (extends EnemyBase) |
| `enemies/devourer/the_devourer.tscn` | Boss scene |
| `enemies/devourer/states/devourer_idle.gd` | Idle state |
| `enemies/devourer/states/devourer_phase1.gd` | Phase 1 logic |
| `enemies/devourer/states/devourer_phase2.gd` | Phase 2 logic |
| `enemies/devourer/states/devourer_phase3.gd` | Phase 3 logic |
| `enemies/devourer/devourer_dark_pulse.gd` | Dark Pulse projectile (Phase 2+) |
| `enemies/devourer/devourer_dark_pulse.tscn` | Dark Pulse projectile scene |

### 4.2 Modified Files

| Path | Change |
|---|---|
| `enemies/spawner/wave_spawner.gd` | Add Devourer fight trigger when `story_07_devourer` is active; spawn boss instead of normal wave; boss death emits `wave_cleared` |
| `combat/weapons/weapon_data.gd` | Add `is_pollen_weapon: bool` export (or equivalent) |
| `audio/sfx_manager.gd` | Register Devourer SFX IDs (slam, dark_pulse, channel, death, phase_transition) |
| `audio/music_manager.gd` | Handle `devourer_boss.mp3` 3-segment playback tied to boss phase |
| `player/scripts/player_controller.gd` | Add debug key (e.g., Ctrl+5) to force-spawn Devourer; wire pollen weapon damage multiplier |
| `quests/scripts/quest_manager.gd` | Ensure `devourer_defeated` event fires correctly from boss `die()` |
| `ui/hud/hud.gd` | (Optional) Show boss HP bar during Devourer fight |
| `docs/design/TASK_BREAKDOWN.md` | Update ENEMY-05 status when complete |

---

## 5. Minion Summoning

The Devourer summons existing enemy types. No new minion type is required.

### Summoning Logic

```gdscript
var _summon_timer: float = 0.0
const SUMMON_INTERVAL: float = 15.0  # Phase-dependent

func _summon_minions() -> void:
    var spawner: Node = _find_wave_spawner()
    if spawner == null:
        return
    var container: Node = spawner._enemy_container
    for entry in _get_minion_list():
        var scene: PackedScene = WaveSpawner.ENEMY_SCENES.get(entry.type)
        if scene == null:
            continue
        var minion: EnemyBase = scene.instantiate() as EnemyBase
        # Spawn at random offset from boss position
        var offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(32, 64)
        minion.global_position = global_position + offset
        container.add_child(minion)
        if minion.has_method("activate"):
            minion.activate()
        # Connect to wave spawner tracking so wave_cleared accounts for minions
        spawner._enemies_alive += 1
        spawner._current_wave_total += 1
        minion.enemy_died.connect(spawner._on_enemy_died)
```

### Per-Phase Minion Table

| Phase | Interval | Minions per Summon |
|---|---|---|
| Phase 1 | 15s | 2× Shadowling |
| Phase 2 | 12s | 1× Voidrunner + 1× Shadowling |
| Phase 3 | 10s | 2× Voidrunner |

---

## 6. Boss HP Bar (HUD Integration)

Since The Devourer is a unique boss, a dedicated boss HP bar should appear during the fight.

**Option A — Scene-authored in `hud.tscn`:**
Add a `BossHPBar` PanelContainer (hidden by default) at top-center below Core HP. Show/hide via signal from WaveSpawner or a new `boss_spawned` signal.

**Option B — Boss-owned UI:**
The Devourer scene includes a `Label` or `ProgressBar` above its head (world-space). Simpler but less polished.

**Recommended:** Option A. Add to `hud.tscn`:
```
BossHPPanel (PanelContainer, unique_name_in_owner, visible=false)
├── VBoxContainer
│   ├── BossNameLabel ("THE DEVOURER")
│   └── BossHPBar (ProgressBar)
```

Connect to `GameManager` signal or a new `WaveSpawner.boss_spawned(enemy)` / `WaveSpawner.boss_defeated` signal pair.

---

## 7. Boss Music Integration

`devourer_boss.mp3` is 90 seconds with 3 segments (30s each):
- 0–30s: Phase 1
- 30–60s: Phase 2
- 60–90s: Phase 3

**Integration approach:**
- When the Devourer fight starts, `MusicManager` crossfades to `devourer_boss.mp3`.
- On phase transition, seek the `AudioStreamPlayer` to the appropriate segment offset.
- `MusicManager` needs a `play_boss_phase(phase: int)` method or equivalent.

---

## 8. Death & Victory Flow

When `TheDevourer.die()` is called:

1. **Boss death animation** — custom (not the standard 0.5s fade): slow dramatic death over ~2s with screen flash.
2. **Report event** — `QuestManager.report_event(&"devourer_defeated", {})`.
3. **Clean up minions** — all remaining summoned minions die (queue_free with short death animation).
4. **Wave cleared** — `WaveSpawner.wave_cleared.emit()` triggers night-survived flow.
5. **Music** — `MusicManager` crossfades to silence or victory sting.
6. **Ending** — `EndingManager` checks for True Ending conditions on `night_survived` signal (already implemented).

```gdscript
func die() -> void:
    if is_dead:
        return
    is_dead = true
    velocity = Vector2.ZERO
    # Disable FSM
    var fsm: Node = get_node_or_null("StateMachine")
    if fsm:
        fsm.set_process(false)
        fsm.set_physics_process(false)
    # Kill summoned minions
    for minion in _summoned_minions:
        if is_instance_valid(minion) and not minion.is_dead:
            minion.die()
    enemy_died.emit(self)
    remove_from_group(&"enemies")
    # Report to quest system
    QuestManager.report_event(&"devourer_defeated", {})
    # Play dramatic death
    _play_boss_death_animation()
```

---

## 9. Difficulty Scaling

The Devourer's base stats (1200 HP, 50 DMG) are **not** scaled by the per-day HP growth formula since it's a unique boss. However:

- **Difficulty tier multipliers** (Easy/Normal/Hard from `DifficultyManager`) **should** apply.
- **Endless mode scaling** should NOT apply (boss only appears once per run in story mode).
- Minion summons ARE subject to normal difficulty scaling.

Implementation: WaveSpawner applies `DifficultyManager.get_hp_multiplier()` and `get_dmg_multiplier()` to the boss just like regular enemies, but skips the per-day growth multiplier (`_current_hp_multiplier` = 1.0 for the boss).

---

## 10. Debug Keys

| Key | Action |
|---|---|
| Ctrl+5 | Force-spawn The Devourer at a spawn point (skip quest check) |
| Ctrl+6 | Force phase transition (cycle 1→2→3) |
| Ctrl+7 | Kill all summoned minions |

---

## 11. Acceptance Criteria (from TASK_BREAKDOWN.md)

- [ ] 1200 HP, 50 DMG/hit per GDD §8.1
- [ ] 3 mechanically distinct phases with minion summoning
- [ ] Weak to Dianthus Pollen weapon
- [ ] Triggers on final story night (when `story_07_devourer` is active)
- [ ] Boss death fires `devourer_defeated` event → quest completes → ending check
- [ ] Boss HP bar visible in HUD during fight
- [ ] `devourer_boss.mp3` plays with phase-synced segments
- [ ] Difficulty tier modifiers apply; per-day growth does NOT
- [ ] Summoned minions are tracked by WaveSpawner for wave-cleared logic

---

## 12. Sprite Asset

An existing sprite is available at `enemies/devourer/the_devourer.png` (source: `the_devourer.aseprite`). The sprite shows a dark, tentacled creature with a central purple void eye. It should be used as the base idle frame. Animation frames for walk/attack/charge/channel/death need to be authored in Aseprite and added to the spritesheet.

**Sprite size estimate:** The existing PNG appears to be ~64×64 px — larger than regular enemies (16×24). This is appropriate for a boss.

---

## 13. Open Questions for Design Review

Before implementation, confirm:

1. **Phase thresholds** — Are 70% / 30% acceptable, or should they be adjusted?
2. **Devour Surge** (Phase 3 channel attack) — Is a 100 DMG interruptible channel the right mechanic, or too complex?
3. **Minion cap** — Should there be a max number of active summoned minions (e.g., 6)?
4. **Pollen weapon** — Which specific weapon(s) get the 1.5× bonus? All weapons, or only those crafted with `dianthus_pollen` as an ingredient?
5. **ENEMY-04 dependency** — The task lists ENEMY-04 (Swarm Larva) as a dependency. Is this strict (must ship first), or can The Devourer be implemented without Swarm Larva existing?
6. **Boss arena** — Does the fight happen in Meadow Edge (current main zone) or a special arena? The GDD says "Final Night" which implies the normal garden.
7. **Normal enemies during boss fight** — Does the WaveSpawner also spawn regular wave enemies alongside the boss, or is the boss + summoned minions the entire wave?

---

## 14. Implementation Order

Suggested step-by-step:

1. **Create `the_devourer.gd`** — class_name, exports, phase tracking, `take_damage()` override, `die()` override, `should_retreat() → false`.
2. **Create `the_devourer.tscn`** — Wire Sprite2D, CollisionShape2D, AnimationPlayer, NavigationAgent2D, StateMachine, VoidSlamArea.
3. **Create `devourer_idle.gd`** — Simple entry state, transitions to Phase1 on `activate()`.
4. **Create `devourer_phase1.gd`** — Movement toward Core, Void Slam attack, minion summon timer.
5. **Create `devourer_phase2.gd`** — Inherits Phase1 logic, adds Dark Pulse, faster summons, speed boost.
6. **Create `devourer_phase3.gd`** — Inherits Phase2 logic, adds Devour Surge, max aggression.
7. **Create `devourer_dark_pulse.gd/.tscn`** — Ranged projectile with AoE on impact.
8. **Modify `wave_spawner.gd`** — Add `_start_devourer_fight()` method, quest-active check, boss tracking.
9. **Modify `weapon_data.gd`** — Add pollen weapon flag.
10. **Modify `hud.gd/hud.tscn`** — Add boss HP bar (hidden by default).
11. **Register SFX** — Add Devourer sound IDs to `sfx_manager.gd`.
12. **Wire music** — Phase-synced `devourer_boss.mp3` playback in `music_manager.gd`.
13. **Add debug keys** — Ctrl+5/6/7 in `player_controller.gd`.
14. **Test end-to-end** — Force-spawn boss, verify phase transitions, minion summons, death → quest completion → ending trigger.
15. **Update `TASK_BREAKDOWN.md`** — Mark ENEMY-05 as Done.
