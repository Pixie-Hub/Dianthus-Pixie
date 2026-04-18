# UI-05 — Pause Menu, Main Menu & Settings — Implementation Prompt

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** M (1–3 days, combined)
**Priority:** High (Phase 4)
**Task IDs:** UI-05 (Pause Menu) + Main Menu (no formal ID — derived from PERSON_TASKS.md Person C Week 2)
**Dependencies:**
- FOUND-01 (Project Scaffold — Done)
- FOUND-06 (Scene Transition — Done) — `SceneTransition` autoload used for fade transitions
- SAVE-01 + SAVE-02 (Save System — Done) — `SaveManager` API: `has_save()`, `save_to_slot(true)`, `load_from_slot()`, `delete_save()`, `get_save_metadata()`
- CORE-04 (Game Over — Done) — Game Over screen's `_on_main_menu()` has a TODO to navigate to main menu
- CORE-09 (Night Survived — Done) — no direct interaction, but both pause and survive-screen can coexist

**Downstream dependents:** ACCESS-01 (difficulty selection writes to Settings), ACCESS-02 (colorblind toggle in Settings), ACCESS-04 (text speed slider in Settings), AUDIO-01..04 (volume sliders in Settings)

---

## 1. Objective

Ship **three interconnected UI screens** in a single sprint:

