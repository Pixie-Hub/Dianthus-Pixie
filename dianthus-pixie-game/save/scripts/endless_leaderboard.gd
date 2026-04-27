extends Node

const LEADERBOARD_PATH: String = "user://endless_leaderboard.json"
const MAX_ENTRIES: int = 10

var _scores: Array[Dictionary] = []


func _ready() -> void:
	_load()
	GameManager.game_over_triggered.connect(_on_game_over)


func _on_game_over() -> void:
	if not GameManager.endless_mode:
		return
	var rank: int = submit_score(DayNightCycle.day_count)
	print("[EndlessLeaderboard] Score submitted: Day %d — Rank #%d" % [DayNightCycle.day_count, rank])


func submit_score(day: int) -> int:
	var entry: Dictionary = {
		"day": day,
		"date_unix": int(Time.get_unix_time_from_system()),
	}
	_scores.append(entry)
	_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["day"] > b["day"])
	if _scores.size() > MAX_ENTRIES:
		_scores.resize(MAX_ENTRIES)
	_save()
	for i: int in range(_scores.size()):
		if _scores[i]["date_unix"] == entry["date_unix"] and _scores[i]["day"] == entry["day"]:
			return i + 1
	return 0


func get_scores() -> Array[Dictionary]:
	return _scores.duplicate()


func get_best_day() -> int:
	if _scores.is_empty():
		return 0
	return int(_scores[0]["day"])


func clear() -> void:
	_scores.clear()
	if FileAccess.file_exists(LEADERBOARD_PATH):
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove("endless_leaderboard.json")
	print("[EndlessLeaderboard] Cleared.")


func _save() -> void:
	var raw: Array = []
	for e: Dictionary in _scores:
		raw.append(e)
	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[EndlessLeaderboard] Failed to write leaderboard. Error: %d" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(raw, "\t"))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Array:
		return
	_scores.clear()
	for item: Variant in (parsed as Array):
		if item is Dictionary:
			_scores.append(item as Dictionary)
