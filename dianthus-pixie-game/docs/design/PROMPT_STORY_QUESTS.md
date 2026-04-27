# PROMPT — QUEST-05: Story Quests

**Task ID:** QUEST-05 (Story Quests)
**Category:** Quest System
**Priority:** High
**Dependencies:** QUEST-01 (Done), QUEST-02/03/04 (Done), DIALOG-01 (In Progress), WORLD-02 (Not Started — Ruins of Veld), DIFF-03 (Not Started — Voidlord), ENEMY-05 (Not Started — Devourer)
**GDD Reference:** §5.1 (Lose Conditions / alternative ending), §8.1 (Devourer), §8.2 (Voidlord Night 21), §10.1 (Ruins of Veld), §16 (Quest System table — Story Quest row)

---

## Goal

Author and wire the **full story-quest chain** described in GDD §16:

> *"Selidiki Ruins of Veld; Hadapi Voidlord"* → culminating in **The Devourer** on the final story night.

This task delivers the **data + glue + flag plumbing** for the chain — not the underlying content (the Ruins zone, Voidlord boss, and Devourer boss are separate tasks and may be stubbed). The chain must:

- Auto-progress via `next_quest_id` (currently a defined-but-unused field on `QuestData`).
- Carry time limits on critical quests; **failure of a critical story quest must NOT trigger Game Over** — it must mark a pending *alternative* ending and let the run continue (per GDD §5.1).
- Drive endings (END-01 True Ending; future END-02/03/04 read the same flags) via `UnlockFlags`.
- Surface in the existing `QuestLog` UI (UI-03 — already supports the STORY badge and `time_limit_days` countdown — verify, do not modify).

No HUD changes. No new UI screens. No Dialogic timeline authoring (only references — leave `.dtl` paths pointing at `res://addons/dialogic/timelines/story_<n>.dtl` even though those files don't exist yet; QuestManager already null-guards a missing Dialogic singleton).

---

## Scope

### In Scope
1. **Story quest chain authoring (7 quests)** under `quests/data/story/`. See §Quest Chain below.
2. **`next_quest_id` chain progression** — extend `QuestManager.complete_quest()` to auto-start `q.next_quest_id` if non-empty. Pure 2-line change.
3. **Story-quest auto-start trigger** — first quest in chain (`story_01_whispers`) auto-starts on **Day 2 DAY phase** (gives the player one day of pure tutorial/exploration first). Implement as `_on_phase_changed` branch reading a new `story_chain_started` flag from `UnlockFlags`.
4. **Critical-quest failure → alternative ending** — extend `QuestManager.fail_quest(id, reason)` so that for `quest_type==STORY` failures with reason `"time_limit"`:
   - The quest's `reward_unlock_flags` are **still applied**, but only the entries that begin with `alt_ending_` (so a failed quest can still set its own bad-ending flag).
   - A new optional field `failure_unlock_flags: Array[String]` on `QuestData` is used for the bad-ending flag set on failure (cleaner than overloading `reward_unlock_flags`). See §QuestData extension.
   - The chain continues by jumping to `failure_next_quest_id` if non-empty (also new field), instead of `next_quest_id`. Allows branching to a "lost timeline" path.
   - **No Game Over** is triggered. The Dianthus Core HP zero path (CORE-04) remains the only Game Over trigger.
5. **Ending flag set** — define canonical flags in a new `quests/data/story/ending_flags.gd` (plain `class_name StoryEndingFlags`, static const set):
   - `flag_story_complete` — Devourer defeated through the canonical path.
   - `flag_story_failed_ruins` — Ruins quest failed by time-limit.
   - `flag_story_failed_voidlord` — Voidlord quest failed by time-limit.
   - `flag_story_devourer_summoned` — Devourer phase reached (regardless of outcome).
   - `flag_story_devourer_defeated` — Devourer killed (END-01 True Ending gate).
   - These are just `const` strings, not new logic.
6. **Story-quest event vocabulary additions** — add 3 new events emitted from existing systems:
   - `&"zone_entered"` — emitted from a new lightweight `ZoneTracker` autoload (or a single hook in `meadow_edge.tscn`/transition system) with `{zone_id:String}`. Required for "Travel to the Ruins" objective. Where the actual zone scenes don't exist yet, leave a `# TODO: WORLD-02` and have the player_controller debug key (`Shift+5`) emit it instead.
   - `&"voidlord_defeated"` — emitted by Voidlord on death. Stub: a fake event from `Shift+6` debug key (since DIFF-03 is Not Started).
   - `&"devourer_defeated"` — same. Stub from `Shift+7`.
7. **Voidlord/Devourer encounter triggers** — story-quest `voidlord_defeated`/`devourer_defeated` objectives must work even though the bosses themselves are stubs. The debug keys above are the test surface. **Do NOT spawn the actual bosses in this prompt.** Leave `# TODO: DIFF-03` / `# TODO: ENEMY-05` stubs.
8. **Save migration v8 → v9** — only if `UnlockFlags` doesn't already serialize the new flag names (it should, since they're plain strings). Bump only if you add `failure_unlock_flags` deserialization to `QuestData` and need a migration of any saved quest snapshot — likely **no bump needed** (the field is on the resource, not on the saved state). Verify with the existing `_active`/`_completed`/`_failed` schema.
9. **Debug keys**:
   - `Shift+5` → emit `zone_entered{zone_id:"ruins_of_veld"}`.
   - `Shift+6` → emit `voidlord_defeated`.
   - `Shift+7` → emit `devourer_defeated`.
   - `Ctrl+Shift+5` → force-start `story_01_whispers` (for testing without waiting for Day 2).
   - `Ctrl+Shift+F` → force-fail current active story quest with `time_limit` (tests the alt-ending branch).
