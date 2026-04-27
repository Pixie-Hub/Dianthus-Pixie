# PROMPT — END-04: Endless Post-Game Mode

**Task ID:** END-04  
**Priority:** Low  
**Effort:** M (1–3 days)  
**Dependencies:** END-01 (True Ending — Done)  
**GDD Reference:** §5.2 Endless / Post-Game Mode, §8.2 Day 30+ scaling

---

## Acceptance Criteria (from TASK_BREAKDOWN.md)

> Endless mode unlocks after True Ending per GDD §5.2; exponential scaling (×1.5 HP/DMG every 5 days) continues indefinitely; local leaderboard records highest day reached.

---

## Context — What Already Exists

### Unlock flag
- `StoryEndingFlags.unlock_endless_mode` constant already defined in `quests/data/story/ending_flags.gd`.
- `EndingManager._fire("true")` already calls `UnlockFlags.set_flag(StoryEndingFlags.unlock_endless_mode)` in `core/endings/ending_manager.gd:50`.
- The EndlessButton on the ending screen is already wired in `ui/screens/ending_screen.tscn:94-97` (visible=false, text "Endless Mode") and connected in `ending_screen.gd:42`.

### Ending screen stub
- `ending_screen.gd:73-75` has the `_on_endless()` method with a `TODO: END-04` comment. This is where Endless Mode activation should go.

### Wave spawner scaling
- `enemies/spawner/wave_spawner.gd` handles per-day difficulty via:
  - `hp_growth_per_day` (0.10), `spawn_growth_per_day` (+1), `max_hp_multiplier` (3.0), `max_spawn_count` (20).
  - `DifficultyManager` tier multipliers stack multiplicatively on top.
- Currently **linear** scaling. GDD §8.2 says Day 30+ should be **exponential ×1.5 HP/DMG every 5 days**.

### Save system
- `save_manager.gd` SCHEMA_VERSION=9. The `state["unlocks"]` key is stubbed as `[]` with `TODO: END-04` comment at line 226.
- `UnlockFlags` already persists `unlock_endless_mode` via `serialize()/deserialize()`. The `state["unlocks"]` stub is unused and can remain empty or be repurposed for the leaderboard.

### Relevant autoloads (project.godot)
DayNightCycle, GameManager, DifficultyManager, SaveManager, InventoryManager, CraftingManager, BreedingManager, QuestManager, DailyQuestRoller, CodexManager, UnlockFlags, ZoneTracker, EndingManager.

---

## Scope — What to Implement

### 1. Endless Mode State Flag (GameManager)

Add a `var endless_mode: bool = false` to `shared/autoloads/game_manager.gd`.
- Set to `true` when player activates Endless Mode from the ending screen.
- Persisted in save data under `state["endless_mode"]` (boolean).
- Reset to `false` on New Game (add to `main_menu.gd:_start_new_game()`).
- Restored on load in `save_manager.gd:_apply_state()`.

### 2. Exponential Scaling in WaveSpawner

In `enemies/spawner/wave_spawner.gd`, modify `start_wave()`:
- **When `GameManager.endless_mode == true` AND `DayNightCycle.day_count >= 30`:**
  - HP multiplier = `1.5 ^ floor((day_count - 30) / 5)` (×1.0 at day 30, ×1.5 at day 35, ×2.25 at day 40, etc.), **stacked on top** of existing linear + difficulty tier multipliers.
  - DMG multiplier = same formula. Apply to `enemy.damage` alongside existing DifficultyManager dmg_mult.
  - Spawn count: remove the `max_spawn_count` cap (or raise it significantly, e.g. 50).
  - All 4 entry points always active (force `count = _spawn_point_markers.size()`).
- **When `GameManager.endless_mode == false`:** behavior unchanged (existing linear scaling).

### 3. Ending Screen → Activate Endless Mode

In `ui/screens/ending_screen.gd`:
- `_on_ending()`: Show EndlessButton if `UnlockFlags.has_flag(StoryEndingFlags.unlock_endless_mode)` (not just `ending_id == "true"` — the flag persists across runs, so returning players see it too).
- `_on_endless()`: Replace the TODO stub with:
  1. `GameManager.endless_mode = true`
  2. Unpause the tree.
  3. Hide the ending screen.
  4. Print `[EndingScreen] Endless Mode activated.`
  5. The game continues from the current day — no scene reload.

### 4. Local Leaderboard

Create `save/scripts/endless_leaderboard.gd` (autoload `EndlessLeaderboard`):
- Separate file from main save: `user://endless_leaderboard.json`.
- Data: Array of entries `{ "day": int, "date_unix": int }`, sorted descending by day, max 10 entries.
- Public API:
  - `submit_score(day: int) -> int` — inserts into sorted list, trims to 10, saves to file, returns rank (1-indexed, 0 if not placed).
  - `get_scores() -> Array[Dictionary]` — returns the sorted list.
  - `get_best_day() -> int` — returns top entry's day, or 0 if empty.
  - `clear() -> void` — deletes leaderboard file (debug only).
