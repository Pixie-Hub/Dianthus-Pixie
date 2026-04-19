extends CanvasLayer

signal continue_pressed

@onready var _day_label: Label = %DayLabel
@onready var _rewards_label: Label = %RewardsLabel


func _ready() -> void:
	visible = false
	GameManager.night_survived.connect(_on_night_survived)


func _on_night_survived(day: int) -> void:
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return
	get_tree().paused = true
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
	get_tree().paused = false
	visible = false
	continue_pressed.emit()
	if DayNightCycle.is_night():
		DayNightCycle.debug_skip_phase()
