class_name ScoutTracks
extends Area2D

const INTERACTION_KEY: String = "interact"
const SCOUT_SFX: String = "codex_unlocked"
const INTEL_TEXT: String = "+1 Night Intel"
const ALREADY_USED_TEXT: String = "Already scouted"
const PROMPT_TEXT: String = "Press E to Scout"

var _is_player_nearby: bool = false
var _scouted_this_day: bool = false

@onready var _prompt_label: Label = %PromptLabel
@onready var _visual: ColorRect = %Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_nearby:
		return
	if not DayNightCycle.is_day():
		return
	if _scouted_this_day:
		return
	if event.is_action_pressed(INTERACTION_KEY):
		_do_scout()
		get_viewport().set_input_as_handled()


func _do_scout() -> void:
	_scouted_this_day = true

	SfxManager.play(SCOUT_SFX)

	var spawner: Node = get_tree().current_scene.find_child("WaveSpawner", true, false)
	var spawn_pos: Vector2 = Vector2.ZERO
	if spawner != null and spawner.has_method("predict_spawn_direction"):
		spawn_pos = spawner.predict_spawn_direction()

	if spawn_pos != Vector2.ZERO:
		var minimap: MapView = _find_minimap()
		if minimap != null:
			minimap.set_scouted_intel(spawn_pos)

	_show_floating_text(INTEL_TEXT)
	_refresh_prompt()
	_grey_out_visual()


func _find_minimap() -> MapView:
	var hud: Node = get_tree().current_scene.find_child("HUD", true, false)
	if hud == null:
		return null
	return hud.find_child("Minimap", true, false) as MapView


func _show_floating_text(text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	lbl.position = Vector2(-24, -32)
	add_child(lbl)
	var tween: Tween = create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 24.0, 0.8)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tween.tween_callback(lbl.queue_free)


func _grey_out_visual() -> void:
	if is_instance_valid(_visual):
		_visual.modulate = Color(0.5, 0.5, 0.5, 1.0)


func _refresh_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	if _scouted_this_day:
		_prompt_label.text = ALREADY_USED_TEXT
		_prompt_label.visible = _is_player_nearby
	else:
		_prompt_label.text = PROMPT_TEXT
		_prompt_label.visible = _is_player_nearby


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_nearby = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_nearby = false
		_refresh_prompt()


func _on_phase_changed(phase: String) -> void:
	if phase == "DAY":
		_scouted_this_day = false
		if is_instance_valid(_visual):
			_visual.modulate = Color.WHITE
		_refresh_prompt()