- **When to submit:** On Game Over (Core HP 0) during Endless Mode, AND on Main Menu exit during Endless Mode. Hook into `GameManager.game_over_triggered` + check `endless_mode`.

### 5. Leaderboard Display on Game Over Screen

Modify `ui/hud/game_over_screen.gd` (or whichever screen handles Game Over):
- If `GameManager.endless_mode`:
  - Show "ENDLESS MODE — Day X" as the title instead of normal Game Over text.
  - Call `EndlessLeaderboard.submit_score(DayNightCycle.day_count)`.
  - Display the rank: "New Record! Rank #N" or "Best: Day Y" if not a new record.
  - Show top 5 leaderboard entries below the stats.

### 6. HUD Indicator

In `ui/hud/hud.gd`:
- When `GameManager.endless_mode == true`, show a small "∞ ENDLESS" label somewhere unobtrusive (e.g., next to the day counter in the Time-of-Day indicator, or a small badge near the wave counter).
- This is a visual-only indicator so the player knows they're in Endless Mode.

### 7. Save Schema

- Bump `SCHEMA_VERSION` from 9 to 10.
- `_gather_state()`: add `state["endless_mode"] = GameManager.endless_mode`.
- `_apply_state()`: read `GameManager.endless_mode = state.get("endless_mode", false)`.
- `_migrate()`: v9→v10 adds `data["endless_mode"] = false` for old saves.
- Remove the `TODO: END-04` comment from `state["unlocks"]` line.
- The leaderboard is a **separate file** — no interaction with the main save schema.

### 8. Debug Keys

Add to `player/scripts/player_controller.gd`:
- **Ctrl+4**: Toggle Endless Mode on/off (`GameManager.endless_mode = !GameManager.endless_mode`, print state).
- **Ctrl+Shift+4**: Submit current day to leaderboard + print rank.

### 9. Main Menu — Endless Mode Awareness

In `ui/menus/main_menu.gd`:
- If `EndlessLeaderboard.get_best_day() > 0`, show "Best Endless: Day X" on the main menu somewhere (e.g., below the Continue button or in a corner).
- This is optional polish — implement only if time allows.

---

## Files to Create

| File | Purpose |
|------|---------|
| `save/scripts/endless_leaderboard.gd` | Autoload — leaderboard read/write to `user://endless_leaderboard.json` |

## Files to Modify

| File | Changes |
|------|---------|
| `shared/autoloads/game_manager.gd` | Add `var endless_mode: bool = false` |
| `enemies/spawner/wave_spawner.gd` | Endless exponential scaling in `start_wave()` + `_spawn_enemy()` (DMG), remove spawn cap in endless |
| `ui/screens/ending_screen.gd` | `_on_endless()` activates endless mode; EndlessButton visibility uses flag check |
| `save/scripts/save_manager.gd` | Schema v10; serialize/deserialize `endless_mode`; remove TODO comment |
| `player/scripts/player_controller.gd` | Ctrl+4 / Ctrl+Shift+4 debug keys |
| `ui/hud/hud.gd` | Endless mode indicator label |
| `ui/menus/main_menu.gd` | Optional: best endless day display |
| `project.godot` | Register `EndlessLeaderboard` autoload |
| `docs/design/TASK_BREAKDOWN.md` | END-04 status → Done |
| `docs/design/PERSON_TASKS.md` | Ctrl+4 / Ctrl+Shift+4 debug key rows |

---

## Out of Scope

- **DIFF-02** (Surge Night every 7th night) — separate task; Endless Mode does not add surge logic.
- **ENEMY-04/05** (Swarm Larva / Devourer) — spawned by story, not endless scaling.
- **New Game+** — GDD §11.3 mentions it but no task exists; not part of END-04.
- **Online leaderboard** — local only per GDD §5.2.

---

## Testing Checklist

1. **Fresh start:** Endless Mode button hidden on ending screen until True Ending is achieved.
2. **True Ending → Endless:** Press "Endless Mode" button → game unpauses → `GameManager.endless_mode == true` → HUD shows indicator.
3. **Scaling at Day 35:** HP/DMG should be ×1.5 of Day 30 values (on top of linear + tier).
4. **Scaling at Day 40:** HP/DMG should be ×2.25 of Day 30 values.
5. **Game Over in Endless:** Score submitted to leaderboard; rank displayed; leaderboard file written.
6. **Leaderboard persistence:** Quit game → reopen → main menu shows best day → leaderboard file still intact.
7. **Save/Load in Endless:** Save during endless → load → `endless_mode` is true → scaling still applies.
8. **New Game after Endless:** `endless_mode` reset to false; normal scaling resumes.
9. **Ctrl+4 debug:** Toggles endless on/off mid-run; wave scaling changes immediately on next night.
10. **Ctrl+Shift+4 debug:** Submits score and prints rank to Output.
11. **Old save migration:** v9 save loads cleanly; `endless_mode` defaults to false.
