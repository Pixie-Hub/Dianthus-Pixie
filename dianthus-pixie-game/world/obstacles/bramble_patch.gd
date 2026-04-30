class_name BramblePatch
extends StaticBody2D

signal cleared(bramble_id: StringName)
signal hp_changed(current_hp: int, max_hp: int)

@export var bramble_id: StringName = &""
@export var max_hp: int = 30

var current_hp: int = 0
var is_cleared: bool = false

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	current_hp = max_hp
	collision_layer = CollisionLayers.TERRAIN | CollisionLayers.ENEMY
	collision_mask = 0
	add_to_group(&"brambles")
	add_to_group(&"obstacles")


func take_damage(amount: int) -> void:
	if is_cleared:
		return
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)
	_flash_damage()
	if current_hp <= 0:
		_clear()


func _clear() -> void:
	if is_cleared:
		return
	is_cleared = true
	collision_layer = 0
	collision_mask = 0
	if is_instance_valid(_collision_shape):
		_collision_shape.set_deferred("disabled", true)
	SfxManager.play_at("beringin_wall_break", global_position)
	cleared.emit(bramble_id)

	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.28)
	fade_tween.tween_property(self, "scale", scale * 0.86, 0.28)
	fade_tween.chain().tween_callback(queue_free)


func _flash_damage() -> void:
	if is_cleared:
		return
	var original_modulate: Color = modulate
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.35, 0.25, original_modulate.a), 0.05)
	flash_tween.tween_property(self, "modulate", original_modulate, 0.12)
