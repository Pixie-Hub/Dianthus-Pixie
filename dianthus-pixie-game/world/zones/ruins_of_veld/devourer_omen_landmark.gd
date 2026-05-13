class_name DevourerOmenLandmark
extends Area2D

const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const PROMPT_STATUS_SUCCESS: int = 3
const STORY_QUEST_ID: StringName = &"story_05_devourer_omens"
const CUTSCENE_SCENE: PackedScene = preload("res://core/cutscenes/devourer_omen_decipher_cutscene.tscn")
const NORMAL_ACCENT: Color = Color(0.96, 0.76, 0.28, 1.0)
const DISABLED_ACCENT: Color = Color(0.68, 0.62, 0.52, 1.0)
const SUCCESS_ACCENT: Color = Color(0.48, 0.92, 0.62, 1.0)
const DECIPHERING_ACCENT: Color = Color(0.84, 0.34, 1.0, 1.0)

@export var prompt_title: String = "Ancient Omen"
@export var prompt_body: String = "Decipher the Devourer omen."
@export var prompt_hint: String = "Press E to decipher"
@export var inactive_body: String = "The root-script is silent for now."
@export var deciphering_body: String = "The glyphs are answering."
@export var deciphered_body: String = "The breach-door warning is recorded."

@onready var _interaction_prompt: InteractionPrompt = $InteractionPrompt
@onready var _stone_glyph: Sprite2D = $OmenStoneGlyph
@onready var _breach_glow: Polygon2D = $OmenBreachGlow

var _player_in_range: bool = false
var _is_deciphering: bool = false
var _is_deciphered: bool = false
var _active_cutscene: Node = null
var _visual_tween: Tween = null
var _base_glow_color: Color = Color(0.5, 0.12, 0.74, 0.32)


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	_base_glow_color = _breach_glow.color
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_is_deciphered = QuestManager.is_completed(STORY_QUEST_ID)
	_refresh_visual_state()
	_hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _is_deciphering:
		return
	if _is_deciphered or QuestManager.is_completed(STORY_QUEST_ID):
		_is_deciphered = true
		_refresh_visual_state()
		_refresh_prompt()
		return
	if not QuestManager.is_active(STORY_QUEST_ID):
		_refresh_prompt()
		return
	_start_decipher_cutscene()


func _exit_tree() -> void:
	if _visual_tween and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = null
	if is_instance_valid(_active_cutscene):
		if _active_cutscene.has_method("cancel"):
			_active_cutscene.cancel()
		else:
			_active_cutscene.queue_free()
	_active_cutscene = null


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
	if _is_deciphering:
		_interaction_prompt.show_interaction(
			prompt_title,
			deciphering_body,
			"",
			"",
			DECIPHERING_ACCENT,
			PROMPT_STATUS_NORMAL
		)
	elif _is_deciphered or QuestManager.is_completed(STORY_QUEST_ID):
		_is_deciphered = true
		_interaction_prompt.show_interaction(
			prompt_title,
			deciphered_body,
			"",
			"",
			SUCCESS_ACCENT,
			PROMPT_STATUS_SUCCESS
		)
	elif QuestManager.is_active(STORY_QUEST_ID):
		_interaction_prompt.show_interaction(
			prompt_title,
			prompt_body,
			"E",
			prompt_hint,
			NORMAL_ACCENT,
			PROMPT_STATUS_NORMAL
		)
	else:
		_interaction_prompt.show_interaction(
			prompt_title,
			inactive_body,
			"",
			"",
			DISABLED_ACCENT,
			PROMPT_STATUS_DISABLED
		)


func _hide_prompt() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.hide_prompt()


func _start_decipher_cutscene() -> void:
	_is_deciphering = true
	_hide_prompt()
	_refresh_visual_state()
	_active_cutscene = CUTSCENE_SCENE.instantiate()
	_active_cutscene.finished.connect(_on_cutscene_finished, CONNECT_ONE_SHOT)
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(_active_cutscene)


func _on_cutscene_finished() -> void:
	_active_cutscene = null
	_is_deciphering = false
	if not QuestManager.is_completed(STORY_QUEST_ID):
		QuestManager.decipher_devourer_omen()
	_is_deciphered = true
	_refresh_visual_state()
	_refresh_prompt()


func _refresh_visual_state() -> void:
	if _visual_tween and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = null

	if _is_deciphering:
		_breach_glow.visible = true
		_breach_glow.color = Color(0.76, 0.2, 1.0, 0.74)
		_stone_glyph.modulate = Color(1.0, 0.84, 1.0, 1.0)
		_start_glow_pulse(0.48, 0.86, 0.5)
	elif _is_deciphered:
		_breach_glow.visible = true
		_breach_glow.color = Color(0.72, 0.24, 0.96, 0.56)
		_stone_glyph.modulate = Color(1.0, 0.92, 0.72, 1.0)
	elif QuestManager.is_active(STORY_QUEST_ID):
		_breach_glow.visible = true
		_breach_glow.color = _base_glow_color
		_stone_glyph.modulate = Color.WHITE
		_start_glow_pulse(0.24, 0.42, 1.2)
	else:
		_breach_glow.visible = false
		_breach_glow.color = _base_glow_color
		_stone_glyph.modulate = Color(0.62, 0.58, 0.52, 1.0)


func _start_glow_pulse(min_alpha: float, max_alpha: float, duration: float) -> void:
	_visual_tween = create_tween().set_loops()
	_visual_tween.tween_property(_breach_glow, "color:a", max_alpha, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_visual_tween.tween_property(_breach_glow, "color:a", min_alpha, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
