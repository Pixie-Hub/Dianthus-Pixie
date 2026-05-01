class_name ThornBarricade
extends StaticBody2D

const MAX_HP: int = 60
const HIT_FLASH_DURATION: float = 0.1

var _current_hp: int = MAX_HP

@onready var _visual: ColorRect = $Visual
@onready var _hp_bar: ColorRect = %HpBar
@onready var _hp_bar_bg: ColorRect = %HpBarBg


func _ready() -> void:
	collision_layer = CollisionLayers.INTERACTABLE | CollisionLayers.TERRAIN
	collision_mask = 0
	_update_hp_bar()
	_setup_enemy_hit_detection()


func _setup_enemy_hit_detection() -> void:
	var area: Area2D = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = CollisionLayers.ENEMY
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(24.0, 8.0)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(_on_enemy_entered)
	add_child(area)


func _on_enemy_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(0)
	take_damage(body.get("damage") if body.get("damage") != null else 8)


func take_damage(amount: int) -> void:
	_current_hp = max(_current_hp - amount, 0)
	_update_hp_bar()
	_flash()
	SfxManager.play_at("enemy_hit", global_position, 0.1)
	if _current_hp <= 0:
		_break()


func _break() -> void:
	SfxManager.play_at("plant_destroyed", global_position)
	queue_free()


func _flash() -> void:
	if not is_instance_valid(_visual):
		return
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color(1.0, 0.3, 0.3, 1.0), HIT_FLASH_DURATION)
	tween.tween_property(_visual, "modulate", Color.WHITE, HIT_FLASH_DURATION)


func _update_hp_bar() -> void:
	if not is_instance_valid(_hp_bar) or not is_instance_valid(_hp_bar_bg):
		return
	_hp_bar.size.x = _hp_bar_bg.size.x * (float(_current_hp) / float(MAX_HP))