1. **Main Menu** — the game's entry point. Title screen with New Game, Continue, Settings, and Quit.
2. **Pause Menu** — in-game overlay accessible via `Escape` at any time (except during hard-scripted cutscenes, which don't exist yet). Sub-options: Resume, Settings, Save (manual), Main Menu.
3. **Settings Screen** — shared sub-screen usable from both Main Menu and Pause Menu. Controls: Master/Music/SFX volume, Fullscreen toggle, and forward-compatible stubs for difficulty, colorblind mode, text speed, and tutorial skip.

After this task:
- `project.godot` → `run/main_scene` points to `res://ui/menus/main_menu.tscn`.
- Game Over screen's `_on_main_menu()` navigates to the real main menu instead of reloading the scene.
- `SaveManager` is fully wired into the UI (Save button, Continue button, New Game overwrite dialog).

Non-goals (strictly deferred):
- Full inventory UI (UI-02), quest log (UI-03), plant codex (UI-04).
- Difficulty selection at New Game start (ACCESS-01) — only the Settings stub is wired.
- Colorblind mode implementation (ACCESS-02) — only the toggle exists.
- Audio tracks (AUDIO-01..04) — volume sliders are functional via AudioServer bus, but no music/SFX assets are required.
- Interactive tutorial toggle (ACCESS-03).

---

## 2. GDD Specs — Mapped to Acceptance

| GDD Section | Mapped Requirement |
|---|---|
| §11.2 "Pause Menu — akses ke Settings, Save/Load, dan Main Menu" | Pause Menu has Resume, Save, Settings, Main Menu buttons. |
| §11.3 "Manual save tersedia kapan saja selama Exploration/Preparation Phase" | Pause Menu Save button calls `SaveManager.save_to_slot(true)`. Shows success/blocked feedback. |
| §11.3 "Satu save slot per permainan" | New Game button shows overwrite confirmation if `SaveManager.has_save()`. |
| §11.4 "3 level kesulitan: Normal, Easy, Hard" | Settings screen has a Difficulty dropdown (stub — writes to a local var, `TODO (ACCESS-01)` for gameplay integration). |
| §11.4 "Colorblind mode" | Settings screen has a toggle (stub — `TODO (ACCESS-02)`). |
| §11.4 "Kecepatan teks dialog bisa diatur" | Settings screen has a Text Speed option (stub — `TODO (ACCESS-04)`). |
| §12.1 "UI Style: traditional overlay; frame HUD bergaya panel kayu alami" | Visual style: dark semi-transparent background, natural/wooden panel aesthetic for containers. Pixel-friendly fonts. |

---

## 3. Architecture

### 3a. File Structure

```
ui/
├── menus/
│   ├── main_menu.gd              # Main Menu script
│   ├── main_menu.tscn            # Main Menu scene (new main_scene)
│   ├── pause_menu.gd             # Pause Menu script
│   ├── pause_menu.tscn           # Pause Menu scene (instanced in gameplay scenes)
│   ├── settings_screen.gd        # Settings screen script (shared)
│   └── settings_screen.tscn      # Settings screen scene (instanced by both menus)
└── ...
```

**Modified files:**
- `project.godot` — change `run/main_scene` to `res://ui/menus/main_menu.tscn`
- `ui/screens/game_over_screen.gd` — replace TODO in `_on_main_menu()` with real navigation to main menu
- `world/zones/meadow_edge/meadow_edge.tscn` — add `PauseMenu` instance as a child node (CanvasLayer, high layer)

**No new autoloads.** Settings persistence uses a simple `ConfigFile` written to `user://settings.cfg`. No new input actions beyond the built-in `ui_cancel` (Escape).

### 3b. `ui/menus/main_menu.gd` — Main Menu

Root node: **Control** (full rect anchor).

**Scene tree:**
```
MainMenu (Control, full rect)
├── Background (TextureRect or ColorRect — dark gradient or title art)
├── VBoxContainer (centered)
│   ├── TitleLabel ("Dianthus Pixie", large pixel font)
│   ├── SubtitleLabel ("A 2D Survival Crafting Action Game", smaller)
│   ├── ContinueButton (Button — "Continue — Day X")
│   ├── NewGameButton (Button — "New Game")
│   ├── SettingsButton (Button — "Settings")
│   └── QuitButton (Button — "Quit")
├── SettingsScreen (instanced scene, initially hidden)
└── OverwriteDialog (ConfirmationDialog — "A save already exists. Overwrite?")
```

**Script logic:**

```gdscript
extends Control

@onready var _continue_btn: Button = %ContinueButton
@onready var _settings_screen: Control = %SettingsScreen   # or CanvasLayer
@onready var _overwrite_dialog: ConfirmationDialog = %OverwriteDialog
@onready var _continue_label_format: String = "Continue — Day %d"

func _ready() -> void:
    _refresh_continue_button()
    _overwrite_dialog.confirmed.connect(_on_overwrite_confirmed)

func _refresh_continue_button() -> void:
    if SaveManager.has_save():
        var meta: Dictionary = SaveManager.get_save_metadata()
        var day: int = meta.get("day_count", 1)
        _continue_btn.text = _continue_label_format % day
        _continue_btn.disabled = false
    else:
        _continue_btn.text = "Continue"
        _continue_btn.disabled = true

func _on_continue_pressed() -> void:
    SaveManager.load_from_slot()

func _on_new_game_pressed() -> void:
    if SaveManager.has_save():
        _overwrite_dialog.popup_centered()
    else:
        _start_new_game()

func _on_overwrite_confirmed() -> void:
    SaveManager.delete_save()
    _start_new_game()

func _start_new_game() -> void:
    # Reset GameManager state for a fresh run.
    GameManager.current_state = GameManager.GameState.EXPLORATION
    GameManager.player_data = {"position": Vector2.ZERO, "last_zone": "", "inventory": {}}
    DayNightCycle.day_count = 1
    DayNightCycle.current_phase = DayNightCycle.Phase.DAY
    get_tree().change_scene_to_file("res://world/zones/meadow_edge/meadow_edge.tscn")

func _on_settings_pressed() -> void:
    _settings_screen.open()

func _on_quit_pressed() -> void:
    get_tree().quit()
```

**Key behaviors:**
- Continue button is **greyed out** when no save exists. Label shows "Continue — Day X" when a save is present.
- New Game shows a `ConfirmationDialog` only when a save exists.
- `_start_new_game()` resets all relevant autoload state before transitioning. This prevents stale data from a previous session leaking into a new game.
- No `get_tree().paused` manipulation — Main Menu is never paused.

### 3c. `ui/menus/pause_menu.gd` — Pause Menu

Root node: **CanvasLayer** (layer 100, above HUD at default layer, below SceneTransition at 128).

**Scene tree:**
```
PauseMenu (CanvasLayer, layer=100, process_mode=PROCESS_MODE_ALWAYS)
├── Overlay (ColorRect — black, alpha ~0.5, full rect, mouse_filter=IGNORE)
├── PanelContainer (centered, ~300×280 px)
│   └── VBoxContainer
│       ├── TitleLabel ("Paused")
│       ├── ResumeButton
│       ├── SaveButton ("Save Game")
│       ├── SettingsButton ("Settings")
│       └── MainMenuButton ("Main Menu")
├── SettingsScreen (instanced, initially hidden)
├── SaveFeedbackLabel (Label — "Saved!" / "Cannot save during night", auto-hides)
└── MainMenuConfirmDialog (ConfirmationDialog — "Return to Main Menu? Unsaved progress will be lost.")
```

**Script logic:**

```gdscript
extends CanvasLayer

signal paused
signal resumed

@onready var _panel: PanelContainer = %PanelContainer
@onready var _save_btn: Button = %SaveButton
@onready var _save_feedback: Label = %SaveFeedbackLabel
@onready var _settings_screen: Control = %SettingsScreen
@onready var _main_menu_dialog: ConfirmationDialog = %MainMenuConfirmDialog

var _is_open: bool = false

func _ready() -> void:
    visible = false
    _save_feedback.visible = false
    _main_menu_dialog.confirmed.connect(_on_main_menu_confirmed)
    SaveManager.save_completed.connect(_on_save_completed)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if _settings_screen.visible:
            _settings_screen.close()
            get_viewport().set_input_as_handled()
            return
        _toggle()
        get_viewport().set_input_as_handled()

func _toggle() -> void:
    if _is_open:
        _close()
    else:
        _open()

func _open() -> void:
    if GameManager.current_state == GameManager.GameState.GAME_OVER:
        return
    _is_open = true
    visible = true
    get_tree().paused = true
    # Enable/disable Save button based on game state.
    _save_btn.disabled = GameManager.current_state != GameManager.GameState.EXPLORATION
    paused.emit()

func _close() -> void:
    _is_open = false
    visible = false
    _save_feedback.visible = false
    get_tree().paused = false
    resumed.emit()

func _on_resume_pressed() -> void:
    _close()

func _on_save_pressed() -> void:
    SaveManager.save_to_slot(true)

func _on_save_completed(success: bool, manual: bool) -> void:
    if not manual:
        return
    _save_feedback.visible = true
    _save_feedback.text = "Saved!" if success else "Cannot save during night."
    # Auto-hide after 2 seconds.
    var tw: Tween = create_tween()
    tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tw.tween_interval(2.0)
    tw.tween_callback(func() -> void: _save_feedback.visible = false)

func _on_settings_pressed() -> void:
    _settings_screen.open()

func _on_main_menu_pressed() -> void:
    _main_menu_dialog.popup_centered()

func _on_main_menu_confirmed() -> void:
    _is_open = false
    visible = false
    get_tree().paused = false
    get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
```

**Key behaviors:**
- `process_mode = PROCESS_MODE_ALWAYS` so the menu works while the tree is paused.
- Escape toggles pause. If the Settings sub-screen is open, Escape closes Settings first (back navigation).
- Save button is disabled during DEFENSE (night) and GAME_OVER. Feedback label shows result for 2 seconds.
- "Main Menu" shows a confirmation dialog to prevent accidental loss of unsaved progress.
- **Does NOT open** during GAME_OVER (the Game Over screen handles that state).
- Tween for feedback label uses `TWEEN_PAUSE_PROCESS` so it ticks while paused.

### 3d. `ui/menus/settings_screen.gd` — Settings Screen (Shared)

Root node: **Control** or **PanelContainer** (centered, ~350×350 px). Can be instanced inside both Main Menu and Pause Menu scenes.

**Scene tree:**
```
SettingsScreen (PanelContainer, centered, initially hidden)
├── VBoxContainer
│   ├── TitleLabel ("Settings")
│   ├── MasterVolumeRow (HBoxContainer)
│   │   ├── Label ("Master Volume")
│   │   └── HSlider (%MasterSlider, min=0, max=100, step=1, value=100)
│   ├── MusicVolumeRow (HBoxContainer)
│   │   ├── Label ("Music")
│   │   └── HSlider (%MusicSlider)
│   ├── SFXVolumeRow (HBoxContainer)
│   │   ├── Label ("SFX")
│   │   └── HSlider (%SFXSlider)
│   ├── FullscreenRow (HBoxContainer)
│   │   ├── Label ("Fullscreen")
│   │   └── CheckButton (%FullscreenToggle)
│   ├── HSeparator
│   ├── DifficultyRow (HBoxContainer)                   # TODO (ACCESS-01)
│   │   ├── Label ("Difficulty")
│   │   └── OptionButton (%DifficultyOption, items: Easy/Normal/Hard)
│   ├── ColorblindRow (HBoxContainer)                   # TODO (ACCESS-02)
│   │   ├── Label ("Colorblind Mode")
│   │   └── CheckButton (%ColorblindToggle)
│   ├── TextSpeedRow (HBoxContainer)                    # TODO (ACCESS-04)
│   │   ├── Label ("Text Speed")
│   │   └── OptionButton (%TextSpeedOption, items: Slow/Normal/Fast/Instant)
│   ├── HSeparator
│   └── BackButton ("Back")
```

**Script logic:**

```gdscript
extends PanelContainer

const SETTINGS_PATH: String = "user://settings.cfg"

# Audio bus indices — match Godot's default bus layout.
# Bus 0 = "Master", Bus 1 = "Music", Bus 2 = "SFX".
# These buses must be created in the Audio Bus Layout (default_bus_layout.tres).
# If they don't exist yet, this script handles it gracefully.

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _difficulty_option: OptionButton = %DifficultyOption
@onready var _colorblind_toggle: CheckButton = %ColorblindToggle
@onready var _text_speed_option: OptionButton = %TextSpeedOption

func _ready() -> void:
    visible = false
    _load_settings()
    # Connect signals.
    _master_slider.value_changed.connect(_on_master_changed)
    _music_slider.value_changed.connect(_on_music_changed)
    _sfx_slider.value_changed.connect(_on_sfx_changed)
    _fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
    _difficulty_option.item_selected.connect(_on_difficulty_changed)
    _colorblind_toggle.toggled.connect(_on_colorblind_toggled)
    _text_speed_option.item_selected.connect(_on_text_speed_changed)

func open() -> void:
    visible = true

func close() -> void:
    visible = false
    _save_settings()

# --- Audio ---

func _on_master_changed(value: float) -> void:
    _set_bus_volume("Master", value)

func _on_music_changed(value: float) -> void:
    _set_bus_volume("Music", value)

func _on_sfx_changed(value: float) -> void:
    _set_bus_volume("SFX", value)

func _set_bus_volume(bus_name: String, percent: float) -> void:
    var idx: int = AudioServer.get_bus_index(bus_name)
    if idx < 0:
        return
    if percent <= 0.0:
        AudioServer.set_bus_mute(idx, true)
    else:
        AudioServer.set_bus_mute(idx, false)
        AudioServer.set_bus_volume_db(idx, linear_to_db(percent / 100.0))

# --- Fullscreen ---

func _on_fullscreen_toggled(enabled: bool) -> void:
    if enabled:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# --- Stubs ---

func _on_difficulty_changed(_index: int) -> void:
    pass  # TODO (ACCESS-01): Apply difficulty to DifficultyScaling system.

func _on_colorblind_toggled(_enabled: bool) -> void:
    pass  # TODO (ACCESS-02): Toggle colorblind icons on HP/Energy bars.

func _on_text_speed_changed(_index: int) -> void:
    pass  # TODO (ACCESS-04): Set dialogue system text speed.

# --- Persistence ---

func _save_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("audio", "master", _master_slider.value)
    config.set_value("audio", "music", _music_slider.value)
    config.set_value("audio", "sfx", _sfx_slider.value)
    config.set_value("display", "fullscreen", _fullscreen_toggle.button_pressed)
    config.set_value("accessibility", "difficulty", _difficulty_option.selected)
    config.set_value("accessibility", "colorblind", _colorblind_toggle.button_pressed)
    config.set_value("accessibility", "text_speed", _text_speed_option.selected)
    config.save(SETTINGS_PATH)

func _load_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load(SETTINGS_PATH) != OK:
        return  # First launch — use defaults already set in the scene.
    _master_slider.value = config.get_value("audio", "master", 100.0)
    _music_slider.value = config.get_value("audio", "music", 100.0)
    _sfx_slider.value = config.get_value("audio", "sfx", 100.0)
    _fullscreen_toggle.button_pressed = config.get_value("display", "fullscreen", false)
    _difficulty_option.selected = config.get_value("accessibility", "difficulty", 1)  # Normal
    _colorblind_toggle.button_pressed = config.get_value("accessibility", "colorblind", false)
    _text_speed_option.selected = config.get_value("accessibility", "text_speed", 1)  # Normal
    # Apply loaded audio values immediately.
    _on_master_changed(_master_slider.value)
    _on_music_changed(_music_slider.value)
    _on_sfx_changed(_sfx_slider.value)
    # Apply loaded fullscreen value.
    _on_fullscreen_toggled(_fullscreen_toggle.button_pressed)
```

**Key behaviors:**
- Settings are persisted via `ConfigFile` at `user://settings.cfg`. Loaded on `_ready()`, saved on `close()`.
- Audio uses `AudioServer` bus API. **Requires** 3 buses to exist in the Audio Bus Layout: Master, Music, SFX. If `Music` or `SFX` buses don't exist yet, create them in `res://default_bus_layout.tres` (Godot's default audio bus layout file). The script handles missing buses gracefully (early return if bus index < 0).
- Fullscreen toggle uses `DisplayServer.window_set_mode()`.
- Difficulty, Colorblind, and Text Speed controls are **visual stubs** — they save/load their values but the gameplay effects are deferred to their owning tasks (ACCESS-01, ACCESS-02, ACCESS-04). Each callback has a `TODO` comment with the task ID.
- `open()` / `close()` API allows parent menus to control visibility. Escape in Pause Menu closes Settings before closing the pause overlay.

