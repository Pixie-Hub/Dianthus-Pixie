extends StaticBody2D

@onready var _prompt_label: Label = $PromptLabel
@onready var _interaction_zone: Area2D = $InteractionZone
@onready var _bench_visual: ColorRect = $BenchVisual

var _player_in_range: bool = false
var _tutorial_hint_tween: Tween = null
var _quest_hint_tween: Tween = null
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
	QuestManager.quest_tracked.connect(_on_quest_tracked_bench)
	QuestManager.quest_untracked.connect(_refresh_quest_highlight)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated_bench)
	QuestManager.quest_completed.connect(_on_quest_completed_bench)
	QuestManager.quest_failed.connect(_on_quest_failed_bench)
	_refresh_quest_highlight()


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
		if is_instance_valid(_quest_hint_tween):
			_quest_hint_tween.kill()
			_quest_hint_tween = null
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
	_refresh_quest_highlight()


func set_quest_highlight_active(active: bool) -> void:
	if active:
		if is_instance_valid(_tutorial_hint_tween):
			return
		if is_instance_valid(_quest_hint_tween):
			return
		_bench_visual.color = Color(0.12, 0.55, 0.52, 1.0)
		_quest_hint_tween = create_tween().set_loops()
		_quest_hint_tween.tween_property(_bench_visual, "color", Color(0.25, 0.95, 0.85, 1.0), 0.55)
		_quest_hint_tween.tween_property(_bench_visual, "color", Color(0.08, 0.40, 0.38, 1.0), 0.55)
		return
	if is_instance_valid(_quest_hint_tween):
		_quest_hint_tween.kill()
	_quest_hint_tween = null
	if not is_instance_valid(_tutorial_hint_tween):
		_bench_visual.color = _base_visual_color


func _refresh_quest_highlight() -> void:
	var tracked_id: StringName = QuestManager.get_tracked_quest()
	if tracked_id == &"":
		set_quest_highlight_active(false)
		return
	var quest: QuestData = QuestManager.get_quest_data(tracked_id)
	if quest == null:
		set_quest_highlight_active(false)
		return
	var prog: Dictionary = QuestManager.get_progress(tracked_id)
	for obj: QuestObjective in quest.objectives:
		if obj.event_id != &"weapon_crafted" and obj.event_id != &"plant_bred":
			continue
		var obj_data: Variant = prog.get(obj.objective_id)
		var current: int = 0
		if obj_data is Dictionary:
			current = int((obj_data as Dictionary).get("current", 0))
		if current < obj.target_count:
			set_quest_highlight_active(true)
			return
	set_quest_highlight_active(false)


func _on_quest_tracked_bench(_quest_id: StringName) -> void:
	_refresh_quest_highlight()


func _on_quest_progress_updated_bench(
		quest_id: StringName,
		_obj_id: StringName,
		_current: int,
		_target: int) -> void:
	if quest_id == QuestManager.get_tracked_quest():
		_refresh_quest_highlight()


func _on_quest_completed_bench(quest_id: StringName) -> void:
	if quest_id == QuestManager.get_tracked_quest():
		set_quest_highlight_active(false)


func _on_quest_failed_bench(quest_id: StringName, _reason: String) -> void:
	if quest_id == QuestManager.get_tracked_quest():
		set_quest_highlight_active(false)