10. **Doc updates**:
    - `docs/design/PERSON_TASKS.md` — debug key rows added; mark QUEST-05 ✅.
    - `docs/design/TASK_BREAKDOWN.md` — QUEST-05 → `Done`.

### Out of Scope
- Authoring `.dtl` Dialogic timelines for story dialog (DIALOG-01 ongoing).
- Implementing Ruins of Veld zone scene (WORLD-02).
- Implementing Voidlord boss (DIFF-03).
- Implementing The Devourer boss (ENEMY-05).
- END-01..04 trigger logic / ending screens — leave `# TODO: END-01` etc. where the flags are read.
- Time-of-day-specific (vs day-count) time limits.
- Quest abandon / pin / map-marker UI.
- Dialog branching variables in Dialogic (just use one timeline per `dialogic_timeline_on_complete`).
- Localization of the new strings.

---

## Existing Architecture Reference

### `QuestData` (`quests/data/quest_data.gd`)
Already has `next_quest_id: StringName` (defined but unused). Has `reward_unlock_flags`, `time_limit_days`, `dialogic_timeline_on_complete/on_fail`. Add **two new optional fields** in this prompt — see §QuestData extension. Resource format remains backward-compatible.

### `QuestManager` (`quests/scripts/quest_manager.gd`)
- `_check_time_limits()` already fails quests with `time_limit_days > 0` by calling `fail_quest(id, "time_limit")`. **DAILY quests are skipped** (line ~357). STORY quests are NOT skipped — that path is exactly where the alt-ending branch hooks.
- `complete_quest()` already plays `dialogic_timeline_on_complete`. Append `next_quest_id` chain logic at the end of the function.
- `fail_quest()` already plays `dialogic_timeline_on_fail`. Branch at the top of the function: if `q.quest_type == STORY and reason == "time_limit"`, run alt-ending logic instead of (or in addition to) the normal fail flow.
- `report_event()` already routes events. Just add three new event-IDs at call sites (no dispatcher change).

