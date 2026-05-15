extends Control

const SETTINGS_PATH: String = "user://settings.cfg"
const TEXT_SPEED_VALUES: Array[float] = [0.5, 1.0, 2.0, 0.0]
const AUDIO_BUSES: Array[String] = ["Music", "SFX"]
const CRAFTING_SCREEN_SCRIPT: GDScript = preload("res://ui/screens/crafting_screen.gd")

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _colorblind_toggle: CheckButton = %ColorblindToggle
@onready var _tutorial_toggle: CheckButton = %TutorialToggle
@onready var _atmospheric_vfx_toggle: CheckButton = %AtmosphericVfxToggle
@onready var _text_speed_option: OptionButton = %TextSpeedOption
# TODO: MINI-01-SETTINGS — wire up SkipMinigameToggle node in settings_screen.tscn
# When the node is added to the scene, remove the null guard below.
var _skip_minigame_toggle: CheckButton = null
var _skip_crafting_minigame_toggle: CheckButton = null


func _ready() -> void:
	visible = false
	_ensure_audio_buses()
	_text_speed_option.add_item("Slow", 0)
	_text_speed_option.add_item("Normal", 1)
	_text_speed_option.add_item("Fast", 2)
	_text_speed_option.add_item("Instant", 3)
	_text_speed_option.selected = 1
	_load_settings()
	_tutorial_toggle.button_pressed = TutorialManager.tutorial_enabled
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_colorblind_toggle.toggled.connect(_on_colorblind_toggled)
	_tutorial_toggle.toggled.connect(_on_tutorial_toggled)
	_atmospheric_vfx_toggle.toggled.connect(_on_atmospheric_vfx_toggled)
	_text_speed_option.item_selected.connect(_on_text_speed_changed)
	# Skip minigame toggle — search the scene for the node in case tscn hasn't been updated yet.
	_skip_minigame_toggle = find_child("SkipMinigameToggle", true, false) as CheckButton
	if _skip_minigame_toggle != null:
		_skip_minigame_toggle.button_pressed = CrossBreedingScreen.skip_breeding_minigame
		_skip_minigame_toggle.toggled.connect(_on_skip_minigame_toggled)
		_skip_minigame_toggle.disabled = not UnlockFlags.has_flag("flag_tutorial_complete")
	_skip_crafting_minigame_toggle = find_child("SkipCraftingMinigameToggle", true, false) as CheckButton
	if _skip_crafting_minigame_toggle != null:
		_skip_crafting_minigame_toggle.button_pressed = bool(CRAFTING_SCREEN_SCRIPT.get("skip_crafting_minigame"))
		_skip_crafting_minigame_toggle.toggled.connect(_on_skip_crafting_minigame_toggled)
		_skip_crafting_minigame_toggle.disabled = not UnlockFlags.has_flag("flag_tutorial_complete")
	_apply_audio_settings()


func open() -> void:
	visible = true


func close() -> void:
	SfxManager.play("ui_button_click")
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


func _ensure_audio_buses() -> void:
	for bus_name: String in AUDIO_BUSES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var idx: int = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _apply_audio_settings() -> void:
	_on_master_changed(_master_slider.value)
	_on_music_changed(_music_slider.value)
	_on_sfx_changed(_sfx_slider.value)


# --- Fullscreen ---

func _on_fullscreen_toggled(enabled: bool) -> void:
	SfxManager.play("ui_button_click")
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# --- Stubs ---



func _on_colorblind_toggled(enabled: bool) -> void:
	SfxManager.play("ui_button_click")
	GameManager.set_colorblind_mode(enabled)


func _on_tutorial_toggled(enabled: bool) -> void:
	SfxManager.play("ui_button_click")
	TutorialManager.set_tutorial_enabled(enabled)


func _on_atmospheric_vfx_toggled(_enabled: bool) -> void:
	SfxManager.play("ui_button_click")


func _on_text_speed_changed(index: int) -> void:
	if Engine.has_singleton("Dialogic"):
		Dialogic.Settings.text_speed = TEXT_SPEED_VALUES[index]


func _on_skip_minigame_toggled(enabled: bool) -> void:
	SfxManager.play("ui_button_click")
	CrossBreedingScreen.skip_breeding_minigame = enabled


func _on_skip_crafting_minigame_toggled(enabled: bool) -> void:
	SfxManager.play("ui_button_click")
	CRAFTING_SCREEN_SCRIPT.set("skip_crafting_minigame", enabled)


# --- Persistence ---

func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "master", _master_slider.value)
	config.set_value("audio", "music", _music_slider.value)
	config.set_value("audio", "sfx", _sfx_slider.value)
	config.set_value("display", "fullscreen", _fullscreen_toggle.button_pressed)
	config.set_value("graphics", "atmospheric_vfx", _atmospheric_vfx_toggle.button_pressed)
	config.set_value("accessibility", "colorblind", _colorblind_toggle.button_pressed)
	config.set_value("accessibility", "tutorial", _tutorial_toggle.button_pressed)
	config.set_value("accessibility", "text_speed", _text_speed_option.selected)
	config.set_value("accessibility", "skip_breeding_minigame", CrossBreedingScreen.skip_breeding_minigame)
	config.set_value("accessibility", "skip_crafting_minigame", bool(CRAFTING_SCREEN_SCRIPT.get("skip_crafting_minigame")))
	config.save(SETTINGS_PATH)
	print("[Settings] Settings saved.")


func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_master_slider.value = config.get_value("audio", "master", 100.0)
	_music_slider.value = config.get_value("audio", "music", 100.0)
	_sfx_slider.value = config.get_value("audio", "sfx", 100.0)
	_fullscreen_toggle.button_pressed = config.get_value("display", "fullscreen", false)
	_atmospheric_vfx_toggle.button_pressed = config.get_value("graphics", "atmospheric_vfx", true)
	_colorblind_toggle.button_pressed = config.get_value("accessibility", "colorblind", false)
	_tutorial_toggle.button_pressed = config.get_value("accessibility", "tutorial", true)
	_text_speed_option.selected = config.get_value("accessibility", "text_speed", 1)
	CrossBreedingScreen.skip_breeding_minigame = config.get_value("accessibility", "skip_breeding_minigame", false)
	CRAFTING_SCREEN_SCRIPT.set("skip_crafting_minigame", config.get_value("accessibility", "skip_crafting_minigame", false))
	if _skip_minigame_toggle != null:
		_skip_minigame_toggle.button_pressed = CrossBreedingScreen.skip_breeding_minigame
	if _skip_crafting_minigame_toggle != null:
		_skip_crafting_minigame_toggle.button_pressed = bool(CRAFTING_SCREEN_SCRIPT.get("skip_crafting_minigame"))
	_on_fullscreen_toggled(_fullscreen_toggle.button_pressed)
	GameManager.set_colorblind_mode(_colorblind_toggle.button_pressed)
	TutorialManager.set_tutorial_enabled(_tutorial_toggle.button_pressed)
	_on_text_speed_changed(_text_speed_option.selected)
	print("[Settings] Settings loaded.")
