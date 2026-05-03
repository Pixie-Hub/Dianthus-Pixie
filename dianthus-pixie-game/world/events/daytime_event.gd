class_name DaytimeEvent
extends Area2D

signal event_completed(event_id: StringName)
signal event_failed(event_id: StringName)
signal event_despawned(event_id: StringName)

const INTERACT_RADIUS: float = 28.0
const DESPAWN_WARNING_TIME: float = 30.0
const INTERACTION_PROMPT_SCENE: PackedScene = preload("res://ui/components/interaction_prompt.tscn")
const PROMPT_STATUS_NORMAL: int = 0

@export var event_id: StringName = &""
@export var event_display_name: String = "Event"
@export var event_color: Color = Color(1.0, 0.85, 0.2, 1.0)

var _is_active: bool = false
var _player_in_range: bool = false
var _is_complete: bool = false
var _prompt_progress: float = -1.0

@onready var _visual: ColorRect = $Visual
@onready var _prompt_label: Label = %PromptLabel
@onready var _interaction_shape: CollisionShape2D = $InteractionShape

var _interaction_prompt = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_visual.color = event_color
	_setup_interaction_prompt()
	_update_prompt("")


func activate() -> void:
	_is_active = true
	show()
	_on_activated()


func deactivate() -> void:
	_is_active = false
	event_despawned.emit(event_id)
	queue_free()


func _on_activated() -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		_on_player_enter()


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_on_player_exit()


func _on_player_enter() -> void:
	pass


func _on_player_exit() -> void:
	_update_prompt("")


func _on_phase_changed(phase: String) -> void:
	if phase == "NIGHT":
		deactivate()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active or _is_complete or not _player_in_range:
		return
	_handle_input(event)


func _handle_input(_event: InputEvent) -> void:
	pass


func _finish_event() -> void:
	_is_complete = true
	_give_reward()
	event_completed.emit(event_id)
	SfxManager.play("quest_completed")
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _give_reward() -> void:
	pass


func _setup_interaction_prompt() -> void:
	if is_instance_valid(_prompt_label):
		_prompt_label.visible = false
	_interaction_prompt = get_node_or_null("%InteractionPrompt")
	if _interaction_prompt == null:
		_interaction_prompt = INTERACTION_PROMPT_SCENE.instantiate()
		_interaction_prompt.name = "InteractionPrompt"
		add_child(_interaction_prompt)


func _update_prompt(text: String) -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.show_message(text, event_color, PROMPT_STATUS_NORMAL, _prompt_progress)
	elif is_instance_valid(_prompt_label):
		_prompt_label.text = text
		_prompt_label.visible = not text.is_empty()


func _set_prompt_progress(ratio: float) -> void:
	_prompt_progress = ratio
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.set_progress(ratio)


func get_world_position() -> Vector2:
	return global_position
