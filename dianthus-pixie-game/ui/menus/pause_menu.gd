extends CanvasLayer

signal paused
signal resumed

@warning_ignore("unused_private_class_variable")
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
	SfxManager.play("screen_open")
	_is_open = true
	visible = true
	PauseManager.request_pause(self)
	_save_btn.disabled = GameManager.current_state != GameManager.GameState.EXPLORATION
	paused.emit()


func _close() -> void:
	SfxManager.play("screen_close")
	_is_open = false
	visible = false
	_save_feedback.visible = false
	PauseManager.release_pause(self)
	resumed.emit()


func _on_resume_pressed() -> void:
	_close()


func _on_save_pressed() -> void:
	SfxManager.play("ui_button_click")
	SaveManager.save_to_slot(true)


func _on_save_completed(success: bool, manual: bool) -> void:
	if not manual:
		return
	_save_feedback.visible = true
	_save_feedback.text = "Saved!" if success else "Cannot save during night."
	var tw: Tween = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(2.0)
	tw.tween_callback(func() -> void: _save_feedback.visible = false)


func _on_settings_pressed() -> void:
	SfxManager.play("ui_button_click")
	_settings_screen.open()


func _on_main_menu_pressed() -> void:
	SfxManager.play("ui_button_click")
	SfxManager.play("screen_open")
	_main_menu_dialog.popup_centered()


func _on_main_menu_confirmed() -> void:
	SfxManager.play("ui_button_click")
	_is_open = false
	visible = false
	PauseManager.clear_all()
	SaveManager.save_to_slot(false)
	print("[PauseMenu] Returning to main menu.")
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
