---
trigger: always_on
---

## Project Overview

`Dianthus Pixie` is a 2D survival-crafting action game built in Godot 4.6 using the Forward Plus renderer. The game loop is organized around exploring and gathering resources, preparing the garden through crafting and plant breeding, then defending the Dianthus Core during night waves.

This repository is organized by gameplay feature. Each feature folder should own the scenes, scripts, data resources, sprites, audio, and UI pieces that belong to that feature. Prefer working inside the smallest relevant feature area instead of adding cross-project abstractions.

Primary references:

- `README.md` for the current repository layout and high-level system summary.
- `docs/design/TASK_BREAKDOWN.md` for task status, priorities, dependencies, and acceptance criteria.
- `../Dianthus Pixie GDD.md` for the broader design document when available.
- `project.godot` for autoloads, input actions, main scene, rendering settings, and enabled plugins.

## Required Workflow

- Read files before editing them.
- Follow existing patterns in the codebase.
- Keep changes narrow and local to the requested behavior.
- If the prompt is ambiguous, ask before implementing. Clarify unclear target scenes, intended player flow, asset choice, task scope, or whether a design task should be started.
- Do not treat debug shortcuts as the real player flow unless the user explicitly says so. Prefer actual in-world interactions and input actions from `project.godot`.
- Before editing, check `git status --short` and identify unrelated user changes.
- Always commit every change to Git after editing and verification.
- Commit only the files changed for the current request. Do not include unrelated modified or untracked files unless the user explicitly asks.
- Use clear commit messages that describe the player-facing or developer-facing change.
- Never use destructive Git commands such as `git reset --hard` or `git checkout --` unless the user explicitly asks.

## Task Breakdown Rules

Use `docs/design/TASK_BREAKDOWN.md` as the guide for which tasks have and have not been completed.

- Before implementing a feature-sized request, find the matching task row and read its status, dependencies, priority, and acceptance criteria.
- Treat `Done` tasks as existing intended behavior, but still verify the current code before relying on them.
- Treat `Not Started` tasks as not implemented unless the current code clearly proves otherwise.
- If the user asks for work that maps to a `Not Started` task, implement only the requested slice unless they ask for the whole task.
- If a request conflicts with the task breakdown or GDD, explain the conflict and ask before making design-heavy changes.
- Do not mark a task as `Done` unless the implementation satisfies the acceptance criteria or the user asks for a planning/documentation update.
- If implementation changes task status, dependencies, or acceptance criteria, update the task breakdown only when that is part of the requested work or clearly necessary to keep docs honest.

## Project Structure

- `.claude/`: Claude Code local configuration and related agent files.
- `.godot/`: Godot editor cache, imported metadata, shader cache, and local editor state. Avoid manual edits unless diagnosing editor-local state.
- `.vscode/`: VS Code workspace settings.
- `.windsurf/`: Windsurf agent/editor rules.
- `accessibility/`: Difficulty, tutorial, and accessibility-related systems.
- `addons/`: Third-party Godot addons, including Dialogic. Do not edit anything here.
- `assets/`: Raw source assets such as Aseprite files, source music, and source SFX.
- `audio/`: Runtime audio managers and imported music/SFX resources used by the game.
- `combat/`: Weapons, projectiles, hit logic, and combat-specific behavior.
- `core/`: Foundational game systems such as day-night flow, Dianthus Core, endings, and scene transitions.
- `crafting/`: Crafting, breeding bench, cross-breeding logic, recipes, and related data.
- `dialogic/`: Project-owned Dialogic timelines, characters, and styles.
- `docs/`: Design documents, task breakdowns, and reference materials ignored by Godot runtime.
- `enemies/`: Enemy scenes, enemy scripts, FSM states, base enemy code, and wave spawner logic.
- `inventory/`: Inventory manager, item data, pickup logic, and inventory-related resources.
- `minigames/`: Standalone minigame scenes and scripts for breeding, crafting, and harvesting.
- `plants/`: Plant entities, placement systems, plant sprites, and plant effect behavior.
- `player/`: Player scene, controller scripts, player animation resources, and player sprites.
- `quests/`: Quest manager, quest logic, daily/story/discovery quest data, and quest resources.
- `save/`: Save/load scripts, save schema logic, and leaderboard persistence.
- `shared/`: Cross-feature autoloads, components, constants, fonts, utilities, and shared layer definitions.
- `tests/`: Unit and integration tests.
- `ui/`: HUD, menus, screens, codex UI, quest UI, and reusable UI components.
- `vfx/`: Shared effects, animations, particles, and shaders.
- `world/`: Garden, zones, tile sets, zone tracker, and world scene scripts.

## Godot

- Engine version: **Godot 4.6** (Forward Plus renderer).
- GDScript is used for all scripting.
- Project uses GDScript 2.0 syntax (`class_name`, `@export`, `@onready`, signal declarations, etc.).
- Main scene is `res://ui/menus/main_menu.tscn`.
- Prefer typed GDScript that matches nearby code.
- Be careful with Godot 4 typed arrays. APIs such as `map()` and some `duplicate()` flows can return untyped `Array`; rebuild typed arrays explicitly when assigning to `Array[String]` or other typed arrays.
- For `%NodeName` lookups, verify the scene node exists and has correct `unique_name_in_owner` metadata before changing script logic.
- Do not manually edit generated `.import` files or `.uid` files unless the user explicitly asks and the reason is clear.