---

## 4. Audio Bus Setup

Create or update `res://default_bus_layout.tres` to include 3 buses:

| Bus Index | Name | Output To |
|-----------|------|-----------|
| 0 | Master | (device) |
| 1 | Music | Master |
| 2 | SFX | Master |

This can be done in the Godot editor: **Bottom panel → Audio → Add Bus** twice, rename to "Music" and "SFX", route both to "Master".

If the file doesn't exist yet, Godot auto-creates it. The settings script references buses by name, not index, so reordering is safe.

---

## 5. Hooks into Existing Code

### 5a. `project.godot` — Change main scene

```ini
run/main_scene="res://ui/menus/main_menu.tscn"
```

This is the **only** change to `project.godot`. No new autoloads.

### 5b. `ui/screens/game_over_screen.gd` — Wire Main Menu button

Replace the TODO in `_on_main_menu()`:

```gdscript
# BEFORE:
func _on_main_menu() -> void:
    get_tree().paused = false
    visible = false
    # TODO: Replace with SceneTransition.transition_to("res://ui/menus/main_menu.tscn") when main menu exists.
    get_tree().reload_current_scene()

# AFTER:
func _on_main_menu() -> void:
    get_tree().paused = false
    visible = false
    get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
```

### 5c. `world/zones/meadow_edge/meadow_edge.tscn` — Instance Pause Menu

