class_name ZoneTransitionGate
extends Area2D

const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const AVAILABLE_ACCENT: Color = Color(0.58, 0.86, 0.62, 1.0)
const DISABLED_ACCENT: Color = Color(0.62, 0.62, 0.62, 1.0)

@export_file("*.tscn") var target_scene: String = ""
@export var target_entry_marker: StringName = &""
@export var required_day: int = 1
@export var required_unlock_flag: StringName = &""
@export var required_active_quest: StringName = &""
@export var display_name: String = "Zone"
@export var prompt_body: String = "Travel to this zone."
@export var disabled_prompt: String = ""

@onready var _interaction_prompt: InteractionPrompt = $InteractionPrompt

var _player_in_range: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if not _can_transition():
		_refresh_prompt()
		return
	_hide_prompt()
	SceneTransition.transition_to(target_scene, target_entry_marker)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_hide_prompt()


func _on_phase_changed(_phase: String) -> void:
	if _player_in_range:
		_refresh_prompt()


func _can_transition() -> bool:
	if target_scene.is_empty():
		return false
	if DayNightCycle.day_count < required_day:
		return false
	if DayNightCycle.is_night() or GameManager.current_state == GameManager.GameState.DEFENSE:
		return false
	if not _has_story_access():
		return false
	return true


func _has_story_access() -> bool:
	if required_unlock_flag == &"":
		return true
	if UnlockFlags.has_flag(str(required_unlock_flag)):
		return true
	return required_active_quest != &"" and QuestManager.is_active(required_active_quest)


func _refresh_prompt() -> void:
	if not _player_in_range or not is_instance_valid(_interaction_prompt):
		return
	if _can_transition():
		_interaction_prompt.show_interaction(
			display_name,
			prompt_body,
			"E",
			"Press E to travel",
			AVAILABLE_ACCENT,
			PROMPT_STATUS_NORMAL
		)
		return
	_interaction_prompt.show_interaction(
		display_name,
		_get_disabled_text(),
		"",
		"",
		DISABLED_ACCENT,
		PROMPT_STATUS_DISABLED
	)


func _get_disabled_text() -> String:
	if DayNightCycle.is_night() or GameManager.current_state == GameManager.GameState.DEFENSE:
		return "Unavailable during night defense."
	if DayNightCycle.day_count < required_day:
		if not disabled_prompt.is_empty():
			return disabled_prompt
		return "Requires Day %d" % required_day
	if not _has_story_access():
		if not disabled_prompt.is_empty():
			return disabled_prompt
		return "Requires story progress."
	return "Path unavailable."


func _hide_prompt() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.hide_prompt()
