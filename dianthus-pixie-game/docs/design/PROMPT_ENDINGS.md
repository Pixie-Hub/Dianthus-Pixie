# PROMPT — END-01 / END-02 / END-03: Ending System

**Task IDs:** END-01 (True Ending), END-02 (Survival Ending), END-03 (Discovery Ending)
**Category:** Core Mechanics
**Priority:** END-01 High, END-02/03 Medium
**Dependencies:** QUEST-04 (`discovery_complete` flag), QUEST-05 (story flags), DIFF-01 (day count)
**GDD Reference:** §5.2 Win Conditions

---

## Goal

Implement the three non-Endless win-condition endings that already have data hooks but no
trigger logic or outro screens. All three flow through a single shared resolution screen
template that swaps copy + accent color per ending. One ending per run, evaluated on
`night_survived`, on key flag changes, and on Devourer defeat.

| Ending | Trigger (per GDD §5.2) | Implementation Trigger |
|--------|------------------------|------------------------|
| END-01 True | Full Dianthus potential unlocked + Devourer defeated on Day 30+ | `flag_story_devourer_defeated` set AND `DayNightCycle.day_count >= 30` |
| END-02 Survival | Survive to Day 20 without unlocking full Dianthus | `night_survived` with `day_count >= 20` AND no `flag_story_complete` AND no `flag_story_devourer_defeated` |
| END-03 Discovery | Complete all Discovery Quests | `UnlockFlags.flag_set("discovery_complete")` |

---

## Scope

### In Scope
1. **`EndingManager` autoload** — single arbiter; evaluates all three ending conditions, picks the highest-priority one, fires it once per run, persists "seen" flags.
2. **`EndingScreen` reusable UI** — one scene, three configurable variants (title, subtitle, body, accent color, art swatch).
3. **Trigger hooks** — listen to `GameManager.night_survived`, `UnlockFlags.flag_set`, and `QuestManager._on_devourer_defeated()`'s flag. No edits to Devourer/QuestManager logic itself — purely listener-side.
4. **Ending priority resolution** — if multiple conditions met simultaneously: **True > Discovery > Survival**.
5. **One-shot per run** — a fired ending sets `flag_ending_seen_true/_survival/_discovery`. Don't re-fire after the screen closes.
6. **Endless unlock stub** — True Ending sets `unlock_endless_mode` flag (read by future END-04). Leave `# TODO: END-04` where the post-credits "Endless" button would live.
7. **Save/load integration** — schema bump; persist seen-ending flags through `UnlockFlags` (no new top-level state needed since flags already round-trip).
8. **Debug keys** — `Ctrl+1/2/3` force-trigger True/Survival/Discovery for testing.

### Out of Scope
- END-04 Endless Post-Game Mode (separate task; only stub the unlock flag).
- Dialogic outro timelines (leave `dialogic_timeline_outro` String fields blank or with `TODO: DIALOG-01`).
- Animated cinematic — the screen is a static styled panel, same visual language as `night_survived_screen` / `game_over_screen`.
- Credits roll (a `CreditsLabel` with a 4–6 line static credits block is fine — no scrolling).
- New Game+ flow (button on the screen routes to Main Menu only).
- Story branch alt-endings (`flag_alt_ending_lost/shadow/lingering`) — those already get handled inside their own follow-up story quests; do **not** wire them into `EndingManager` in this task. Leave `# TODO: END-ALT` near the resolver.

---

## Existing Architecture Reference