Add an instance of `ui/menus/pause_menu.tscn` as a child of the root node in the zone scene. The CanvasLayer at layer 100 ensures it renders above gameplay and HUD.

**Every future gameplay zone scene must also instance the Pause Menu.** For now, only `meadow_edge` exists. When more zones are added (WORLD-01..04), each zone scene should include the PauseMenu instance (or it could be moved to an autoload pattern later if many zones make it tedious).

### 5d. Hooks NOT wired in this task

- `TODO (ACCESS-01)` — Difficulty option in Settings → actually modify enemy scaling multipliers.
- `TODO (ACCESS-02)` — Colorblind toggle → swap HP/Energy bar icon overlays.
- `TODO (ACCESS-04)` — Text speed option → set dialogue typewriter speed.
- `TODO (AUDIO-01..04)` — Actual music/SFX assets routed through Music/SFX buses.

---

## 6. Navigation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                       MAIN MENU                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────┐         │
│  │ Continue  │  │ New Game │  │ Settings │  │ Quit│         │
│  │ (Day X)  │  │          │  │          │  │     │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──┬──┘         │
│       │              │              │           │            │
│       │     ┌────────▼────────┐     │           │            │
│       │     │ Overwrite Save? │     │           │            │
│       │     │ (if save exists)│     │           │            │
│       │     └────────┬────────┘     │           │            │
│       │              │ Confirm      │           │            │
│       ▼              ▼              ▼           ▼            │
│   Load Save    Start Fresh    Settings UI    Quit App       │
│   (meadow)     (meadow)      (shared)                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    GAMEPLAY (any zone)                        │
│                                                              │
│   Escape pressed → Pause Menu opens → tree paused            │
│                                                              │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│   │  Resume  │  │  Save    │  │ Settings │  │ Main Menu │  │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│        │              │              │              │         │
│        ▼              ▼              ▼              ▼         │
│    Close &       save_to_slot    Settings UI   Confirm →     │
│    Unpause       (true) +        (shared)      → Main Menu   │
│                  feedback                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      GAME OVER SCREEN                        │
│                                                              │
│   ┌──────────┐  ┌───────────┐                                │
│   │ Restart  │  │ Main Menu │                                │
│   └────┬─────┘  └─────┬─────┘                                │
│        │               │                                     │
│        ▼               ▼                                     │
│   Reload Scene    change_scene_to_file(main_menu)            │
│                   (save file is NOT deleted)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Visual Style Guidelines

