class_name PlantBase
extends StaticBody2D

signal plant_destroyed(plant: PlantBase)
signal hp_changed(current_hp: int, max_hp: int)

@export var max_hp: int = 30
@export var effect_radius: float = 24.0

var current_hp: int = 0
var is_destroyed: bool = false

@onready var _sprite: Sprite2D = %Sprite2D


func _ready() -> void:
	current_hp = max_hp
	add_to_group(&"plants")
	collision_layer = CollisionLayers.INTERACTABLE
	collision_mask = 0


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
	is_destroyed = true
	plant_destroyed.emit(self)
	_play_wither_animation()


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
