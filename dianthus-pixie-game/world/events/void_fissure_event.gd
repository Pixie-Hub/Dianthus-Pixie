class_name VoidFissureEvent
extends DaytimeEvent

const CHALLENGE_DURATION: float = 10.0
const SAFE_RADIUS: float = 40.0
const SHADOW_COUNT: int = 3
const SHADOW_HP: int = 12
const SHADOW_DAMAGE: int = 4
const SHADOW_SPEED: float = 48.0
const SHADOW_SPAWN_RADIUS: float = 64.0

var _challenge_active: bool = false
var _challenge_timer: float = 0.0
var _shadows: Array[Node2D] = []
var _left_zone: bool = false

@onready var _radius_visual: ColorRect = %RadiusVisual
@onready var _timer_label: Label = %TimerLabel


func _ready() -> void:
	event_id = &"void_fissure"
	event_display_name = "Void Fissure"
	event_color = Color(0.15, 0.05, 0.35, 1.0)
	super._ready()


func _on_player_enter() -> void:
	if not _challenge_active:
		_update_prompt("[E] Enter Fissure (10s survival = RARE reward)")


func _on_player_exit() -> void:
	if not _challenge_active:
		_update_prompt("")


func _process(delta: float) -> void:
	if not _is_active or _is_complete:
		return
	if not _challenge_active:
		return
	_challenge_timer -= delta
	if is_instance_valid(_timer_label):
		_timer_label.text = "%.0fs" % maxf(_challenge_timer, 0.0)
	var player: Node2D = GameManager.player as Node2D
	if is_instance_valid(player):
		var dist: float = player.global_position.distance_to(global_position)
		if dist > SAFE_RADIUS:
			_fail_challenge()
			return
	_clean_dead_shadows()
	if _challenge_timer <= 0.0:
		_succeed_challenge()


func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not _challenge_active:
		_start_challenge()
		get_viewport().set_input_as_handled()


func _start_challenge() -> void:
	_challenge_active = true
	_challenge_timer = CHALLENGE_DURATION
	_left_zone = false
	if is_instance_valid(_radius_visual):
		_radius_visual.visible = true
	if is_instance_valid(_timer_label):
		_timer_label.visible = true
	_update_prompt("Stay inside circle!")
	SfxManager.play("wave_start")
	for i: int in range(SHADOW_COUNT):
		_spawn_shadow()


func _spawn_shadow() -> void:
	var angle: float = randf_range(0.0, TAU)
	var spawn_pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * SHADOW_SPAWN_RADIUS
	var shadow: CharacterBody2D = _build_shadow_enemy()
	shadow.global_position = spawn_pos
	var ysort: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	if ysort != null:
		ysort.add_child(shadow)
	else:
		get_tree().current_scene.add_child(shadow)
	_shadows.append(shadow)


func _build_shadow_enemy() -> CharacterBody2D:
	var shadow: CharacterBody2D = CharacterBody2D.new()
	shadow.add_to_group(&"enemies")
	shadow.add_to_group(&"void_fissure_shadows")
	shadow.collision_layer = CollisionLayers.ENEMY
	shadow.collision_mask = CollisionLayers.PLAYER

	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(10, 10)
	visual.position = Vector2(-5, -5)
	visual.color = Color(0.4, 0.0, 0.6, 0.9)
	shadow.add_child(visual)

	var shape_owner: CollisionShape2D = CollisionShape2D.new()
	var circ: CircleShape2D = CircleShape2D.new()
	circ.radius = 6.0
	shape_owner.shape = circ
	shadow.add_child(shape_owner)

	shadow.set_meta(&"hp", SHADOW_HP)
	shadow.set_meta(&"damage", SHADOW_DAMAGE)
	shadow.set_meta(&"speed", SHADOW_SPEED)
	shadow.set_meta(&"attack_cooldown", 0.0)
	shadow.set_meta(&"is_fissure_shadow", true)
	shadow.set_script(preload("res://world/events/fissure_shadow_ai.gd"))
	return shadow


func _clean_dead_shadows() -> void:
	var alive: Array[Node2D] = []
	for s: Node2D in _shadows:
		if is_instance_valid(s):
			alive.append(s)
	_shadows = alive


func _fail_challenge() -> void:
	_challenge_active = false
	_cleanup_shadows()
	if is_instance_valid(_radius_visual):
		_radius_visual.visible = false
	if is_instance_valid(_timer_label):
		_timer_label.visible = false
	event_failed.emit(event_id)
	_show_fail_popup("Left the circle — failed!")
	SfxManager.play("quest_failed")
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	_is_complete = true


func _succeed_challenge() -> void:
	_challenge_active = false
	_cleanup_shadows()
	if is_instance_valid(_radius_visual):
		_radius_visual.visible = false
	if is_instance_valid(_timer_label):
		_timer_label.visible = false
	_finish_event()


func _cleanup_shadows() -> void:
	for s: Node2D in _shadows:
		if is_instance_valid(s):
			s.remove_from_group(&"enemies")
			s.queue_free()
	_shadows.clear()


func _give_reward() -> void:
	var rare_items: Array[String] = ["aether_bloom", "dianthus_pollen", "kecombrang_extract"]
	var chosen: String = rare_items[randi() % rare_items.size()]
	InventoryManager.add_item(chosen, 1)
	var item_name: String = ItemDatabase.get_display_name(chosen)
	_show_reward_popup("Rare reward: %s!" % item_name)
	QuestManager.report_event(&"item_collected", 1, {item_id = chosen})


func _show_reward_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-56, -32)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 1.4)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.4)
	tween.tween_callback(label.queue_free)


func _show_fail_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-56, -32)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(label.queue_free)
