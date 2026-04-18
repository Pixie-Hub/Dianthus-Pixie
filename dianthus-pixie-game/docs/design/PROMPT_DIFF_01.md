# DIFF-01 — Simple Difficulty Scaling — Implementation Prompt

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** S (0.5 day)
**Priority:** High (Week 2)
**Dependencies:** CORE-06 (Shadowling FSM — Done), CORE-07 (Wave Spawner — Done), FOUND-05 (Day/Night Cycle — Done)
**Downstream dependents:** DIFF-02 (Surge Night overrides), future enemy variety tuning

---

## 1. Objective

Add **per-day difficulty scaling** to the Wave Spawner so each successive night is measurably harder than the last. The scaling must be:

1. **Linear** — predictable growth per day, no exponential ramps.
2. **Data-driven** — multipliers exposed as `@export` vars on `WaveSpawner` so a designer can tune without touching code.
3. **Applied per-wave** — values are re-read from `DayNightCycle.day_count` at the moment `start_wave()` is called (so the first wave after a save-load still gets the right scaling).
4. **Non-destructive** — must not break the existing `wave_cleared` flow, CORE-09 Night Survived screen, or any FSM/Plant logic.

The two scaling axes for this task:

| Axis | Formula | Default |
|------|---------|---------|
| Enemy HP | `base_hp * (1 + hp_growth_per_day * (day_count - 1))` | `hp_growth_per_day = 0.10` (+10%/day) |
| Spawn count | `base_total_enemies + spawn_growth_per_day * (day_count - 1)` | `spawn_growth_per_day = 1` (+1 enemy/day) |

**Day 1 = baseline** (no scaling applied). Day 2 = 1.10× HP, +1 enemy. Day 3 = 1.20× HP, +2 enemies. Etc.

---

## 2. Scaling Rules

- **HP scaling** is applied to each spawned enemy instance **after** instantiation, by multiplying `max_hp` and re-assigning `current_hp = max_hp`. Round to `int`.
- **Spawn count scaling** is applied by computing a local `effective_total_enemies` inside `start_wave()`. **Do NOT mutate the exported `total_enemies`** — that would compound across nights. Use a runtime var (`_current_wave_total`) instead.
- **Optional clamp:** `max_hp_multiplier: float = 3.0` and `max_spawn_count: int = 20` as safety caps.
- **Entry point scaling is out of scope** for DIFF-01 (belongs to DIFF-02 Surge Night). Do not change `min_entry_points` / `max_entry_points`.

---

## 3. Architecture

### 3a. WaveSpawner changes (`enemies/spawner/wave_spawner.gd`)

**New `@export` vars (grouped at top, below existing exports):**
```gdscript
@export_group("Difficulty Scaling")
@export var hp_growth_per_day: float = 0.10
@export var spawn_growth_per_day: int = 1
@export var max_hp_multiplier: float = 3.0
@export var max_spawn_count: int = 20
```

**New runtime var (next to `_enemies_spawned`):**
```gdscript
var _current_wave_total: int = 0
var _current_hp_multiplier: float = 1.0
```

**In `start_wave()` — compute scaling from `DayNightCycle.day_count`:**
```gdscript
var day: int = max(1, DayNightCycle.day_count)
var days_passed: int = day - 1
_current_hp_multiplier = min(1.0 + hp_growth_per_day * days_passed, max_hp_multiplier)
_current_wave_total = min(total_enemies + spawn_growth_per_day * days_passed, max_spawn_count)
```

Replace all remaining references to `total_enemies` inside `start_wave()`, `_process()`, and `_check_wave_cleared()` with `_current_wave_total`.

**In `_spawn_enemy()` — apply HP multiplier after `instantiate()` and before `add_child()`:**
```gdscript
if _current_hp_multiplier > 1.0:
    enemy.max_hp = int(round(enemy.max_hp * _current_hp_multiplier))
    enemy.current_hp = enemy.max_hp
```

**Update the print line in `start_wave()`** to log the day and computed values:
```gdscript
print("[WaveSpawner] Wave started. Day: %d, Entry points: %d, Enemies: %d, HP x%.2f" \
    % [day, count, _current_wave_total, _current_hp_multiplier])
```

### 3b. EnemyBase — no changes required

`max_hp` is already an `@export var` on `EnemyBase` and `current_hp` is set in `_ready()`. Because the spawner mutates `max_hp` **before** `add_child()` is called, the enemy's own `_ready()` (which runs `current_hp = max_hp`) will pick up the scaled value automatically. Still, the spawner re-assigns `current_hp = max_hp` after the multiplier is applied to be explicit and defensive against ordering changes.

### 3c. DayNightCycle — no changes required

`day_count` already starts at `1` and increments when the phase transitions from `NIGHT → DAY` in `_advance_phase()`. DIFF-01 only reads it.

---

## 4. File Structure

**Modified files:**
- `enemies/spawner/wave_spawner.gd` — add exports, runtime vars, and scaling logic in `start_wave()` + `_spawn_enemy()`.

**No new files.** No new scenes. No new debug keys required (existing F7 skip-phase + F8 force-wave already allow jumping to Day 2/3/4 quickly).

---

## 5. Acceptance Criteria