### `UnlockFlags` (`shared/autoloads/unlock_flags.gd`)
Already serialized via `SaveManager` v8. `set_flag(name)/has_flag(name)` is the entire surface used here. No code change.

### `DayNightCycle`
`day_count`, `phase_changed`, `is_night()`. Story quest auto-start uses `phase=="DAY"` + `day_count==2` (or `>=2 and not has_flag("story_chain_started")`).

### `Dialogic`
Optional — already null-guarded in `QuestManager._connect_dialogic()` and `complete_quest()/fail_quest()`. Story `.dtl` paths can be set on the quest resources without those files existing yet; `Dialogic.start(path)` will be skipped gracefully (verify the existing null-guard, push_warning is fine).

---

## Quest Chain

Seven `.tres` files under `quests/data/story/`. `quest_type=3` (STORY) for all. `auto_start=false` for all (chain is started programmatically — see §Story-quest auto-start trigger). `display_name` and `description` are user-facing; keep in English consistent with existing quests.

| # | quest_id | display_name | objective(s) | time_limit_days | next_quest_id | failure_next_quest_id | reward / failure reward |
|---|----------|--------------|--------------|------------------|---------------|------------------------|--------------------------|
| 1 | `story_01_whispers` | "Whispers of the Void" | Survive 2 nights (`day_survived×2`) | 0 | `story_02_omen` | — | reward: `aether_bloom×1`, flag `flag_story_chain_started` |
| 2 | `story_02_omen` | "An Ill Omen" | Defeat 10 enemies of any type during night (`enemy_killed×10`) | 3 | `story_03_journey` | `story_alt_lost` | reward: `moonspore×3`; failure: flag `flag_story_failed_omen` |
| 3 | `story_03_journey` | "The Long Road" | Travel to the Ruins of Veld (`zone_entered` filter `zone_id=ruins_of_veld`) | 4 | `story_04_ruins` | `story_alt_lost` | reward: flag `unlock_zone_ruins`; failure: flag `flag_story_failed_ruins` |
| 4 | `story_04_ruins` | "Echoes Beneath the Stones" | Collect 3 Shadow Resin in the Ruins (`item_collected×3` filter `item_id=shadow_resin`) **AND** defeat 5 Phantom Weavers (`enemy_killed×5` filter `enemy_type=phantom_weaver`) | 5 | `story_05_voidlord` | `story_alt_lost` | reward: flag `unlock_recipe_void_grenade`; failure: flag `flag_story_failed_ruins` |
| 5 | `story_05_voidlord` | "The Voidlord Stirs" | Defeat the Voidlord (`voidlord_defeated×1`) — fires Night 21 per GDD §8.2 | 3 | `story_06_pollen` | `story_alt_voidlord_loss` | reward: flag `flag_story_voidlord_slain`; failure: flag `flag_story_failed_voidlord` |
| 6 | `story_06_pollen` | "Petals of Power" | Acquire Dianthus Pollen (`item_collected×1` filter `item_id=dianthus_pollen`) **AND** craft a weapon upgraded with it (`weapon_crafted` filter `weapon_id=blazeblade` — placeholder, swap when Pollen-tier weapons land) | 0 | `story_07_devourer` | — | reward: flag `unlock_zone_core_sanctum` |
| 7 | `story_07_devourer` | "The Final Bloom" | Defeat the Devourer (`devourer_defeated×1`) | 0 | `""` | `story_alt_devourer_loss` | reward: flag `flag_story_devourer_defeated`; failure: flag `flag_story_devourer_summoned` (sets ending state to "Survival") |

**Branch quests** (also in `quests/data/story/`, `auto_start=false`, `time_limit_days=0`, no further chaining):

