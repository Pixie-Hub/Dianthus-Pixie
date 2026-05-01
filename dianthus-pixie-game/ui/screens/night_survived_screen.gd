extends CanvasLayer

signal continue_pressed

const TUTORIAL_STATE_DAY_1_COMBAT: int = 6

@onready var _day_label: Label = %DayLabel
@onready var _rewards_label: Label = %RewardsLabel

var _pending_day: int = -1
var _waiting_for_dialog: bool = false


func _ready() -> void:
	visible = false
	GameManager.night_survived.connect(_on_night_survived)


func _on_night_survived(day: int) -> void:
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return
	if not is_inside_tree():
		return
	_pending_day = day
	if _should_advance_phase_before_showing():
		DayNightCycle.debug_skip_phase()
		await DayNightCycle.phase_changed
	_show_after_dialog_ends()


func _should_advance_phase_before_showing() -> bool:
	if not DayNightCycle.is_night():
		return false
	var tutorial_manager: Node = get_node_or_null("/root/TutorialManager")
	if tutorial_manager == null:
		return false
	var tutorial_state: int = int(tutorial_manager.get("current_state"))
	return tutorial_state == TUTORIAL_STATE_DAY_1_COMBAT


func _show_after_dialog_ends() -> void:
	if _waiting_for_dialog:
		return
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic != null and dialogic.has_signal("timeline_ended") and dialogic.get("current_timeline") != null:
		_waiting_for_dialog = true
		dialogic.connect("timeline_ended", _on_dialogic_timeline_ended, CONNECT_ONE_SHOT)
		return
	_show_pending_night_survived()


func _on_dialogic_timeline_ended() -> void:
	_waiting_for_dialog = false
	_show_pending_night_survived()


func _show_pending_night_survived() -> void:
	if _pending_day < 0:
		return
	var day: int = _pending_day
	_pending_day = -1
	SfxManager.play("night_survived")
	PauseManager.request_pause(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_day_label.text = "Day %d Complete" % day
	_rewards_label.text = _generate_rewards_text()
	visible = true


func _generate_rewards_text() -> String:
	var common_count: int = randi_range(3, 5)
	InventoryManager.add_item("petal_shard", common_count)
	InventoryManager.add_item("verdant_sap", 1)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("+ %d Petal Shard" % common_count)
	lines.append("+ 1 Verdant Sap")
	return "\n".join(lines)


func _on_continue() -> void:
	SfxManager.play("ui_button_click")
	PauseManager.release_pause(self)
	visible = false
	continue_pressed.emit()
	if DayNightCycle.is_night():
		DayNightCycle.debug_skip_phase()
