extends StaticBody2D

@onready var _prompt_label: Label = $PromptLabel
@onready var _interaction_zone: Area2D = $InteractionZone
@onready var _bench_visual: ColorRect = $BenchVisual

var _player_in_range: bool = false
var _tutorial_hint_tween: Tween = null
var _base_visual_color: Color = Color.WHITE


func _ready() -> void:
	add_to_group("breeding_benches")
	collision_layer = CollisionLayers.INTERACTABLE
	collision_mask = 0
	_base_visual_color = _bench_visual.color
	_prompt_label.visible = false
	_interaction_zone.body_entered.connect(_on_body_entered)
	_interaction_zone.body_exited.connect(_on_body_exited)
	if TutorialManager.is_phase_2_active():
		set_tutorial_hint_active(true)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		if DayNightCycle.is_night():
			print("[BreedingBench] Cannot craft at night.")
			return
		var screen: Node = get_tree().current_scene.find_child("CrossBreedingScreen", true, false)
		if screen != null and screen.has_method("open"):
			screen.open()
			TutorialManager.report_crafting_bench_opened()
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		_prompt_label.visible = true
		TutorialManager.report_breeding_bench_range_changed(true)


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_prompt_label.visible = false
		TutorialManager.report_breeding_bench_range_changed(false)


func set_tutorial_hint_active(active: bool) -> void:
	if active:
		if _player_in_range:
			TutorialManager.report_breeding_bench_range_changed(true)
		if is_instance_valid(_tutorial_hint_tween):
			return
		_bench_visual.color = Color(0.95, 0.72, 0.18, 1.0)
		_tutorial_hint_tween = create_tween().set_loops()
		_tutorial_hint_tween.tween_property(_bench_visual, "color", Color(1.0, 0.92, 0.38, 1.0), 0.45)
		_tutorial_hint_tween.tween_property(_bench_visual, "color", Color(0.65, 0.38, 0.12, 1.0), 0.45)
		return
	if is_instance_valid(_tutorial_hint_tween):
		_tutorial_hint_tween.kill()
	_tutorial_hint_tween = null
	_bench_visual.color = _base_visual_color