- `story_alt_lost.tres` — "A Path Forsaken" — single objective `day_survived×5` from start. On complete: flag `flag_alt_ending_lost`. Description: "The chain is broken. Survive what comes." This is the dead-end alt-ending breadcrumb. `next_quest_id=&""`.
- `story_alt_voidlord_loss.tres` — "Shadow Triumphant" — `day_survived×3`. Flag `flag_alt_ending_shadow`.
- `story_alt_devourer_loss.tres` — "The Lingering Bloom" — `day_survived×3`. Flag `flag_alt_ending_lingering`.

> **Total:** 7 critical-path + 3 alt = **10 story `.tres` files**.

---

## QuestData extension

Add two optional fields (do **not** rename existing ones):

```gdscript
# quests/data/quest_data.gd — append at the bottom of the existing exports
@export var failure_unlock_flags: Array[String] = []   # set on time_limit failure (story quests)
@export var failure_next_quest_id: StringName = &""    # auto-start on time_limit failure (story quests only)
```

Existing `.tres` files (Daily/Progress/Discovery) will load with both fields defaulted to empty arrays/strings — fully backward compatible. **No save schema bump required** (these are resource-side fields, not save-state).

---

## Chain progression — `complete_quest()` change

Append after the existing Dialogic call:

```gdscript
# auto-start the next link in the chain
if q.next_quest_id != &"" and _registry.has(q.next_quest_id):
    start_quest(q.next_quest_id)
```

That's the entire chain mechanism. It also lets non-story chains (e.g. progress milestones) link if anyone wires `next_quest_id`.

---

## Failure → alt-ending branch — `fail_quest()` change

At the top of `fail_quest`, before `_active.erase(id)`:

```gdscript
var q: QuestData = _registry.get(id)
var is_story_timeout: bool = q != null \
    and q.quest_type == QuestData.Type.STORY \
    and reason == "time_limit"

if is_story_timeout:
    for flag: String in q.failure_unlock_flags:
        UnlockFlags.set_flag(flag)
    print("[QuestManager] Story-quest soft-fail: %s — alt-ending flags set" % id)
```

Then continue with the existing `_active.erase(id) … quest_failed.emit(id, reason)` flow so UI-03 still shows it in the Failed tab and `dialogic_timeline_on_fail` plays.

After the existing dialogic-on-fail call, append:

```gdscript
if is_story_timeout and q.failure_next_quest_id != &"" and _registry.has(q.failure_next_quest_id):
    start_quest(q.failure_next_quest_id)
```

> **Note:** Critical Story Quest failure does **not** call `core.die()` and does **not** open the Game Over screen. GDD §5.1 explicitly states alternative ending, not game over. Confirm by reading `core/dianthus_core/dianthus_core.gd` and `ui/screens/game_over_screen.gd` — neither is touched.

---

## Story-quest auto-start trigger

Inside `QuestManager._on_phase_changed(phase)`:

```gdscript
if phase == "DAY":
    DailyQuestRoller.roll_for_day(DayNightCycle.day_count)
    report_event(&"day_survived", 1, {"day": DayNightCycle.day_count})
    _check_time_limits()
    _maybe_start_story_chain()                    # NEW
```

```gdscript
func _maybe_start_story_chain() -> void:
    if UnlockFlags.has_flag("flag_story_chain_started"):
        return
    if DayNightCycle.day_count < 2:
        return
    if _registry.has(&"story_01_whispers"):
        start_quest(&"story_01_whispers")
```

The first quest's reward sets `flag_story_chain_started`, so this guard short-circuits forever after.

---

## Event emitter wiring

### `&"zone_entered"`

- Add a new tiny autoload `world/scripts/zone_tracker.gd`:

```gdscript
extends Node
signal zone_entered(zone_id: String)

func enter_zone(zone_id: String) -> void:
    zone_entered.emit(zone_id)
    QuestManager.report_event(&"zone_entered", 1, {"zone_id": zone_id})
```

Register in `project.godot` after `QuestManager`.

