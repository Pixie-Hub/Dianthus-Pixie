# PROMPT — QUEST-02 / QUEST-03 / QUEST-04: Daily, Progress, Discovery Quests

**Task IDs:** QUEST-02 (Daily Quests), QUEST-03 (Progress Quests), QUEST-04 (Discovery Quests)
**Category:** Quest System
**Priority:** Medium
**Dependencies:** QUEST-01 (Done), PLANT-05 (Done), UI-03 (Done), UI-04 (Done)
**GDD Reference:** §16 — Quest System table

---

## Goal

Layer the three remaining non-story quest types on top of the existing `QuestManager` (QUEST-01) without changing its public contract. All three live as data-driven `.tres` files plus minimal autoload glue:

- **QUEST-02 — Daily Quests:** generated each Morning from a pool, expire at end of same day, drop on success/expiry.
- **QUEST-03 — Progress Quests:** persistent milestone quests that track cumulative stats (days survived, zones unlocked, etc.); reward Aether Bloom or unlock flags.
- **QUEST-04 — Discovery Quests:** fire when a new plant or breeding combo is discovered; reward Codex entries (already auto-discovered by `CodexManager`) plus crafting recipe unlock flags.

No save schema bump for the quest container itself — `QuestManager.serialize()/deserialize()` already round-trips `_active`/`_completed`/`_failed`. Daily-pool state (today's roll, last-rolled-day) needs new fields under `quest` save section. Bump `SCHEMA_VERSION` only if those fields are added.

---

## Scope

### In Scope
1. **Daily Quest Pool** — `quests/data/daily/` directory with 6–8 `QuestData.tres` (Type=DAILY, `auto_start=false`); a `DailyQuestRoller` selects 1–2 each Morning.
2. **Daily reroll logic** — replace the `# TODO: QUEST-02 — daily quest reroll on day start` stub in `quest_manager.gd`. On phase=DAY at day_count change, fail any unfinished daily quests with reason `"expired"` (not shown in Failed tab — see §UX) and start a new roll.
3. **Progress Quests** — `quests/data/progress/` with 4–5 milestone quests (Type=PROGRESS, `auto_start=true`). Use existing events plus two new ones: `&"zone_unlocked"`, `&"plant_unlocked_at_day"` (deferred — leave TODO if WORLD-01..04 not done).
4. **Discovery Quests** — `quests/data/discovery/` with 4–5 quests (Type=DISCOVERY, `auto_start=true`). Drive off existing `&"plant_discovered"` and `&"plant_bred"` events. Add new event `&"combo_attempted"` (success or fail) emitted from `BreedingManager`.
5. **Reward unlock flags** — replace the `# TODO: QUEST-03 — process reward_unlock_flags` stub in `_grant_rewards`. Implement a tiny `UnlockFlags` autoload: `set_flag(name)/has_flag(name)/serialize()/deserialize()`. Hook it into `SaveManager`.
6. **Recipe unlock via Discovery** — Discovery Quest rewards may carry flag `recipe_<weapon_id>`. `CraftingManager.can_craft()` should respect a "locked behind flag" hint stored on the recipe. (See §Recipe gating — minimal change.)
7. **Daily-quest UX in QuestLog** — daily quests already render via existing UI-03 code. Verify type badge "DAILY" appears (it does — UI-03 already handles all four types).
8. **Save persistence** — daily roll state (`last_rolled_day:int`, `current_daily_ids:Array[StringName]`) and `UnlockFlags`. Migrate.
9. **Debug keys** — add `Shift+Q` to force daily reroll, `Ctrl+Shift+Q` to print all active+completed+failed quests.

### Out of Scope
- Story quests (QUEST-05).
- Quest-pin / abandon / map-marker UI.
- Endings hooked off Discovery completion (END-03 — leave a TODO comment).
- WORLD-01..04 zone-unlock event emission (leave `&"zone_unlocked"` event subscription wired but with a TODO and no emitter).
- Tutorial integration (ACCESS-03).
- Dialogic timelines for daily/progress/discovery (leave fields blank in `.tres`).
- Re-rolling a single daily quest at runtime (only full reroll on day change).
- Any new HUD widget; QuestLog (UI-03) already shows everything.

---

## Existing Architecture Reference

### `QuestManager` (`quests/scripts/quest_manager.gd`) — DO NOT modify the public API
- Auto-loads quests from any subfolder of `res://quests/data/` (recursive `_scan_dir`). Just drop new `.tres` in `quests/data/daily/`, `quests/data/progress/`, `quests/data/discovery/`.
- Already emits: `quest_started`, `quest_progress_updated`, `quest_completed`, `quest_failed`, `quest_rewards_granted`.
- Already routes events: `&"item_collected"`, `&"enemy_killed"`, `&"day_survived"`, `&"plant_bred"`, `&"plant_discovered"`, `&"weapon_crafted"`.
- `report_event(event_id, amount, context)` is the entry point. Add new emitters; do not duplicate the dispatcher.
- TODO stubs already left at lines ~295 (`reward_unlock_flags`) and ~315 (`daily reroll`). Fill them in.

### `QuestData` (`quests/data/quest_data.gd`)
- Has `Type` enum: `DAILY=0, PROGRESS=1, DISCOVERY=2, STORY=3`. Use these for `quest_type`.
- `reward_items: Dictionary` (item_id → amount), `reward_weapons: Array[String]`, `reward_unlock_flags: Array[String]`.
- `time_limit_days` already enforced by `_check_time_limits()` on day transition.

### `QuestObjective` (`quests/data/quest_objective.gd`)
- Fields: `objective_id`, `description`, `event_id`, `target_count`, `filter:Dictionary`.
- Filter values are stringified before compare — keep filter values as strings.

### Save (`save/scripts/save_manager.gd`)
- Current `SCHEMA_VERSION = 7` (per recent loadout work). Bump to **8** for this prompt.
- Add `quest_daily_state` and `unlock_flags` sections. Migration v7→v8 inserts empty defaults.

### UI-03 (`ui/quests/quest_log_screen.gd`)
- Already renders DAILY/PROGRESS/DISCOVERY/STORY badges and time-limit countdown. No edit needed.

### `CodexManager` (`ui/codex/codex_manager.gd`)
- Already auto-discovers plants on `BreedingManager.breed_succeeded` and seed pickup. Discovery Quests just observe — no Codex code change.

### `CraftingManager` (`crafting/scripts/crafting_manager.gd`)
- Owns `owned_weapons:Dictionary`. For recipe gating via flags, see §Recipe gating below.

---

## File Plan

### New Files

#### Daily Quests
- `quests/data/daily/daily_petal_collect.tres` — collect 10 Petal Shard; reward verdant_sap×3.
- `quests/data/daily/daily_verdant_collect.tres` — collect 5 Verdant Sap; reward petal_shard×8.
- `quests/data/daily/daily_kill_shadowlings.tres` — kill 5 shadowlings (filter `enemy_type=shadowling`); reward moonspore×2. `time_limit_days=1`.
- `quests/data/daily/daily_kill_voidrunners.tres` — kill 4 voidrunners (filter `enemy_type=voidrunner`); reward moonspore×2.
- `quests/data/daily/daily_kill_stonehusks.tres` — kill 2 stonehusks; reward shadow_resin×1.
- `quests/data/daily/daily_kill_phantom_weavers.tres` — kill 2 phantom weavers; reward shadow_resin×1.
- `quests/data/daily/daily_breed_any.tres` — succeed at 1 breeding combo; reward kunyit_seed×1.
- `quests/data/daily/daily_craft_weapon.tres` — craft 1 weapon (event `weapon_crafted`); reward verdant_sap×4.

All `auto_start=false`, `time_limit_days=1`, `quest_type=0`.

#### Progress Quests
- `quests/data/progress/progress_survive_5_days.tres` — `day_survived×5`; reward `aether_bloom×1`. `auto_start=true`.
- `quests/data/progress/progress_survive_10_days.tres` — `day_survived×10`; reward `aether_bloom×2`, flag `progress_milestone_10`.
- `quests/data/progress/progress_kill_50_enemies.tres` — `enemy_killed×50`; reward `dianthus_pollen×1`.
- `quests/data/progress/progress_craft_3_weapons.tres` — `weapon_crafted×3`; reward flag `recipe_unlock_void_grenade` (if you adopt the flag-gating; otherwise `aether_bloom×1`).
- `quests/data/progress/progress_collect_50_shards.tres` — `item_collected×50` (filter `item_id=petal_shard`); reward `kecombrang_seed×1`.

#### Discovery Quests
- `quests/data/discovery/discovery_first_breed.tres` — `plant_bred×1`; reward flag `recipe_crystal_lash`.
- `quests/data/discovery/discovery_5_combos.tres` — `combo_attempted×5`; reward `aether_bloom×1`.
- `quests/data/discovery/discovery_all_base_plants.tres` — `plant_discovered×7`; reward `dianthus_pollen×1`, flag `unlock_garden_expansion_tier1`.
- `quests/data/discovery/discovery_all_hybrids.tres` — `plant_discovered×11`; reward `aether_bloom×3`, flag `discovery_complete` (END-03 hook — TODO comment in script).
- `quests/data/discovery/discovery_breed_bunga_api.tres` — `plant_bred×1` filtered `plant_id=bunga_api`; reward `kunyit_seed×2`.

#### Code
- `quests/scripts/daily_quest_roller.gd` — autoload `DailyQuestRoller` (or methods on `QuestManager` — see §Architecture decision). Holds `current_daily_ids`, `last_rolled_day`. API: `roll_for_day(day:int)`, `force_reroll()`, `serialize()`, `deserialize()`.
- `shared/autoloads/unlock_flags.gd` — autoload `UnlockFlags`. API: `set_flag(name:String)`, `has_flag(name:String)->bool`, `clear_flag(name:String)`, `serialize()->Dictionary`, `deserialize(d:Dictionary)`. Signal `flag_set(name)`.

### Modified Files
- `quests/scripts/quest_manager.gd`
  - Replace daily-reroll TODO in `_on_phase_changed` with call into `DailyQuestRoller.roll_for_day(DayNightCycle.day_count)` followed by failing-out expired daily quests (any active quest with `quest_type==DAILY` and `started_day<day_count` → `fail_quest(id, "expired")`).
  - Replace `reward_unlock_flags` TODO in `_grant_rewards` with loop calling `UnlockFlags.set_flag(flag)`.
  - On `_on_breed_succeeded`, also emit a `&"combo_attempted"` event with `{success:true}` context. Add a hook for failed breeds — see `BreedingManager` change below. (If `BreedingManager` emits no fail signal yet, add `breed_failed_attempted` or reuse `breed_failed`.)
  - Optional getter: `get_current_daily_ids()->Array[StringName]` (delegates to roller).
- `crafting/breeding/breeding_manager.gd` (or wherever `breed()` lives)
  - On breed attempt (success or fail), emit a new signal `combo_attempted(combo_id, success)` AND have `QuestManager` listen → `report_event(&"combo_attempted", 1, {"success":str(success)})`.
- `save/scripts/save_manager.gd`
  - Bump `SCHEMA_VERSION` to **8**.
  - `_gather_state` adds: `state["quest_daily"] = DailyQuestRoller.serialize()`, `state["unlock_flags"] = UnlockFlags.serialize()`.
  - `_apply_state` deserializes both.
  - `_migrate` v7→v8: `data["quest_daily"] = {"last_rolled_day":0,"current_daily_ids":[]}`, `data["unlock_flags"] = {}`.
- `project.godot`
  - Register autoloads `DailyQuestRoller` and `UnlockFlags` after `QuestManager`.
  - Order: `… QuestManager → UnlockFlags → DailyQuestRoller …` (roller queries QuestManager registry).
- `player/scripts/player_controller.gd`
  - `Shift+Q` → `DailyQuestRoller.force_reroll()` (debug only; bypass day check).
  - `Ctrl+Shift+Q` → print active/completed/failed quest summary.
- `docs/design/PERSON_TASKS.md`
  - Add Shift+Q / Ctrl+Shift+Q rows.
  - Mark QUEST-02 / QUEST-03 / QUEST-04 with ✅.
- `docs/design/TASK_BREAKDOWN.md`
  - QUEST-02, QUEST-03, QUEST-04 → Status `Done`.

---

## Architecture Decisions

### Roller as autoload vs. method on QuestManager
Use a separate autoload `DailyQuestRoller`. Reasons:
- QuestManager remains generic — knows nothing about daily-specific state.
- Save/migration cleaner: `quest_daily` section is independent of `quest` section.

### Daily roll algorithm
```gdscript
func roll_for_day(day: int) -> void:
    if day == last_rolled_day:
        return
    # 1. fail-out previous daily quests as "expired"
    for id in QuestManager.get_active_quest_ids():
        if QuestManager.get_quest_type(id) == QuestData.Type.DAILY:
            QuestManager.fail_quest(id, "expired")
    # 2. pick N from pool (default 2)
    var pool := QuestManager.get_quests_by_type(QuestData.Type.DAILY)
    pool.shuffle()
    current_daily_ids = []
    for q in pool.slice(0, daily_count_per_day):
        QuestManager.start_quest(q.quest_id)
        current_daily_ids.append(q.quest_id)
    last_rolled_day = day
```

Add helpers `get_active_quest_ids()`, `get_quest_type(id)`, `get_quests_by_type(type)` to `QuestManager` (read-only, do not change existing methods).

### "Expired" daily quests should NOT pollute the Failed tab
UI-03 reads `get_failed_quests()`. Either:
- (a) skip emitting `quest_failed` for reason `"expired"` — silent drop into a separate `_expired` dict, OR
- (b) allow it but UI-03 hides daily expired entries.

**Choose (a)**: add `silent_drop_quest(id)` to QuestManager (clears from `_active`, no signal). Use it for `expired` daily case. Keep `fail_quest` for true failures (story timeouts only).

### UnlockFlags
Plain dict autoload. No signal needed unless you want UI to react. For now, `flag_set(name)` signal is enough; `CraftingManager.can_craft` reads `UnlockFlags.has_flag(flag)`.

### Recipe gating (minimal)
Add optional field to `RecipeDatabase` recipes:
```gdscript
"void_grenade": {
    "display_name": "Void Grenade",
    "materials": {...},
    "is_upgrade": true,
    "upgrade_base": "spore_bomb",
    "required_flag": "recipe_void_grenade",  # NEW, optional
}
```
`CraftingManager.can_craft(weapon_id)` returns false if `required_flag != "" and not UnlockFlags.has_flag(required_flag)`. Update `_craft_fail_reason` to return `"locked"` in that case. **Do not gate any recipes that are already accessible by default — only the upgrade tier and 1–2 hybrids.** Default-gate only `void_grenade`, `crystal_lash`, `iron_bloom_shield`, `blazeblade` if you want a full unlock loop. Or leave `required_flag=""` for all in this prompt and only wire the mechanism — let later content tasks set flags.

---

## Implementation Order

1. **UnlockFlags autoload** — smallest surface, used by step 4.
2. **QuestManager helpers** — `get_active_quest_ids`, `get_quest_type`, `get_quests_by_type`, `silent_drop_quest`. Keep existing API untouched.
3. **DailyQuestRoller autoload** — implement roll, expire-fail, serialize. Wire into `QuestManager._on_phase_changed`.
4. **`reward_unlock_flags` processing** in `_grant_rewards` — call `UnlockFlags.set_flag` for each.
5. **`combo_attempted` event** — add signal to `BreedingManager.breed()`, route via `QuestManager._on_combo_attempted`.
6. **Quest .tres data files** — create the 8 daily, 5 progress, 5 discovery files. Verify they load via `QuestManager._scan_dir` log.
7. **Recipe gating field** (optional minimal) — extend `RecipeDatabase` schema with optional `required_flag`, gate `CraftingManager.can_craft`.
8. **Save migration v7→v8** — add fields, gather/apply, migrate.
9. **Debug keys + Person/Task doc updates**.

---

## Acceptance Criteria

### QUEST-02 — Daily Quests
- New game starts: on first DAY phase tick, 2 daily quests are active in the QuestLog. Console logs show `[QuestManager] Started: daily_*`.
- Day rolls over (e.g., F4 advance): unfinished daily quests are silently dropped; new 2 are rolled. They do NOT appear in Failed tab.
- Completing a daily before the day ends grants its rewards via existing `_grant_rewards`.
- Save → close → load: same daily quests persist if same day; new roll only on actual day advance.
- `Shift+Q` forces a fresh reroll for testing.

### QUEST-03 — Progress Quests
- All 5 progress quests are active from new game (`auto_start=true`).
- `progress_survive_5_days` completes after 5 dawn transitions (existing `day_survived` event).
- `progress_kill_50_enemies` increments on any enemy death (filter-less on `enemy_killed`).
- `progress_milestone_10` flag is set in `UnlockFlags` after surviving day 10.
- Quests persist across save/load via existing `QuestManager.serialize`.

### QUEST-04 — Discovery Quests
- All 5 discovery quests active from new game.
- Picking up a new seed → `CodexManager.discover_plant` fires → `plant_discovered` event → progress increments on `discovery_all_base_plants`.
- Successful breed → `plant_bred` + `combo_attempted{success=true}` events fire → both `discovery_first_breed` and `discovery_5_combos` advance.
- Failed breed (insufficient mats etc.) still increments `combo_attempted` but NOT `plant_bred`.
- `discovery_first_breed` reward sets `recipe_crystal_lash` flag (verify via `print(UnlockFlags.has_flag("recipe_crystal_lash"))`).
- TODO comment for END-03 left on `discovery_all_hybrids.tres` script-side completion handler.

### Cross-Cutting
- Schema v7 saves migrate cleanly to v8 with default empty daily-state and flags. Print `[SaveManager] Migrated v7 → v8`.
- All "not in scope" lint warnings on new autoloads are pure IDE-lag (resolve after Godot project reload). Note this in the post-task memory record.
- No regression in UI-03 / UI-04 / Crafting screen.

---

## TODO Stubs to Leave (do not implement)

- `# TODO: WORLD-01..04` — `&"zone_unlocked"` emitter unimplemented; subscribe but expect zero events.
- `# TODO: END-03` — Discovery Ending trigger on `discovery_complete` flag.
- `# TODO: ACCESS-03` — tutorial-day quest gating.
- `# TODO: QUEST-05` — story-quest chain (separate prompt).
- `# TODO: QUEST-06` — pin / abandon / reroll-single-quest UI.

---

## Post-Task Memory Record (write after completion)

Capture in memory:
- New files (8 daily + 5 progress + 5 discovery `.tres`, `daily_quest_roller.gd`, `unlock_flags.gd`).
- Modified files (`quest_manager.gd`, `breeding_manager.gd`, `save_manager.gd`, `project.godot`, `player_controller.gd`, `recipe_database.gd` if gating adopted, `crafting_manager.gd`).
- Save schema bump v7 → v8 with migration details.
- Debug keys: `Shift+Q` reroll, `Ctrl+Shift+Q` summary print.
- New events: `&"combo_attempted"`. Subscribed-but-unemitted: `&"zone_unlocked"`.
- Confirmation of which recipes (if any) are flag-gated.

Mark QUEST-02, QUEST-03, QUEST-04 → Done in `TASK_BREAKDOWN.md`. Update `PERSON_TASKS.md` debug key table and quest section.