Per GDD §12.1: "UI Style: traditional overlay; frame HUD bergaya panel kayu alami".

- **Background overlay:** `ColorRect`, Color `#000000`, alpha `0.5` (50% opacity dark backdrop).
- **Panel style:** Use Godot's `StyleBoxFlat` on `PanelContainer` — dark brown (`#2a1f14`) background, light border (`#8b6b3d`), 2 px border width, 4 px corner radius. This gives a natural wood-panel feel that matches the pixel art aesthetic.
- **Font:** Use Godot's default font at appropriate sizes, or import a pixel-art font (e.g. "Press Start 2P" or "m5x7") for consistency with the 32×32 tile art. Title: 24 px, body/buttons: 12–14 px.
- **Button style:** `StyleBoxFlat` — brown base (`#3a2a18`), lighter hover (`#4a3a28`), pressed darken. Text color: warm white (`#f0e6d2`).
- **Slider style:** Track: dark (`#1a1208`), grabber: golden (`#c8a830`).
- **All sizing** must be pixel-friendly — even numbers, snapped to 2x or 4x multiples.
- **No animations required** for menus in this task. Simple show/hide. Tweened transitions are a polish task.

---

## 8. Acceptance Criteria

### Main Menu
1. **Game launches to Main Menu.** `project.godot` → `run/main_scene` is `res://ui/menus/main_menu.tscn`. Title "Dianthus Pixie" visible.
2. **Continue button greyed out on first launch** (no save exists). Label says "Continue".
3. **New Game transitions to meadow.** Click New Game (no save exists) → scene changes to `meadow_edge.tscn`. `DayNightCycle.day_count == 1`, `GameManager.current_state == EXPLORATION`.
4. **New Game with existing save shows overwrite dialog.** Create a save (F11 in-game), return to main menu, click New Game → ConfirmationDialog appears. Cancel → nothing happens. Confirm → save deleted, new game starts.
5. **Continue loads save.** Create a save at Day 2 with damaged Core. Return to main menu → Continue button says "Continue — Day 2". Click → game loads at Day 2 with correct Core HP, player position, garden layout.
6. **Settings opens and closes.** Click Settings → settings panel visible. Click Back → returns to main menu.
7. **Quit exits the application.**

