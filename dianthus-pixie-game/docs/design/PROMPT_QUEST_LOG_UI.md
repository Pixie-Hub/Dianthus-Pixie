# PROMPT — UI-03: Quest Log Screen

**Task ID:** UI-03
**Category:** UI/HUD
**Priority:** High
**Dependencies:** QUEST-01 (Quest System Architecture — already Done)
**GDD Reference:** §11.2 — "Quest Log — menampilkan misi aktif dengan progress bar, dan tab terpisah untuk misi selesai"

---

## Goal

Implement a Quest Log screen that lists all active quests with per-objective progress bars, plus separate tabs for completed and failed quests. Toggled via the **Q** key (`quest_log_toggle` action — already bound by QUEST-01). Reads live data from the existing `QuestManager` autoload; no changes to quest data model required.

---

## Scope

### In Scope
1. **Quest Log UI screen** — `ui/quests/quest_log_screen.gd` + `.tscn`, CanvasLayer (layer 95).
2. **Three tabs** — Active / Completed / Failed (TabContainer or button bar).
3. **Active quest entries** — display name, type badge (Daily/Progress/Discovery/Story), description, list of objectives with `current/target` progress bars, time-limit countdown if `time_limit_days > 0`.
4. **Completed/Failed entries** — collapsed rows showing display name + completion/fail reason.
5. **Live refresh** — listen to `QuestManager` signals (`quest_started`, `quest_progress_updated`, `quest_completed`, `quest_failed`, `quest_rewards_granted`) and rebuild the list.
6. **Empty states** — "No active quests." / "No completed quests." / "No failed quests." labels.
7. **Toggle wiring** — replace the `print("TODO: UI-03")` stub in `player_controller.gd` with `find_child("QuestLogScreen", true, false).toggle()`.
8. **Scene instancing** — instance `QuestLogScreen` in `world/zones/meadow_edge/meadow_edge.tscn`.

### Out of Scope
- Quest reroll / abandon / pin actions (QUEST-02, QUEST-06).
- Reward preview UI beyond a simple "Rewards: petal_shard×5, verdant_sap×1" text line.
- Map markers or world-space waypoints.
- Quest sorting/filtering UI.
- Story-quest dialogue replay.
- Daily-quest cooldown timer (QUEST-02).

---

## Existing Architecture Reference

### QuestManager Autoload (`quests/scripts/quest_manager.gd`)
Already implemented. Use these public methods/signals — do **not** modify the manager:

**Signals**
- `quest_started(quest_id: StringName)`
- `quest_progress_updated(quest_id: StringName, objective_id: StringName, current: int, target: int)`
- `quest_completed(quest_id: StringName)`
- `quest_failed(quest_id: StringName, reason: String)`
- `quest_rewards_granted(quest_id: StringName, items: Dictionary, weapons: Array)`

**Methods**
- `get_active_quests() -> Array[QuestData]`
- `get_completed_quests() -> Array[QuestData]`
- `is_active(id) / is_completed(id)`
- `get_progress(id: StringName) -> Dictionary`
  Returns `{ objective_id: { "current": int, "target": int, "description": String } }` for the active quest. Use this to render objective rows.

**Internal (read-only access via getter — add a getter if needed)**
- `_active[id]["started_day"]` for time-limit countdown. If you need this for the UI, add a small public helper:
  ```gdscript
  func get_started_day(id: StringName) -> int:
      return int(_active.get(id, {}).get("started_day", 0))
  func get_failed_quests() -> Array[Dictionary]:
      var out: Array[Dictionary] = []
      for id: StringName in _failed:
          if _registry.has(id):
              out.append({"quest": _registry[id], "reason": _failed[id]})
      return out
  ```
  These are minimal additions (≤ 10 lines). Place them next to the existing `get_active_quests` / `get_completed_quests` block.

### QuestData (`quests/data/quest_data.gd`)
- `quest_id: StringName`, `display_name: String`, `description: String`
- `quest_type: Type` enum {DAILY, PROGRESS, DISCOVERY, STORY}
- `objectives: Array[QuestObjective]`
- `reward_items: Dictionary`, `reward_weapons: Array[String]`
- `time_limit_days: int` (0 = no limit)

### QuestObjective (`quests/data/quest_objective.gd`)
- `objective_id: StringName`, `description: String`, `target_count: int`

### DayNightCycle Autoload
- `DayNightCycle.day_count: int` — current day, used to compute `days_remaining = (started_day + time_limit_days) - day_count`.

### Existing UI Patterns (mirror these)
Use the same skeleton already established by `inventory_screen.gd`, `crafting_screen.gd`, `cross_breeding_screen.gd`, `codex_screen.gd`:

- `extends CanvasLayer`, `process_mode = Node.PROCESS_MODE_ALWAYS`.
- Toggle via `_unhandled_input` listening for `quest_log_toggle`, then `get_viewport().set_input_as_handled()`.
- Pauses tree on open: `get_tree().paused = visible`.
- Overlay: dark `ColorRect` + centered `Panel`.
- Build rows dynamically inside a `VBoxContainer` (`%QuestList`) marked unique.
- All node references via unique-name (`%Foo`) syntax.
- Existing CanvasLayer slots in use: 90 (Inventory), 91 (Crafting), 92 (CrossBreeding), 93 (Codex), 94 (Loadout). **Use layer 95 for Quest Log.**

