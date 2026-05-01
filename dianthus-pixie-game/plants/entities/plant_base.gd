class_name PlantBase
extends StaticBody2D

signal plant_destroyed(plant: PlantBase)
signal hp_changed(current_hp: int, max_hp: int)
signal ability_triggered(plant: PlantBase, trigger_id: StringName)
signal vitality_changed(new_vitality: float)

const TEND_DURATION: float = 2.5
const TEND_RESTORE: float = 50.0
const TEND_COST_ITEM: String = "petal_shard"
const INTERACTION_RADIUS: float = 20.0

@export var max_hp: int = 30
@export var effect_radius: float = 24.0

var current_hp: int = 0
var is_destroyed: bool = false
var vitality: float = 100.0
var is_wilted: bool:
	get: return vitality <= 0.0

var _player_near_plant: bool = false
var _is_tending: bool = false
var _tend_tween: Tween = null
var _interaction_area: Area2D = null
var _prompt_label: Label = null
var _tend_progress: ProgressBar = null
var _base_modulate: Color = Color.WHITE

@onready var _sprite: Sprite2D = %Sprite2D


func _ready() -> void:
	current_hp = max_hp
	add_to_group(&"plants")
	collision_layer = CollisionLayers.INTERACTABLE
	collision_mask = 0
	_base_modulate = modulate
	_setup_interaction_area()
	_setup_tend_ui()
	DayNightCycle.phase_changed.connect(_on_plant_phase_changed)


func _setup_interaction_area() -> void:
	_interaction_area = Area2D.new()
	_interaction_area.name = "TendInteractArea"
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 4
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = INTERACTION_RADIUS
	shape_node.shape = circle
	_interaction_area.add_child(shape_node)
	add_child(_interaction_area)
	_interaction_area.body_entered.connect(_on_interact_body_entered)
	_interaction_area.body_exited.connect(_on_interact_body_exited)


func _setup_tend_ui() -> void:
	_prompt_label = Label.new()
	_prompt_label.name = "TendPromptLabel"
	_prompt_label.add_theme_font_size_override("font_size", 7)
	_prompt_label.position = Vector2(-50.0, -34.0)
	_prompt_label.z_index = 10
	_prompt_label.visible = false
	add_child(_prompt_label)

	_tend_progress = ProgressBar.new()
	_tend_progress.name = "TendProgressBar"
	_tend_progress.min_value = 0.0
	_tend_progress.max_value = TEND_DURATION
	_tend_progress.value = 0.0
	_tend_progress.custom_minimum_size = Vector2(48, 6)
	_tend_progress.position = Vector2(-24.0, -24.0)
	_tend_progress.z_index = 10
	_tend_progress.visible = false
	add_child(_tend_progress)


func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)
	_flash_damage()
	if current_hp <= 0:
		destroy()


func destroy() -> void:
	if is_destroyed:
		return
	_cancel_tending()
	is_destroyed = true
	SfxManager.play_at("plant_destroyed", global_position)
	plant_destroyed.emit(self)
	_play_wither_animation()


func _unhandled_input(event: InputEvent) -> void:
	if is_destroyed or not _player_near_plant:
		return
	if DayNightCycle.is_night():
		return
	if vitality >= 100.0:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		_start_tending()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("interact"):
		if _is_tending:
			_cancel_tending()
			get_viewport().set_input_as_handled()


func _on_interact_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_near_plant = true
		_update_tend_prompt()


func _on_interact_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_near_plant = false
		if is_instance_valid(_prompt_label):
			_prompt_label.visible = false
		if _is_tending:
			_cancel_tending()


func _start_tending() -> void:
	if _is_tending:
		return
	if not InventoryManager.has_item(TEND_COST_ITEM, 1):
		if is_instance_valid(_prompt_label):
			_prompt_label.text = "Need 1 Petal Shard!"
			var reset_tween: Tween = create_tween()
			reset_tween.tween_interval(1.5)
			reset_tween.tween_callback(_update_tend_prompt)
		return
	_is_tending = true
	if is_instance_valid(_tend_progress):
		_tend_progress.value = 0.0
		_tend_progress.visible = true
	if is_instance_valid(_tend_tween) and _tend_tween.is_running():
		_tend_tween.kill()
	_tend_tween = create_tween()
	_tend_tween.tween_property(_tend_progress, "value", TEND_DURATION, TEND_DURATION)
	_tend_tween.tween_callback(_finish_tending)


func _cancel_tending() -> void:
	_is_tending = false
	if is_instance_valid(_tend_tween) and _tend_tween.is_running():
		_tend_tween.kill()
	_tend_tween = null
	if is_instance_valid(_tend_progress):
		_tend_progress.visible = false
		_tend_progress.value = 0.0
	_update_tend_prompt()


func _finish_tending() -> void:
	_is_tending = false
	_tend_tween = null
	if is_instance_valid(_tend_progress):
		_tend_progress.visible = false
		_tend_progress.value = 0.0
	if not InventoryManager.has_item(TEND_COST_ITEM, 1):
		_update_tend_prompt()
		return
	InventoryManager.remove_item(TEND_COST_ITEM, 1)
	vitality = minf(vitality + TEND_RESTORE, 100.0)
	vitality_changed.emit(vitality)
	_update_vitality_visual()
	_update_tend_prompt()


func _apply_overnight_decay() -> void:
	if is_destroyed:
		return
	var decay: float = _get_overnight_decay_amount()
	vitality = maxf(vitality - decay, 0.0)
	vitality_changed.emit(vitality)
	_update_vitality_visual()


func _get_overnight_decay_amount() -> float:
	match DifficultyManager.get_tier_label().to_lower():
		"easy": return 15.0
		"hard": return 25.0
		_: return 20.0


func _on_plant_phase_changed(phase: String) -> void:
	if phase == "DAY" and DayNightCycle.day_count > 1:
		_apply_overnight_decay()
	_update_tend_prompt()


func _update_tend_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	if _player_near_plant and not DayNightCycle.is_night() and vitality < 100.0 and not is_destroyed:
		_prompt_label.text = "Hold E: Tend (1x Petal Shard)"
		_prompt_label.visible = true
	else:
		_prompt_label.visible = false


func _update_vitality_visual() -> void:
	var wilted_color: Color = Color(0.45, 0.38, 0.30, 1.0)
	var t: float = 1.0 - (vitality / 100.0)
	modulate = _base_modulate.lerp(wilted_color, t * t)


func _report_ability_triggered(trigger_id: StringName) -> void:
	if is_destroyed:
		return
	ability_triggered.emit(self, trigger_id)


func _flash_damage() -> void:
	if not is_instance_valid(_sprite):
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(_sprite, "modulate", _sprite.modulate, 0.15)


func _play_wither_animation() -> void:
	if not is_instance_valid(_sprite):
		queue_free()
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
