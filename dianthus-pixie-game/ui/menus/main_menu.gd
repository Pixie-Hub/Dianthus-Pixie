extends Control

const _CONTINUE_LABEL_FORMAT: String = "Continue \u2014 Day %d"

@onready var _continue_btn: Button = %ContinueButton
@onready var _settings_screen: Control = %SettingsScreen
@onready var _overwrite_dialog: ConfirmationDialog = %OverwriteDialog


func _ready() -> void:
	_refresh_continue_button()
	_overwrite_dialog.confirmed.connect(_on_overwrite_confirmed)


func _refresh_continue_button() -> void:
	if SaveManager.has_save():
		var meta: Dictionary = SaveManager.get_save_metadata()
		var day: int = meta.get("day_count", 1)
		_continue_btn.text = _CONTINUE_LABEL_FORMAT % day
		_continue_btn.disabled = false
	else:
		_continue_btn.text = "Continue"
		_continue_btn.disabled = true


func _on_continue_pressed() -> void:
	print("[MainMenu] Loading save...")
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
	print("[MainMenu] Starting new game.")
	GameManager.current_state = GameManager.GameState.EXPLORATION
	GameManager.player_data = {"position": Vector2.ZERO, "last_zone": "", "inventory": {}}
	DayNightCycle.day_count = 1
	DayNightCycle.current_phase = DayNightCycle.Phase.DAY
	get_tree().change_scene_to_file("res://world/zones/meadow_edge/meadow_edge.tscn")


func _on_settings_pressed() -> void:
	_settings_screen.open()


func _on_quit_pressed() -> void:
	get_tree().quit()