### Input Action
`quest_log_toggle` is already mapped to **Q** (physical_keycode=81) in `project.godot` per QUEST-01. Do not add a new action — just consume it.

The current `player_controller.gd` handler for `quest_log_toggle` is:
```gdscript
elif event.is_action_pressed(&"quest_log_toggle"):
    print("TODO: UI-03 — open quest log screen")
    get_viewport().set_input_as_handled()
```
Replace this with a call to the new screen. Pattern (matches Codex toggle):
```gdscript
elif event.is_action_pressed(&"quest_log_toggle"):
    var screen: Node = get_tree().current_scene.find_child("QuestLogScreen", true, false)
    if screen != null and screen.has_method("toggle"):
        screen.toggle()
    get_viewport().set_input_as_handled()
```

---

## Implementation Plan

### 1. Quest Log Screen — `ui/quests/quest_log_screen.gd` + `quest_log_screen.tscn`

**Layout (640×360 viewport):**

```
CanvasLayer (layer=95, PROCESS_MODE_ALWAYS, visible=false at start)
└── Overlay (ColorRect, Color(0,0,0,0.65), full rect)
└── Panel (centered ~480×300)
    └── MarginContainer (margins=8)
        └── VBoxContainer
            ├── TitleLabel — "QUEST LOG"
            ├── TabBar (HBoxContainer)
            │   ├── ActiveTabBtn   — "Active (N)"
            │   ├── CompletedTabBtn — "Completed (N)"
            │   └── FailedTabBtn   — "Failed (N)"
            ├── ScrollContainer (vertical, expand_v)
            │   └── %QuestList (VBoxContainer, unique_name)
            │       └── (rows built dynamically)
            └── CloseHint — "Press Q to close"
```

**Active quest row (PanelContainer):**
```
PanelContainer (rounded StyleBoxFlat, padding 6)
└── VBoxContainer
    ├── HBoxContainer (header)
    │   ├── NameLabel — bold, e.g. "Daily Petals"
    │   ├── TypeBadge — Label "[DAILY]" with colored modulate
    │   └── TimerLabel — "2 days left" or hidden
    ├── DescLabel (autowrap_mode=WORD_SMART)
    ├── VBoxContainer ObjectiveList
    │   └── per objective: VBox
    │       ├── HBox: ObjectiveText + "(c / t)"
    │       └── ProgressBar (min=0, max=target, value=current)
    └── RewardLabel — "Rewards: petal_shard×5, verdant_sap×1" (omit if empty)
```

**Completed / Failed rows (compact PanelContainer):**
```
PanelContainer
└── HBoxContainer
    ├── NameLabel — "[Quest Name]"
    └── StatusLabel — "✓ Completed" / "✗ Failed: <reason>"
```

**Type badge color map:**
```gdscript
const TYPE_COLOR := {
    QuestData.Type.DAILY:     Color(0.95, 0.85, 0.3),
    QuestData.Type.PROGRESS:  Color(0.4, 0.75, 1.0),
    QuestData.Type.DISCOVERY: Color(0.6, 1.0, 0.55),
    QuestData.Type.STORY:     Color(1.0, 0.6, 0.85),
}
```

**Public API:**
```gdscript
func open() -> void
func close() -> void
func toggle() -> void
```

**Behavior:**
- Default `_current_tab := "active"`. Tab buttons set `_current_tab` and call `_refresh()`.
- `_refresh()` clears `%QuestList.get_children()` (queue_free), then dispatches to `_build_active()`, `_build_completed()`, or `_build_failed()`.
- Connect on `_ready()`:
  - `QuestManager.quest_started.connect(_refresh.unbind(1))`
  - `QuestManager.quest_progress_updated.connect(_on_progress_updated)`
  - `QuestManager.quest_completed.connect(_refresh.unbind(1))`
  - `QuestManager.quest_failed.connect(_refresh.unbind(2))`
  - `QuestManager.quest_rewards_granted.connect(_refresh.unbind(3))`
- `_on_progress_updated(quest_id, objective_id, current, target)` may either rebuild or, as a small optimization, look up the cached `ProgressBar` for that objective and update `value` + the count label in place. A full `_refresh()` is acceptable for v1.
- `_unhandled_input`: if `event.is_action_pressed("quest_log_toggle")` → `toggle()` and consume.
- `open()` sets `visible = true`, `get_tree().paused = true`, calls `_refresh()`, and updates tab counts.
- `close()` sets `visible = false`, `get_tree().paused = false`.
- Tab buttons display live counts: `"Active (%d)" % QuestManager.get_active_quests().size()`, etc.
- If a tab list is empty, render a single grey Label "No quests." centered.
- Selected tab: bright modulate or differentiated StyleBoxFlat; non-selected: dimmed (Color(1,1,1,0.55)).

### 2. QuestManager additions (minimal)

Add to `quests/scripts/quest_manager.gd` (next to other public getters):