### Key existing pieces (do not duplicate)
- `shared/autoloads/unlock_flags.gd` — `UnlockFlags` autoload, `flag_set(flag_name)` signal, `set_flag/has_flag/serialize/deserialize`. Already round-trips through save.
- `quests/data/story/ending_flags.gd` — `class_name StoryEndingFlags` with all story flag constants. Add new constants here (don't create a parallel file).
- `shared/autoloads/game_manager.gd` — `night_survived(day)` signal, `GAME_OVER` state, `game_over_triggered`. Add a new `ending_triggered(ending_id)` signal here.
- `ui/screens/game_over_screen.gd/.tscn` — reference for the CanvasLayer pattern, dark overlay + centered VBox, Restart/Main Menu buttons. Layer 100 is taken; use **layer 101** for ending screen so it sits above everything including the night-survived screen.
- `ui/screens/night_survived_screen.gd` — reference for `night_survived` listener gating with `if GameManager.current_state == GameManager.GameState.GAME_OVER: return`.
- `quests/data/discovery/discovery_all_hybrids.tres` — already grants `reward_unlock_flags = ["discovery_complete"]`, so END-03 wiring is purely listener-side.
- `quests/data/story/story_07_devourer.tres` — already grants `reward_unlock_flags = ["flag_story_devourer_defeated", "flag_story_complete"]`.
- `save/scripts/save_manager.gd` — current `SCHEMA_VERSION = 8`. Bump to **9**. Migration is a no-op for endings (flags already covered) but version bump is required so old saves get any future ending-seen flags initialized clean.

### Existing TODO markers to clear
- `save/scripts/save_manager.gd:226` — `state["unlocks"] = []   # TODO (END-01, END-04)` → either remove the line or repurpose to mention only END-04.
- `# TODO: END-01` / `# TODO: END-02` / `# TODO: END-03` references in `PROMPT_STORY_QUESTS.md` and `PROMPT_QUEST_TYPES.md` (prompts only — no code edits needed; those prompt docs are reference material).

---

## Implementation Plan

### 1. Constants — extend `quests/data/story/ending_flags.gd`

Append to `StoryEndingFlags`:

```gdscript
# Ending-seen one-shot flags
const flag_ending_seen_true: String = "flag_ending_seen_true"
const flag_ending_seen_survival: String = "flag_ending_seen_survival"
const flag_ending_seen_discovery: String = "flag_ending_seen_discovery"

# Endless mode unlock (END-04 reads this)
const unlock_endless_mode: String = "unlock_endless_mode"

# Discovery quest completion flag (already used by discovery_all_hybrids.tres)
const flag_discovery_complete: String = "discovery_complete"
```

### 2. New autoload — `core/endings/ending_manager.gd`

```gdscript
extends Node

signal ending_triggered(ending_id: String)  # "true", "survival", "discovery"

const TRUE_ENDING_DAY_THRESHOLD: int = 30
const SURVIVAL_ENDING_DAY_THRESHOLD: int = 20

var _ending_fired: bool = false  # transient; reset on new run / scene load

func _ready() -> void:
    GameManager.night_survived.connect(_on_night_survived)
    UnlockFlags.flag_set.connect(_on_flag_set)

# Public force trigger (debug + tests)
func force_trigger(ending_id: String) -> void: ...

# --- Resolver ---
# Priority: true > discovery > survival.
# Returns "" if no ending qualifies.
func _resolve_ending() -> String:
    if UnlockFlags.has_flag(StoryEndingFlags.flag_ending_seen_true) \
            or UnlockFlags.has_flag(StoryEndingFlags.flag_ending_seen_discovery) \
            or UnlockFlags.has_flag(StoryEndingFlags.flag_ending_seen_survival):
        return ""  # already seen one this run
    if UnlockFlags.has_flag(StoryEndingFlags.flag_story_devourer_defeated) \
            and DayNightCycle.day_count >= TRUE_ENDING_DAY_THRESHOLD:
        return "true"
    if UnlockFlags.has_flag(StoryEndingFlags.flag_discovery_complete):
        return "discovery"
    if DayNightCycle.day_count >= SURVIVAL_ENDING_DAY_THRESHOLD \
            and not UnlockFlags.has_flag(StoryEndingFlags.flag_story_complete) \
            and not UnlockFlags.has_flag(StoryEndingFlags.flag_story_devourer_defeated):
        return "survival"
    return ""
    # TODO: END-ALT — alt-ending flags (flag_alt_ending_lost/shadow/lingering)
```

Triggering:
- `_on_night_survived(_day)` → `_try_fire()` (deferred so reward popup runs first).
- `_on_flag_set(flag_name)` → if flag is one of: `flag_story_devourer_defeated`, `flag_discovery_complete`, `flag_story_complete` → `_try_fire()`.
- `_try_fire()` checks `_ending_fired` and `GameManager.current_state != GAME_OVER`, calls `_resolve_ending()`, on hit: sets the matching `flag_ending_seen_*`, sets `unlock_endless_mode` if "true", sets `_ending_fired = true`, emits `ending_triggered(id)`.

Register as autoload in `project.godot` after `QuestManager` and `UnlockFlags`:
```
EndingManager="*res://core/endings/ending_manager.gd"
```
The `core/endings/` directory already exists (currently empty) — fits naturally.

### 3. Ending screen — `ui/screens/ending_screen.gd` + `ui/screens/ending_screen.tscn`

CanvasLayer, layer **101**, `process_mode = PROCESS_MODE_ALWAYS`.

**Visual layout (640×360):**
```
CanvasLayer (layer=101)
└── Overlay (ColorRect, fullscreen, semi-transparent black 0.85)
    └── CenterContainer
        └── Panel (~480×260)
            └── MarginContainer (16px)
                └── VBoxContainer
                    ├── AccentBar (ColorRect, 6px high, accent color)
                    ├── TitleLabel (font_size=24)
                    ├── SubtitleLabel (font_size=12, italic-ish)
                    ├── HSeparator
                    ├── BodyLabel (autowrap, font_size=10) — flavor / outcome text
                    ├── HSeparator
                    ├── StatsLabel (font_size=10, dim) — "Day reached: N • Plants discovered: X / 11"
                    ├── CreditsLabel (font_size=8, dim, autowrap) — 4–6 lines
                    └── ButtonRow (HBoxContainer)
                        ├── ContinueButton ("Continue Run") — disabled for True (still hides screen, but user remains in run)
                        ├── MainMenuButton ("Main Menu")
                        └── EndlessButton ("Endless Mode") — only visible after True; shows toast "Coming soon" — TODO: END-04
```

Behavior:
- `_ready()` connects `EndingManager.ending_triggered → _on_ending(id)` and starts hidden.
- `_on_ending(id)` populates labels from a `_ENDING_COPY` dict keyed by id, pauses the tree, sets `visible = true`. Pause via `get_tree().paused = true` (consistent with night-survived/game-over).
- `Continue` → unpause, hide. Run continues. `MainMenu` → unpause, change scene.
- `EndlessButton.visible = (id == "true")`; pressed → print `"[EndingScreen] TODO: END-04 — Endless mode"` and disabled state, do not change scene.

**Copy table (`_ENDING_COPY`):**
| ID | Title | Subtitle | Accent Color | Body |
|----|-------|----------|--------------|------|
| true | "TRUE ENDING — Bloom Eternal" | "The Devourer falls. The garden breathes again." | `Color(1.0, 0.85, 0.3, 1)` gold | "Dianthus's full potential blossoms across the meadow. Light returns to every petal you tended. The Voidlord's shadow is no more, and a new dawn rests on the horizon." |
| survival | "SURVIVAL ENDING — Open Skies" | "You held the line. The story is not yet finished." | `Color(0.7, 0.7, 0.85, 1)` pale silver | "Twenty nights survived. The garden endures, but Dianthus's deepest secrets remain sealed. Whispers from beyond linger — perhaps another seed will wake what this one could not." |
| discovery | "DISCOVERY ENDING — A New Bloom" | "Dianthus has become more than a flower." | `Color(0.55, 0.95, 0.55, 1)` verdant green | "Through every cross-pollination and every catalogued bud, Dianthus has woken. It is no longer simply a plant — it walks with you now, breathing, learning, growing." |

`StatsLabel` reads `DayNightCycle.day_count` and `CodexManager.get_discovered_count() / get_total_count()`.

**Credits text** (static):
```
Dianthus Pixie — Demo Build
A garden defense story.
Engine: Godot 4.x
Plants, code, and pixels by the team.
```

### 4. Scene instancing — `world/zones/meadow_edge/meadow_edge.tscn`

Add `EndingScreen.tscn` ext_resource (next id slot) and instance it as a sibling to other UI screens (e.g., right after `QuestLogScreen`). It's a CanvasLayer so positioning is irrelevant.

### 5. Save schema — `save/scripts/save_manager.gd`

- `SCHEMA_VERSION` 8 → **9**.
- `_gather_state()`: no new top-level keys (ending-seen flags travel via `UnlockFlags.serialize()` which is already gathered).
- Replace `state["unlocks"] = []   # TODO (END-01, END-04)` with `state["unlocks"] = []   # TODO: END-04` (or remove if you confirm unused — grep `state["unlocks"]` first; the field is still referenced by old migrations).
- `_migrate()` v8→v9: no data changes — just bump and `print("[SaveManager] Migrated v8 → v9 (endings)")`.

### 6. Debug input

In `player/scripts/player_controller.gd._unhandled_input` (or wherever existing `Ctrl+Shift+5` style debug keys live), add:
```gdscript
elif event.keycode == KEY_1 and event.ctrl_pressed and not event.shift_pressed:
    EndingManager.force_trigger("true")
elif event.keycode == KEY_2 and event.ctrl_pressed and not event.shift_pressed:
    EndingManager.force_trigger("survival")
elif event.keycode == KEY_3 and event.ctrl_pressed and not event.shift_pressed:
    EndingManager.force_trigger("discovery")
```
Guard the existing `Ctrl+Shift+1/2/3` (if any) — currently `Ctrl+Shift+5` is taken; plain `Ctrl+1/2/3` should be free, but verify with a grep first.

### 7. NightSurvivedScreen ordering

`NightSurvivedScreen` already pauses on `night_survived`. To keep its reward popup readable, `EndingManager._try_fire()` schedules via `call_deferred("_try_fire_now")` so the night-survived popup appears first; the user clicks Continue, unpauses, then the ending screen fires on the *next* frame because it listens to the same signal but resolves async. To make this clean: `EndingManager` listens to `NightSurvivedScreen.continue_pressed` if available; otherwise it just defers. Implement the simple defer-on-`night_survived` path; if the night-survived screen is open the ending screen will draw on top of it (layer 101 > 100), which is fine — the user closes the ending and night-survived is already gone (continue button on ending screen unpauses).

---

## Files to Create

| File | Purpose |
|------|---------|
| `core/endings/ending_manager.gd` | Autoload — evaluates ending conditions, fires once per run, emits signal |
| `ui/screens/ending_screen.gd` | UI logic — populates copy by ending id, button handlers |
| `ui/screens/ending_screen.tscn` | CanvasLayer scene (layer 101), styled panel, accent bar, credits |

## Files to Modify

| File | Change |
|------|--------|
| `project.godot` | Register `EndingManager` autoload after `QuestManager` |
| `quests/data/story/ending_flags.gd` | Add `flag_ending_seen_true/_survival/_discovery`, `unlock_endless_mode`, `flag_discovery_complete` constants |
| `shared/autoloads/game_manager.gd` | Add `signal ending_triggered(ending_id: String)` (re-emitted from EndingManager for HUD/menu listeners — optional; can skip if EndingManager's own signal suffices) |
| `save/scripts/save_manager.gd` | `SCHEMA_VERSION = 9`; v8→v9 no-op migration; clean stale `# TODO (END-01, END-04)` comment |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance `EndingScreen` as a UI sibling |
| `player/scripts/player_controller.gd` | Debug `Ctrl+1/2/3` force-trigger keys |
| `docs/design/PERSON_TASKS.md` | Add END-01/02/03 row marked ✅; add `Ctrl+1/2/3` debug rows |
| `docs/design/TASK_BREAKDOWN.md` | END-01/END-02/END-03 status → Done |

---

## Acceptance Criteria

1. **END-01 True** — With `Ctrl+Shift+7` (sets `flag_story_devourer_defeated`) on Day 30+, ending screen appears with gold accent, title "TRUE ENDING — Bloom Eternal", and an `Endless Mode` button. The button prints the END-04 TODO and stays disabled.
2. **END-01 gating** — On Day 29, `Ctrl+Shift+7` does NOT trigger the ending. After surviving to Day 30 with the flag already set, the ending fires on `night_survived`.
3. **END-02 Survival** — Surviving night 20 (or later) without `flag_story_complete` and without `flag_story_devourer_defeated` triggers the silver "OPEN SKIES" screen.
4. **END-02 suppression** — If `flag_story_complete` is set, surviving Day 20+ does NOT fire Survival.
5. **END-03 Discovery** — Setting `discovery_complete` flag (via the existing `discovery_all_hybrids.tres` quest reward, or `Ctrl+3` debug) triggers the green "A NEW BLOOM" screen.
6. **Priority** — Simultaneous conditions: True wins over Discovery wins over Survival. With debug, set all three flags then trigger `_try_fire()` via day rollover; only one screen appears.
7. **One-shot** — After an ending fires, `flag_ending_seen_*` is set; subsequent triggers are silently ignored within the run. Save/reload preserves the seen state.
8. **Save schema** — `SCHEMA_VERSION = 9`. Old v8 saves load and print `[SaveManager] Migrated v8 → v9 (endings)`.
9. **Continue Run** — Clicking Continue on the ending screen unpauses and returns control without ending the run (matches GDD's "open story" intent for Survival; True/Discovery also allow continuing for sandbox play).
10. **Main Menu** — Clicking Main Menu unpauses, changes to `res://ui/menus/main_menu.tscn`.
11. **No Game Over collision** — If `current_state == GAME_OVER`, ending screen does not fire.
12. **Stats line** — Ending screen shows correct `day_count` and `CodexManager` discovered count.

---

## Test Recipe (manual)

1. `Ctrl+Shift+5` → start story chain. Use existing debug keys to advance to Day 30 via `O`/`P` phase skip.
2. `Ctrl+Shift+7` → emit devourer_defeated → ending fires (True).
3. Restart. Survive (or debug-skip) to Day 20 without setting any story-complete flag → Survival fires.
4. Restart. Pick up all 11 plant seeds + breed all 4 hybrids until `discovery_complete` is set → Discovery fires.
5. Restart. `Ctrl+1` → True forced. Reload save → seen flag persists; `Ctrl+1` again does nothing.

---

## TODO Stubs to Leave

- `# TODO: END-04` — Endless mode unlock + Endless Mode button activation in ending_screen.gd.
- `# TODO: END-ALT` — alt-ending flags (`flag_alt_ending_lost/shadow/lingering`) integration in ending_manager.gd resolver.
- `# TODO: DIALOG-01` — outro dialogic timeline playback before the ending screen.
- `# TODO: NEWGAME+` — New Game+ flow on Main Menu after seeing an ending.