- For now, **only the player_controller debug key fires it** (Shift+5 → `ZoneTracker.enter_zone("ruins_of_veld")`). Leave `# TODO: WORLD-02 — call ZoneTracker.enter_zone() from each zone scene's _ready` in `zone_tracker.gd`.

### `&"voidlord_defeated"` / `&"devourer_defeated"`

- Add `_on_voidlord_defeated()` / `_on_devourer_defeated()` helpers on `QuestManager` that just call `report_event`.
- For now, **debug-only** triggers (Shift+6 / Shift+7). Leave `# TODO: DIFF-03` / `# TODO: ENEMY-05` stubs at the call sites.

---

## File Plan

### New Files
- `quests/data/story/story_01_whispers.tres`
- `quests/data/story/story_02_omen.tres`
- `quests/data/story/story_03_journey.tres`
- `quests/data/story/story_04_ruins.tres`
- `quests/data/story/story_05_voidlord.tres`
- `quests/data/story/story_06_pollen.tres`
- `quests/data/story/story_07_devourer.tres`
- `quests/data/story/story_alt_lost.tres`
- `quests/data/story/story_alt_voidlord_loss.tres`
- `quests/data/story/story_alt_devourer_loss.tres`
- `quests/data/story/ending_flags.gd` — `class_name StoryEndingFlags`, static const flag names (no logic).
- `world/scripts/zone_tracker.gd` — autoload `ZoneTracker`.

### Modified Files
- `quests/data/quest_data.gd` — add `failure_unlock_flags`, `failure_next_quest_id`.
- `quests/scripts/quest_manager.gd` — chain progression in `complete_quest`; alt-ending branch in `fail_quest`; `_maybe_start_story_chain()`; `_on_voidlord_defeated()`, `_on_devourer_defeated()` helpers.
- `project.godot` — register `ZoneTracker` autoload after `QuestManager`.
- `player/scripts/player_controller.gd` — debug keys Shift+5/6/7, Ctrl+Shift+5, Ctrl+Shift+F.
- `docs/design/PERSON_TASKS.md` — debug-key rows added; QUEST-05 ✅.
- `docs/design/TASK_BREAKDOWN.md` — QUEST-05 → Done.

### NOT Modified
- `save/scripts/save_manager.gd` — no schema bump.
- `ui/quests/quest_log_screen.gd` — already supports STORY badge + countdown.
- `ui/codex/*` — irrelevant.
- Any zone scenes — WORLD-02 deferred.
- `core/dianthus_core/*`, `ui/screens/game_over_screen.*` — alt-ending path is **not** game over.

---

## Implementation Order

1. **`QuestData` field extension** — add the two new fields, save Godot project, confirm existing `.tres` still loads.
2. **`StoryEndingFlags` constants file** — pure const strings.
3. **`QuestManager` chain + alt-ending edits** — both functions, plus `_maybe_start_story_chain()`. Verify existing tests pass (Daily/Progress/Discovery unaffected because their `next_quest_id` is empty and `failure_next_quest_id`/`failure_unlock_flags` default to empty).
4. **`ZoneTracker` autoload** — register, verify `report_event` reaches QuestManager.
5. **Author 10 story `.tres` files** — start with `story_01_whispers`, work down the table. Confirm each loads via `[QuestManager] Registry: N quests found.` log.
6. **Debug keys** — Shift+5/6/7, Ctrl+Shift+5, Ctrl+Shift+F.
7. **Doc updates** + memory record.

---

## Acceptance Criteria

### Chain progression
- New game → on Day 1 nothing story-related is active. On Day 2 DAY phase, console logs `[QuestManager] Started: story_01_whispers` and the QuestLog Active tab shows it under STORY badge.
- Survive 2 nights → `story_01_whispers` completes; `story_02_omen` auto-starts; `flag_story_chain_started` is set in `UnlockFlags`.
- Each subsequent quest in the table chain-starts on completion of its predecessor.
- Saving mid-chain and reloading restores the active story quest progress (existing `QuestManager.serialize()` round-trip).