### Pause Menu
8. **Escape opens pause menu during gameplay.** Tree is paused (enemies, timer, player frozen). Escape again closes it and unpauses.
9. **Escape does NOT open during GAME_OVER.** Trigger Game Over (F1 spam) → Escape does nothing.
10. **Resume button unpauses and closes the menu.**
11. **Save button works during DAY.** Open pause during DAY → click Save → "Saved!" feedback appears for 2 seconds. Save file updated.
12. **Save button disabled during NIGHT.** Advance to night (F7) → open pause → Save button is greyed out / disabled.
13. **Settings sub-screen.** Click Settings in pause → settings panel opens over the pause panel. Escape closes settings first, then a second Escape closes the pause menu.
14. **Main Menu button shows confirmation.** Click Main Menu → "Return to Main Menu?" dialog. Cancel → stays paused. Confirm → navigates to main menu, tree unpaused.

### Settings
15. **Volume sliders control AudioServer buses.** Move Master slider to 0 → `AudioServer.get_bus_volume_db(0)` is very low / muted. Same for Music and SFX buses.
16. **Fullscreen toggle works.** Check → window goes fullscreen. Uncheck → window returns to windowed mode.
17. **Settings persist across sessions.** Change Master to 50%, close settings, quit game, relaunch → Master slider is at 50%.
18. **Difficulty / Colorblind / Text Speed controls exist** but are stubs (no gameplay effect). They save/load their values. Each has a `TODO` comment with the owning task ID.

