extends CanvasLayer

@onready var _days_label: Label = %DaysLabel

var _leaderboard_container: VBoxContainer = null


func _ready() -> void:
	visible = false
	GameManager.game_over_triggered.connect(_on_game_over)
	_leaderboard_container = VBoxContainer.new()
	_leaderboard_container.name = "LeaderboardContainer"
	%DaysLabel.get_parent().add_child(_leaderboard_container)


func _on_game_over() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameManager.endless_mode:
		var day: int = DayNightCycle.day_count
		_days_label.text = "ENDLESS MODE — Day %d" % day
		var rank: int = EndlessLeaderboard.submit_score(day)
		_show_leaderboard(rank)
	else:
		_days_label.text = "You survived %d day%s" % [DayNightCycle.day_count, "s" if DayNightCycle.day_count != 1 else ""]
		_clear_leaderboard()
	visible = true


func _show_leaderboard(rank: int) -> void:
	_clear_leaderboard()
	var rank_label: Label = Label.new()
	if rank >= 1:
		rank_label.text = "New Record!  Rank #%d" % rank if rank <= EndlessLeaderboard.MAX_ENTRIES else "Rank #%d" % rank
	else:
		rank_label.text = "Best: Day %d" % EndlessLeaderboard.get_best_day()
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leaderboard_container.add_child(rank_label)
	var sep: HSeparator = HSeparator.new()
	_leaderboard_container.add_child(sep)
	var top_label: Label = Label.new()
	top_label.text = "— Top Scores —"
	top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leaderboard_container.add_child(top_label)
	var scores: Array[Dictionary] = EndlessLeaderboard.get_scores()
	var shown: int = min(5, scores.size())
	for i: int in range(shown):
		var entry: Dictionary = scores[i]
		var entry_label: Label = Label.new()
		entry_label.text = "#%d  Day %d" % [i + 1, int(entry["day"])]
		entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_leaderboard_container.add_child(entry_label)


func _clear_leaderboard() -> void:
	if _leaderboard_container == null:
		return
	for child: Node in _leaderboard_container.get_children():
		child.queue_free()


func _on_restart() -> void:
	SfxManager.play("ui_button_click")
	get_tree().paused = false
	visible = false
	GameManager.endless_mode = false
	DayNightCycle.day_count = 1
	DayNightCycle.current_phase = DayNightCycle.Phase.DAY
	GameManager.current_state = GameManager.GameState.EXPLORATION
	get_tree().reload_current_scene()


func _on_main_menu() -> void:
	SfxManager.play("ui_button_click")
	if GameManager.endless_mode:
		EndlessLeaderboard.submit_score(DayNightCycle.day_count)
	GameManager.endless_mode = false
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