1. **Day 1 baseline unchanged:** First night spawns exactly `total_enemies` (default 5) enemies with exactly `max_hp` HP each (default Shadowling = 40 HP). Verify by starting a fresh game and watching the `[WaveSpawner]` log line.
2. **Day 2 scales correctly:** Second night spawns `total_enemies + 1` enemies, each with `round(40 * 1.10) = 44` HP. Verify via log line and by hitting an enemy with the Thorn Sword and checking it takes one extra hit compared to Day 1.
3. **Day 3+ scales linearly:** Day 3 → 7 enemies @ 48 HP. Day 4 → 8 enemies @ 52 HP. Day 11 → 15 enemies @ 80 HP (still below cap).
4. **Caps enforced:** With defaults, by Day 21+ the HP multiplier clamps at `3.0` (120 HP) and spawn count clamps at `20`.
5. **`total_enemies` export is not mutated:** Inspecting `WaveSpawner.total_enemies` in the editor after multiple nights still shows the original designer value. Only `_current_wave_total` changes per wave.
6. **No regression on `wave_cleared`:** The wave still ends correctly when `_enemies_alive == 0 and _enemies_spawned >= _current_wave_total`. CORE-09 Night Survived screen still appears.
7. **No regression on cleanup:** `_cleanup_wave()` still frees leftover enemies. `_current_wave_total` and `_current_hp_multiplier` may be reset or left as-is (they are re-computed next `start_wave()`).
8. **Debug flow works:** Using F7 to skip phase repeatedly, you can observe the log line reporting incrementing day numbers and scaled stats on each night.
9. **Designer tuning works:** Setting `hp_growth_per_day = 0.0` in the editor disables HP scaling. Setting `spawn_growth_per_day = 0` disables count scaling. Both set to 0 → identical to pre-DIFF-01 behaviour.

---

## 6. Existing Codebase Context

You must integrate with these existing systems. **Do NOT modify them unless explicitly stated.**

### Autoloads:
- **`DayNightCycle`** (`core/day_night/day_night_cycle.gd`) — `day_count: int` starts at 1, increments on `NIGHT → DAY` transition. Signal `phase_changed(phase: String)` fires with `"NIGHT"` or `"DAY"`.
- **`GameManager`** — not directly needed for DIFF-01.

### WaveSpawner (`enemies/spawner/wave_spawner.gd`) — current shape:
- Listens to `DayNightCycle.phase_changed` and calls `start_wave()` on `"NIGHT"` and `_cleanup_wave()` on `"DAY"`.
- Uses `total_enemies` (export, default 5) to know when to stop spawning and when the wave is cleared.
- Spawns via `_spawn_enemy()` which `instantiate()`s `enemy_scene`, sets `global_position`, and calls `_enemy_container.add_child(enemy)`.
- Emits `wave_started` / `wave_cleared` / `enemy_spawned(enemy)`.
- Already has a TODO comment for DIFF-02 about entry-point overrides — DIFF-01 does NOT touch that.

### EnemyBase (`enemies/enemy_base.gd`):
- `@export var max_hp: int = 40` — safe to mutate on the instance before `add_child()`.
- `current_hp` is assigned `= max_hp` inside `_ready()`.
- `take_damage()`, `die()`, `hp_changed` signal all operate on the mutated `current_hp` / `max_hp` with no special casing needed.

---

## 7. Important Constraints

- **GDScript only**, Godot 4.6, tabs, full type hints.
- **Do NOT mutate `@export` vars at runtime** — always use a `_current_*` shadow var for per-wave values. This is critical because Godot persists exported values across play sessions in the editor and mutating them compounds bugs.
- **Round HP to `int`** via `int(round(...))`. Do not store a fractional HP.
- **Apply HP scaling before `add_child()`** — this guarantees the enemy's `_ready()` sees the scaled `max_hp`.
- **Do not add a new debug key.** F7 + F8 are sufficient.
- **Do not touch FSM states, plant scripts, HUD, or player code.** DIFF-01 is a surgical change to `wave_spawner.gd` only.
- **Match existing style** — follow the patterns in `wave_spawner.gd` (underscore-prefixed private vars, `push_warning` for designer errors, `print("[WaveSpawner] ...")` for runtime logs).
- **Keep the diff small** — target <40 lines of net additions. If the implementation balloons, you have over-engineered it.

---

## 8. Verification Script (manual QA)

1. Launch `meadow_edge.tscn`.
2. Press **F7** repeatedly to skip through DAY → NIGHT → DAY → NIGHT.
3. Watch the console:
   - Night 1: `Day: 1, Enemies: 5, HP x1.00`
   - Night 2: `Day: 2, Enemies: 6, HP x1.10`
   - Night 3: `Day: 3, Enemies: 7, HP x1.20`
4. On Night 2, press **F5** to spawn a test Shadowling at the mouse and confirm it has **44 HP** (check debugger or add a temporary `print(enemy.max_hp)`). Note: enemies spawned via F5 use the `player_controller` debug spawn path, not the WaveSpawner — so they will NOT be scaled. Only WaveSpawner-spawned enemies scale. This is intentional and correct.
5. Let Night 2 play out naturally; confirm CORE-09 Night Survived screen still appears on `wave_cleared`.
6. Toggle `hp_growth_per_day = 0.0` in the editor, restart, skip to Night 3 → all enemies should still have base HP (40), but spawn count should still scale (7 enemies). Confirms the two axes are independent.

---

## 9. Out of Scope (future tasks — do NOT implement)

- **Surge Night** entry-point overrides → DIFF-02.
- **Damage scaling** on enemies → deferred; HP + count is enough for a 2-week slice.
- **Enemy variety unlocks** (new enemy types appearing on Day N) → separate task.
- **Per-phase difficulty UI** (e.g., "Night 3 — Hard") → belongs to UI-01 / CORE-09 polish.
- **Save/load of `day_count`** → owned by the Save System task, not DIFF-01.
