# Claude Code Guidelines

## Godot

- Engine version: **Godot 4.6** (Forward Plus renderer)
- GDScript is used for all scripting.
- Project uses GDScript 2.0 syntax (class_name, @export, @onready, signal declarations, etc.).

## General

- Read files before editing them.
- Follow existing patterns in the codebase.

## Addons

- **Do not edit anything in the `addons/` folder.**
- You may read files in `addons/` to understand how to use Dialogic and other addons.

## Dialogic 2.x Specific Rules
* **Starting Dialog:** Dialogic 2 is an Autoload. To start a timeline, use `Dialogic.start("timeline_name")`. Do not attempt to instantiate a Dialogic node and add it to the tree manually.
* **Handling Multiple Styles:**
    * **Rule:** **NEVER attempt to run two timelines simultaneously.** Dialogic 2 operates on a single global state (`Dialogic.current_timeline`).
    * **Style per Character:** To seamlessly switch between styles (e.g., Visual Novel layout vs. Text Bubble layout) in the same conversation, instruct the user to create custom **Styles** in the Dialogic editor and assign those styles directly inside the **Character Resources (`.dch`)**. Dialogic will automatically swap layouts when that character speaks.
    * **True Simultaneous Display:** If the user requires a text bubble to appear above an NPC *at the exact same time* a VN text box is actively typing on screen, do not run two timelines. Instead, run the primary VN timeline and use Dialogic's `[signal=your_signal_name]` text effect to trigger a standard Godot `RichTextLabel` or custom bubble node in the 2D/3D world.
* **Signals & Events:** Connect to Dialogic's custom signals using standard Godot 4 syntax: `Dialogic.signal_event.connect(_on_dialogic_signal)`.
* **Timeline State:** To check if dialogue is currently actively playing, check if `Dialogic.current_timeline != null`.
* **Variables:** Access and modify Dialogic variables via the state manager: `Dialogic.VAR.variable_name = value`.
* **Text Format (.dtl):** Use the modern Dialogic 2 Text Format (.dtl) when writing script examples (e.g., `CharacterName: Hello there!`).

## Important Autoloads

| Name | Script |
|------|--------|
| `GameManager` | `shared/autoloads/game_manager.gd` |
| `SaveManager` | `save/scripts/save_manager.gd` |
| `InventoryManager` | `inventory/scripts/inventory_manager.gd` |
| `CraftingManager` | `crafting/scripts/crafting_manager.gd` |
| `TutorialManager` | `accessibility/tutorial/tutorial_manager.gd` |
| `DifficultyManager` | `accessibility/difficulty/difficulty_manager.gd` |
| `QuestManager` | `quests/scripts/quest_manager.gd` |
| `Dialogic` | Dialogic addon |
| `DayNightCycle` | `core/day_night/day_night_cycle.gd` |
| `MusicManager` | `audio/music_manager.gd` |
| `SfxManager` | `audio/sfx_manager.gd` |