### Game Over Integration
19. **Game Over → Main Menu button navigates to main menu.** Trigger Game Over → click "Main Menu" → arrives at Main Menu. Continue button shows the last save, not the just-lost run.

### No Regressions
20. All existing features work: CORE-03/04/05/08/09/10, DIFF-01, PLANT-01, SAVE-01/02. HUD, night survived screen, game over screen, debug keys F1–F12 all function identically.

---

## 9. Existing Codebase Context

**Do NOT modify any of these beyond what §5 explicitly lists.**

### Autoloads (registered in project.godot):
- `GameManager` (`shared/autoloads/game_manager.gd`) — `current_state: GameState`, `player`, `dianthus_core`, `player_data`, signals: `game_state_changed`, `game_over_triggered`, `night_survived`.
- `DayNightCycle` (`core/day_night/day_night_cycle.gd`) — `day_count`, `current_phase`, `Phase.DAY/NIGHT`, `get_phase_name()`, `debug_skip_phase()`, `apply_loaded_state()`.
- `SceneTransition` (`core/transitions/scene_transition.gd`) — `transition_to(target)` with fade. CanvasLayer at layer 128. Blocks during DEFENSE state.
- `SaveManager` (`save/scripts/save_manager.gd`) — `has_save()`, `save_to_slot(manual)`, `load_from_slot()`, `delete_save()`, `get_save_metadata()`. Signals: `save_completed(success, manual)`, `load_completed(success)`.

### Existing UI patterns:
- `ui/screens/game_over_screen.gd` — extends CanvasLayer, `visible = false` in `_ready()`, shows on signal, pauses tree, process_mode = ALWAYS.
- `ui/screens/night_survived_screen.gd` — same pattern.
- `ui/hud/hud.gd` — extends CanvasLayer, connects GameManager signals in `_ready()`.
- All UI scripts use `%NodeName` unique name references (`@onready var _x: Type = %X`).

### CanvasLayer ordering:
| Layer | Owner |
|-------|-------|
| Default | HUD |
| 100 | Pause Menu (new) |
| 128 | SceneTransition |

### Display settings:
- Viewport: 640×360 px, stretch mode: `canvas_items`, scale mode: `integer`.
- All UI must fit within 640×360.

---

## 10. Important Constraints

- **GDScript only**, Godot 4.6, tabs for indentation, full type hints on parameters and return types.
- **`process_mode = PROCESS_MODE_ALWAYS`** on PauseMenu and its children so they work while the tree is paused. SettingsScreen inherits this from the parent CanvasLayer.
- **CanvasLayer layer for PauseMenu = 100.** Must be above HUD (default) but below SceneTransition (128) so the fade overlay covers the pause menu during transitions.
- **`ui_cancel` (Escape)** is the built-in action — no need to register a new input action. Use `event.is_action_pressed("ui_cancel")` in `_unhandled_input()`.
- **No new autoloads.** Settings are a local `ConfigFile`, not a global singleton. If a future task needs global access to settings values, that task should extract a `SettingsManager` autoload.
- **Do NOT touch** HUD, FSM states, weapon logic, PlantBase / Thornvine / Gloomshroom internals, WaveSpawner, SaveManager internals, DayNightCycle internals (beyond what §5 lists).
- **Keep diff small on existing files.** `game_over_screen.gd` changes ~2 lines. `project.godot` changes 1 line. `meadow_edge.tscn` adds 1 instance node. Everything else is new files.
- **TODO stubs are mandatory** for every deferred integration point. Tag each with its owning task ID per `taskworkflow.md`:
  - `TODO (ACCESS-01)` — difficulty gameplay effect
  - `TODO (ACCESS-02)` — colorblind mode
  - `TODO (ACCESS-04)` — text speed
  - `TODO (AUDIO-01..04)` — route assets through Music/SFX buses