### Time-limit failure (alt-ending)
- Activate `story_02_omen`, advance days past the 3-day limit without completing → quest moves to Failed tab with reason `time_limit`. `flag_story_failed_omen` is set in `UnlockFlags`. **Game does NOT show Game Over.** `story_alt_lost` auto-starts.
- `Ctrl+Shift+F` reproduces this for whichever story quest is active.

### Event triggers (stubs)
- `Shift+5` → `story_03_journey`'s `zone_entered{zone_id=ruins_of_veld}` objective increments to 1/1 → quest completes.
- `Shift+6` → `story_05_voidlord`'s `voidlord_defeated` objective satisfied.
- `Shift+7` → `story_07_devourer`'s objective satisfied; reward sets `flag_story_devourer_defeated`. Print confirms via `UnlockFlags.has_flag("flag_story_devourer_defeated") == true`.

### UI / data correctness
- UI-03 displays all active story quests with the STORY badge and the time-limit countdown when `time_limit_days > 0`. Compact rows in Failed tab show alt-ending fail entries.
- Existing Daily/Progress/Discovery `.tres` files still load and behave identically (the new optional fields default to empty).

### No regressions
- Save schema unchanged; v8 saves load cleanly.
- All existing debug keys (Shift+1/2/3, F1..F13, etc.) still work.
- `[QuestManager] Registry:` count increases by exactly 10.

---

## TODO Stubs to Leave (do not implement)

- `# TODO: WORLD-02` — real `ZoneTracker.enter_zone()` calls from Ruins zone scene.
- `# TODO: DIFF-03` — Voidlord boss spawn on Night 21; emit `voidlord_defeated` from its `_die()`.
- `# TODO: ENEMY-05` — Devourer spawn after `story_06_pollen` complete; emit `devourer_defeated` from its `_die()`.
- `# TODO: END-01` — read `flag_story_devourer_defeated` + Day≥30 → True Ending screen.
- `# TODO: END-02` — read `flag_story_devourer_summoned` + survived → Survival Ending.
- `# TODO: END-03` — Discovery Ending (already TODO from QUEST-04).
- `# TODO: DIALOG-01` — author `.dtl` timelines referenced by `dialogic_timeline_on_complete/on_fail`. Leave the strings on the `.tres` even though the timeline files don't yet exist.

---

## Post-Task Memory Record (write after completion)

Capture in memory:

- New files: 10 story `.tres` (7 chain + 3 alt), `story/ending_flags.gd`, `world/scripts/zone_tracker.gd`.
- Modified files: `quest_data.gd` (+2 fields), `quest_manager.gd` (chain + alt-ending branches), `project.godot` (ZoneTracker autoload), `player_controller.gd` (5 debug keys), `PERSON_TASKS.md`, `TASK_BREAKDOWN.md`.
- New events: `&"zone_entered"`, `&"voidlord_defeated"`, `&"devourer_defeated"` — currently emitted only via debug keys.
- New UnlockFlags namespace: `flag_story_*`, `flag_alt_ending_*`, `unlock_zone_*`, `unlock_recipe_*`.
- Save schema unchanged (no bump). Resource-level QuestData extension is backward compatible with existing `.tres`.
- Debug keys: Shift+5 / Shift+6 / Shift+7 / Ctrl+Shift+5 / Ctrl+Shift+F.
- Critical Story Quest failure path: alt-ending flag set + branch quest auto-started; **no Game Over** (per GDD §5.1).
- Lint note: `StoryEndingFlags` / `ZoneTracker` "not in scope" warnings will resolve after Godot project reload (same IDE-lag pattern as previous autoloads).

Mark **QUEST-05 → Done** in `TASK_BREAKDOWN.md`. Update `PERSON_TASKS.md` debug key table and add the QUEST-05 row to its quest section.
