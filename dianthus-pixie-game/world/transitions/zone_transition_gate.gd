class_name ZoneTransitionGate
extends Area2D

const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const AVAILABLE_ACCENT: Color = Color(0.58, 0.86, 0.62, 1.0)
const DISABLED_ACCENT: Color = Color(0.62, 0.62, 0.62, 1.0)
const MEADOW_EDGE_SCENE: String = "res://world/zones/meadow_edge/meadow_edge.tscn"

@export_file("*.tscn") var target_scene: String = ""
@export var target_entry_marker: StringName = &""
@export var required_day: int = 1
@export var required_unlock_flag: StringName = &""
@export var required_active_quest: StringName = &""
@export var display_name: String = "Zone"
@export var prompt_body: String = "Travel to this zone."
@export var disabled_prompt: String = ""
@export var allow_night_return_to_defense: bool = false
@export_file("*.tscn") var night_return_target_scene: String = ""
@export var night_return_entry_marker: StringName = &""
@export var night_return_prompt: String = "Return to defend the Dianthus Core."

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
	SceneTransition.transition_to(
		_get_effective_target_scene(),
		_get_effective_entry_marker(),
		_is_defense_return_available()
	)


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
	if _get_effective_target_scene().is_empty():
		return false
	if DayNightCycle.day_count < required_day:
		return false
	if not _has_story_access():
		return false
	if DayNightCycle.is_night() or GameManager.current_state == GameManager.GameState.DEFENSE:
		return _is_defense_return_available()
	return true


func _is_defense_return_available() -> bool:
	return allow_night_return_to_defense \
		and (DayNightCycle.is_night() or GameManager.current_state == GameManager.GameState.DEFENSE) \
		and _is_meadow_edge_target(_get_effective_target_scene())


func _get_effective_target_scene() -> String:
	if DayNightCycle.is_night() or GameManager.current_state == GameManager.GameState.DEFENSE:
		if allow_night_return_to_defense and not night_return_target_scene.is_empty():
			return night_return_target_scene
	return target_scene


func _get_effective_entry_marker() -> StringName:
	if DayNightCycle.is_night() or GameManager.current_state == GameManager.GameState.DEFENSE:
		if allow_night_return_to_defense and night_return_entry_marker != &"":
			return night_return_entry_marker
	return target_entry_marker


func _is_meadow_edge_target(scene_path: String) -> bool:
	if scene_path == MEADOW_EDGE_SCENE:
		return true
	if scene_path.begins_with("uid://"):
		var uid: int = ResourceUID.text_to_id(scene_path)
		if uid >= 0:
			return ResourceUID.get_id_path(uid) == MEADOW_EDGE_SCENE
	return false


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
		var body: String = night_return_prompt if _is_defense_return_available() else prompt_body
		var action: String = "Press E to return" if _is_defense_return_available() else "Press E to travel"
		_interaction_prompt.show_interaction(
			display_name,
			body,
			"E",
			action,
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
