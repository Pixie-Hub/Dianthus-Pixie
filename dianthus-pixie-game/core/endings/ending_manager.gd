extends Node

signal ending_triggered(ending_id: String)  # "true", "survival", "discovery"

const TRUE_ENDING_DAY_THRESHOLD: int = 30
const SURVIVAL_ENDING_DAY_THRESHOLD: int = 20

var _ending_fired: bool = false


func _ready() -> void:
	GameManager.night_survived.connect(_on_night_survived)
	UnlockFlags.flag_set.connect(_on_flag_set)


func force_trigger(ending_id: String) -> void:
	_ending_fired = false
	_fire(ending_id)


func _on_night_survived(_day: int) -> void:
	call_deferred("_try_fire")


func _on_flag_set(flag_name: String) -> void:
	if flag_name in [
		StoryEndingFlags.flag_story_devourer_defeated,
		StoryEndingFlags.flag_discovery_complete,
		StoryEndingFlags.flag_story_complete,
	]:
		call_deferred("_try_fire")


func _try_fire() -> void:
	if _ending_fired:
		return
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return
	var eid: String = _resolve_ending()
	if eid.is_empty():
		return
	_fire(eid)


func _fire(ending_id: String) -> void:
	_ending_fired = true
	match ending_id:
		"true":
			UnlockFlags.set_flag(StoryEndingFlags.flag_ending_seen_true)
			UnlockFlags.set_flag(StoryEndingFlags.unlock_endless_mode)
		"survival":
			UnlockFlags.set_flag(StoryEndingFlags.flag_ending_seen_survival)
		"discovery":
			UnlockFlags.set_flag(StoryEndingFlags.flag_ending_seen_discovery)
	print("[EndingManager] Ending fired: %s" % ending_id)
	ending_triggered.emit(ending_id)
	GameManager.ending_triggered.emit(ending_id)


func _resolve_ending() -> String:
	if UnlockFlags.has_flag(StoryEndingFlags.flag_ending_seen_true) \
			or UnlockFlags.has_flag(StoryEndingFlags.flag_ending_seen_discovery) \
			or UnlockFlags.has_flag(StoryEndingFlags.flag_ending_seen_survival):
		return ""
	if UnlockFlags.has_flag(StoryEndingFlags.flag_story_devourer_defeated) \
			and DayNightCycle.day_count >= TRUE_ENDING_DAY_THRESHOLD:
		return "true"
	if UnlockFlags.has_flag(StoryEndingFlags.flag_discovery_complete):
		return "discovery"
	if DayNightCycle.day_count >= SURVIVAL_ENDING_DAY_THRESHOLD \
			and not UnlockFlags.has_flag(StoryEndingFlags.flag_story_complete) \
			and not UnlockFlags.has_flag(StoryEndingFlags.flag_story_devourer_defeated):
		return "survival"
	return ""
	# TODO: END-ALT — alt-ending flags (flag_alt_ending_lost/shadow/lingering)
