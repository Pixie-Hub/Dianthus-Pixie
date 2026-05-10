class_name DevourerOmenLandmark
extends Area2D

const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_SUCCESS: int = 3
const NORMAL_ACCENT: Color = Color(0.96, 0.76, 0.28, 1.0)
const SUCCESS_ACCENT: Color = Color(0.48, 0.92, 0.62, 1.0)

@export var prompt_title: String = "Ancient Omen"
@export var prompt_body: String = "Decipher the Devourer omen."
@export var prompt_hint: String = "Press E to decipher"
@export var deciphered_body: String = "The breach-door warning is recorded."

@onready var _interaction_prompt: InteractionPrompt = $InteractionPrompt

var _player_in_range: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	QuestManager.decipher_devourer_omen()
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.show_interaction(
			prompt_title,
			deciphered_body,
			"",
			"",
			SUCCESS_ACCENT,
			PROMPT_STATUS_SUCCESS
		)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_hide_prompt()


func _refresh_prompt() -> void:
	if not _player_in_range or not is_instance_valid(_interaction_prompt):
		return
	_interaction_prompt.show_interaction(
		prompt_title,
		prompt_body,
		"E",
		prompt_hint,
		NORMAL_ACCENT,
		PROMPT_STATUS_NORMAL
	)


func _hide_prompt() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.hide_prompt()