## Implementation Guidelines

- Prefer feature-local scripts and resources over new global systems.
- Use existing autoloads and managers instead of introducing duplicate singletons.
- Preserve existing names, signal contracts, input action names, and resource paths unless the request requires changing them.
- For UI and pause behavior, account for overlapping screens. Shared pause state should be managed through the existing pause ownership pattern.
- For audio, route behavior through `SfxManager` and `MusicManager` where possible. Keep SFX IDs semantically matched to the screen or gameplay event.
- For tutorial and quest logic, verify both visible prompt text and the event/signal that completes the step.
- For scene-driven issues, inspect both the `.gd` script and the `.tscn` wiring.
- For runtime-generated systems, identify the runtime source of truth before editing scene-authored data.
- Avoid broad refactors, formatting churn, and unrelated cleanup.

## Validation

- Prefer running the smallest relevant check after edits.
- For parser/startup/autoload changes, run a headless Godot startup check when possible.
- If `godot` is not on `PATH`, try `godot4`, then inspect `.godot/editor/project_metadata.cfg` for the editor binary path.
- If Godot cannot be run, do static verification with targeted searches and explain that runtime validation was not performed.
- For task-breakdown-driven work, compare the result against the relevant acceptance criteria.
- For UI work, verify scene paths, node names, signal connections, and process mode behavior when pause is involved.

## Addons

- **Do not edit anything in the `addons/` folder.**
- You may read files in `addons/` to understand how to use Dialogic and other addons.
- Project-specific Dialogic content belongs in `dialogic/`, not `addons/`.

## Dialogic 2.x Specific Rules

- **Starting Dialog:** Dialogic 2 is an Autoload. To start a timeline, use `Dialogic.start("timeline_name")`. Do not attempt to instantiate a Dialogic node and add it to the tree manually.
- **Handling Multiple Styles:**
  - **Rule:** **NEVER attempt to run two timelines simultaneously.** Dialogic 2 operates on a single global state (`Dialogic.current_timeline`).
  - **Style per Character:** To seamlessly switch between styles (for example, Visual Novel layout vs. Text Bubble layout) in the same conversation, instruct the user to create custom **Styles** in the Dialogic editor and assign those styles directly inside the **Character Resources (`.dch`)**. Dialogic will automatically swap layouts when that character speaks.
  - **True Simultaneous Display:** If the user requires a text bubble to appear above an NPC at the exact same time a VN text box is actively typing on screen, do not run two timelines. Instead, run the primary VN timeline and use Dialogic's `[signal=your_signal_name]` text effect to trigger a standard Godot `RichTextLabel` or custom bubble node in the 2D/3D world.
- **Signals & Events:** Connect to Dialogic's custom signals using standard Godot 4 syntax: `Dialogic.signal_event.connect(_on_dialogic_signal)`.
- **Timeline State:** To check if dialogue is currently actively playing, check if `Dialogic.current_timeline != null`.
- **Variables:** Access and modify Dialogic variables via the state manager: `Dialogic.VAR.variable_name = value`.
- **Text Format (.dtl):** Use the modern Dialogic 2 Text Format (`.dtl`) when writing script examples, such as `CharacterName: Hello there!`.

## Important Autoloads

| Name                 | Script                                           |
| -------------------- | ------------------------------------------------ |
| `GameManager`        | `shared/autoloads/game_manager.gd`               |
| `PauseManager`       | `shared/autoloads/pause_manager.gd`              |
| `DayNightCycle`      | `core/day_night/day_night_cycle.gd`              |
| `SceneTransition`    | `core/transitions/scene_transition.gd`           |
| `SaveManager`        | `save/scripts/save_manager.gd`                   |
| `DifficultyManager`  | `accessibility/difficulty/difficulty_manager.gd` |
| `InventoryManager`   | `inventory/scripts/inventory_manager.gd`         |
| `CraftingManager`    | `crafting/scripts/crafting_manager.gd`           |
| `BreedingManager`    | `crafting/breeding/breeding_manager.gd`          |
| `CodexManager`       | `ui/codex/codex_manager.gd`                      |
| `QuestManager`       | `quests/scripts/quest_manager.gd`                |
| `ZoneTracker`        | `world/scripts/zone_tracker.gd`                  |
| `UnlockFlags`        | `shared/autoloads/unlock_flags.gd`               |
| `DailyQuestRoller`   | `quests/scripts/daily_quest_roller.gd`           |
| `EndingManager`      | `core/endings/ending_manager.gd`                 |
| `EndlessLeaderboard` | `save/scripts/endless_leaderboard.gd`            |
| `SfxManager`         | `audio/sfx_manager.gd`                           |
| `MusicManager`       | `audio/music_manager.gd`                         |
| `Dialogic`           | Dialogic addon autoload                          |
| `TutorialManager`    | `accessibility/tutorial/tutorial_manager.gd`     |

## Git Requirements

- Every completed change must end in a Git commit.
- Check status before and after editing.
- Stage only the intended files.
- Do not commit generated noise, editor-local cache files, or unrelated user work.
- If validation cannot be run, still commit the requested file changes and mention the validation limit.
- In the final response, include the commit hash and a brief summary of what changed.