- **`print` prefix convention:** `[MainMenu]`, `[PauseMenu]`, `[Settings]` for logs, matching existing `[SaveManager]` and `[WaveSpawner]` patterns.
- **Settings screen is a scene instanced by both menus**, not an autoload or a separate scene transition. This avoids scene-change complexity and keeps the "back" navigation simple.

---

## 11. Verification Script (Manual QA)

1. **Launch game.** Main Menu appears. "Continue" is greyed out. "Dianthus Pixie" title visible.
2. **Click New Game.** Meadow Edge loads. Day 1, DAY phase. HUD visible.
3. **Press Escape.** Pause Menu opens. Game is frozen (enemies, timer stopped). Buttons: Resume, Save, Settings, Main Menu.
4. **Click Save.** Feedback label: "Saved!" (disappears after 2 seconds). File written to `user://savegame.json`.
5. **Click Settings.** Settings panel opens. Change Master Volume to 50%. Click Back. Settings panel closes, pause menu still visible.
6. **Press Escape.** Pause menu closes. Game resumes. Timer ticking.
7. **Press F7** to advance to NIGHT. **Press Escape.** Pause opens. Save button is disabled/greyed out.
8. **Click Main Menu.** Confirmation dialog: "Return to Main Menu?". Cancel → stays. Confirm → Main Menu loads.
9. **Main Menu:** Continue button now says "Continue — Day 1". Click Continue → game loads from save. Player position, Core HP, day count all match.
10. **Play to Day 2** (F8 + F9 to clear night). **Press Escape → Main Menu → Confirm.** Main Menu: Continue says "Continue — Day 2" (autosave from night survive).
11. **Click New Game.** Overwrite dialog appears. Confirm → save deleted → new game starts at Day 1. Return to Main Menu → Continue is greyed out again.
12. **Trigger Game Over** (F1 spam). Game Over screen appears. Click "Main Menu" → Main Menu loads cleanly.
13. **Relaunch the game.** Settings (volume, fullscreen) persist from step 5. Verify Master volume is still at 50%.
14. **No regressions:** F1–F12 debug keys work. HUD updates. Night survived screen works. Plants placeable. Save/load via F11/F12 still work.

---

## 12. Out of Scope (future tasks — do NOT implement)

- **Inventory screen** → UI-02. Pause Menu does not include an inventory button.
- **Quest Log screen** → UI-03. No quest-related UI.
- **Plant Codex** → UI-04. No codex button.
- **Difficulty gameplay effect** → ACCESS-01. Settings dropdown exists but is a stub.
- **Colorblind mode implementation** → ACCESS-02. Toggle exists but is a stub.
- **Tutorial skip toggle** → ACCESS-03. Not even a stub in this task.
- **Text speed implementation** → ACCESS-04. Dropdown exists but is a stub.
- **Music/SFX assets** → AUDIO-01..04. Buses are set up, sliders work, but no audio files are added.
- **Animated menu transitions** → Polish task. Menus show/hide instantly.
- **Controller/gamepad navigation** → Polish task. Mouse/keyboard only for now.
- **Credits screen** → END-01. Not needed until endings are implemented.
- **New Game+** → Future task. Not in scope.

---

## 13. Post-Task Memory Update

After completing UI-05 + Main Menu + Settings, record in memory (per `taskworkflow.md`):

- New files: `ui/menus/main_menu.gd`, `ui/menus/main_menu.tscn`, `ui/menus/pause_menu.gd`, `ui/menus/pause_menu.tscn`, `ui/menus/settings_screen.gd`, `ui/menus/settings_screen.tscn`
- Modified files: `project.godot` (main_scene changed), `ui/screens/game_over_screen.gd` (main menu navigation), `world/zones/meadow_edge/meadow_edge.tscn` (PauseMenu instanced)
- Audio bus layout: `res://default_bus_layout.tres` updated with Master, Music, SFX buses
- Settings persistence: `user://settings.cfg` via ConfigFile
- Stubs: `TODO (ACCESS-01)`, `TODO (ACCESS-02)`, `TODO (ACCESS-04)`, `TODO (AUDIO-01..04)`
- CanvasLayer ordering: PauseMenu = 100, SceneTransition = 128
- Next downstream tasks: ACCESS-01, ACCESS-02, ACCESS-04, AUDIO-01..04
