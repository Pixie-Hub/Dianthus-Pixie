extends Control

const SETTINGS_PATH: String = "user://settings.cfg"

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _colorblind_toggle: CheckButton = %ColorblindToggle
@onready var _text_speed_option: OptionButton = %TextSpeedOption


func _ready() -> void:
	visible = false
	_text_speed_option.add_item("Slow", 0)
	_text_speed_option.add_item("Normal", 1)
	_text_speed_option.add_item("Fast", 2)
	_text_speed_option.add_item("Instant", 3)
	_text_speed_option.selected = 1
	_load_settings()
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_colorblind_toggle.toggled.connect(_on_colorblind_toggled)
	_text_speed_option.item_selected.connect(_on_text_speed_changed)


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


func _on_text_speed_changed(_index: int) -> void:
	pass  # TODO (ACCESS-04): Set dialogue system text speed.


# --- Persistence ---

func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "master", _master_slider.value)
	config.set_value("audio", "music", _music_slider.value)
	config.set_value("audio", "sfx", _sfx_slider.value)
	config.set_value("display", "fullscreen", _fullscreen_toggle.button_pressed)
	config.set_value("accessibility", "colorblind", _colorblind_toggle.button_pressed)
	config.set_value("accessibility", "text_speed", _text_speed_option.selected)
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
	_colorblind_toggle.button_pressed = config.get_value("accessibility", "colorblind", false)
	_text_speed_option.selected = config.get_value("accessibility", "text_speed", 1)
	_on_master_changed(_master_slider.value)
	_on_music_changed(_music_slider.value)
	_on_sfx_changed(_sfx_slider.value)
	_on_fullscreen_toggled(_fullscreen_toggle.button_pressed)
	GameManager.set_colorblind_mode(_colorblind_toggle.button_pressed)
	print("[Settings] Settings loaded.")
