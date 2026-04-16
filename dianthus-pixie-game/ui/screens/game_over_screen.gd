extends CanvasLayer

@onready var _days_label: Label = %DaysLabel


func _ready() -> void:
	visible = false
	GameManager.game_over_triggered.connect(_on_game_over)


func _on_game_over() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_days_label.text = "You survived %d day%s" % [DayNightCycle.day_count, "s" if DayNightCycle.day_count != 1 else ""]
	visible = true


func _on_restart() -> void:
	get_tree().paused = false
	visible = false
	DayNightCycle.day_count = 1
	DayNightCycle.current_phase = DayNightCycle.Phase.MORNING
	GameManager.current_state = GameManager.GameState.EXPLORATION
	get_tree().reload_current_scene()


func _on_main_menu() -> void:
	get_tree().paused = false
	visible = false
	# TODO: Replace with SceneTransition.transition_to("res://ui/menus/main_menu.tscn") when main menu exists.
	get_tree().reload_current_scene()