```gdscript
func get_started_day(id: StringName) -> int:
    return int(_active.get(id, {}).get("started_day", 0))


func get_failed_quests() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for id: StringName in _failed:
        if _registry.has(id):
            result.append({"quest": _registry[id], "reason": _failed[id]})
    return result
```

These are read-only helpers — no schema or signal changes.

### 3. Player input wiring — `player/scripts/player_controller.gd`

Replace the existing `quest_log_toggle` placeholder branch with a call to `QuestLogScreen.toggle()` via `find_child` on the current scene (mirrors Codex / Inventory / Loadout toggle pattern).

### 4. Scene instancing — `world/zones/meadow_edge/meadow_edge.tscn`

Add a new `ext_resource` for `quest_log_screen.tscn` and instance `QuestLogScreen` as a sibling to the other UI screens (after `LoadoutScreen`). Keep it inside the scene root, not inside `YSortLayer` (CanvasLayer-based UI).

### 5. Tabs & filtering details

Tab order (left-to-right): Active, Completed, Failed.

Active quests sorted: STORY first, then DAILY (with countdowns), then PROGRESS, then DISCOVERY (stable order from `get_active_quests()` is fine for v1).

Completed list: most-recent-first not required — natural dict order acceptable.

### 6. Time limit countdown

For each active quest with `q.time_limit_days > 0`:
```gdscript
var started: int = QuestManager.get_started_day(q.quest_id)
var due_day: int = started + q.time_limit_days
var remaining: int = max(0, due_day - DayNightCycle.day_count)
timer_label.text = "%d day%s left" % [remaining, "" if remaining == 1 else "s"]
timer_label.modulate = Color(1, 0.4, 0.4) if remaining <= 1 else Color(1, 1, 1)
```
If `time_limit_days <= 0`, hide the timer label.

### 7. Reward summary line

Compose `"Rewards: %s" % parts.join(", ")` where parts are `"%s×%d" % [item_id, amount]` for each entry in `q.reward_items`, plus `"+%s" % weapon_id` for each entry in `q.reward_weapons`. Skip the label entirely when both collections are empty.

---

## Files to Create

| File | Purpose |
|------|---------|
| `ui/quests/quest_log_screen.gd` | Quest Log UI logic (tabs, dynamic rows, signal-driven refresh) |
| `ui/quests/quest_log_screen.tscn` | Quest Log UI scene (CanvasLayer layer=95) |

## Files to Modify

| File | Change |
|------|--------|
| `quests/scripts/quest_manager.gd` | Add `get_started_day()` and `get_failed_quests()` read-only helpers |
| `player/scripts/player_controller.gd` | Replace `TODO: UI-03` print with `QuestLogScreen.toggle()` call |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance `QuestLogScreen` after `LoadoutScreen` |
| `docs/design/PERSON_TASKS.md` | Update Q key row (toggles Quest Log instead of "TODO") |
| `docs/design/TASK_BREAKDOWN.md` | UI-03 status → Done |

**Save schema:** No bump. Quest persistence is already at v6 from QUEST-01.

---

## Acceptance Criteria

1. Pressing **Q** opens the Quest Log; pressing **Q** again closes it. The game pauses while open.
2. The **Active** tab lists every quest from `QuestManager.get_active_quests()` with display name, type badge, description, and a `ProgressBar` per objective showing `current / target`.
3. Quests with `time_limit_days > 0` show "N days left"; the label turns red when `remaining ≤ 1`.
4. Quests with rewards show a "Rewards: ..." line summarising items and weapons.
5. The **Completed** tab lists every quest from `get_completed_quests()` with a "✓ Completed" tag.
6. The **Failed** tab lists every quest from `get_failed_quests()` with the stored fail reason.
7. Tab buttons display live counts and visually indicate the selected tab.
8. The list refreshes in real time when `quest_started`, `quest_progress_updated`, `quest_completed`, `quest_failed`, or `quest_rewards_granted` fire (verifiable via `Shift+Alt+K` debug key which force-completes the first active quest).
9. The `demo_daily_petals` auto-start quest appears in the Active tab on a fresh game; its progress updates as petal_shards are picked up; on completion it moves to Completed and the verdant_sap reward is granted (already wired in QuestManager).
10. Empty tabs show a single "No quests." placeholder.
11. No regressions: Inventory (I), Crafting (C/E), Cross-Breeding (B), Codex (J), Loadout (L), Plant Placement (P) toggles still work; toggling Quest Log while another screen is open is allowed (each manages its own pause state — match existing behavior).

---

## Test Procedure

1. New game → verify Active tab shows "Daily Petals (5/5 petal_shard)" with a 0/5 progress bar.
2. `Shift+Insert` to grant items, walk into petal_shard pickups, watch progress bar tick up live.
3. On completion → quest disappears from Active, appears in Completed, verdant_sap added to inventory.
4. `Shift+Alt+K` → force-complete first active quest; verify list refresh.
5. Save → reload via main menu → quest log state persists (already covered by QUEST-01 v6 schema).
6. Toggle Q rapidly — no double-pause / stuck-paused state.
