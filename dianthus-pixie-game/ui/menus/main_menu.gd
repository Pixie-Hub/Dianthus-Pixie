extends Control

const _CONTINUE_LABEL_FORMAT: String = "Continue \u2014 Day %d"

@onready var _continue_btn: Button = %ContinueButton
@onready var _settings_screen: Control = %SettingsScreen
@onready var _overwrite_dialog: ConfirmationDialog = %OverwriteDialog
@onready var _difficulty_selection: Control = %DifficultySelection


func _ready() -> void:
	_refresh_continue_button()
	_overwrite_dialog.confirmed.connect(_on_overwrite_confirmed)
	_difficulty_selection.difficulty_selected.connect(_on_difficulty_selected)


func _refresh_continue_button() -> void:
	if SaveManager.has_save():
		var meta: Dictionary = SaveManager.get_save_metadata()
		var day: int = meta.get("day_count", 1)
		_continue_btn.text = _CONTINUE_LABEL_FORMAT % day
		_continue_btn.disabled = false
		_continue_btn.modulate = Color.WHITE
	else:
		_continue_btn.text = "Continue"
		_continue_btn.disabled = true
		_continue_btn.modulate = Color(0.42, 0.353, 0.282, 1)
	var best: int = EndlessLeaderboard.get_best_day()
	if best > 0:
		_continue_btn.tooltip_text = "Best Endless: Day %d" % best


func _on_continue_pressed() -> void:
	SfxManager.play("ui_button_click")
	print("[MainMenu] Loading save...")
	SaveManager.load_from_slot()


func _on_new_game_pressed() -> void:
	SfxManager.play("ui_button_click")
	if SaveManager.has_save():
		SfxManager.play("screen_open")
		_overwrite_dialog.popup_centered()
	else:
		_difficulty_selection.open()


func _on_overwrite_confirmed() -> void:
	_difficulty_selection.open()


func _start_new_game() -> void:
	SaveManager.delete_save()
	print("[MainMenu] Starting new game.")
	GameManager.current_state = GameManager.GameState.EXPLORATION
	GameManager.endless_mode = false
	GameManager.player_data = {"position": Vector2.ZERO, "last_zone": ""}
	DayNightCycle.day_count = 1
	DayNightCycle.current_phase = DayNightCycle.Phase.DAY
	DayNightCycle._phase_timer = DayNightCycle.PHASE_DURATIONS[DayNightCycle.Phase.DAY]
	TutorialManager.reset_progress_for_new_game()
	InventoryManager.clear_all()
	CraftingManager.deserialize({})
	BreedingManager.deserialize({})
	QuestManager.reset_state()
	DailyQuestRoller.reset_state()
	UnlockFlags.reset_state()
	CodexManager.reset_state()
	EndingManager.reset_state()
	get_tree().change_scene_to_file("res://world/zones/meadow_edge/meadow_edge.tscn")


func _on_settings_pressed() -> void:
	SfxManager.play("ui_button_click")
	_settings_screen.open()


func _on_difficulty_selected(_tier_id: int) -> void:
	_start_new_game()


func _on_quit_pressed() -> void:
	SfxManager.play("ui_button_click")
	get_tree().quit()
