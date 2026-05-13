class_name WeaponVfxBurst
extends Node2D

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)


func play(
	frames: SpriteFrames,
	animation_name: StringName = &"burst",
	visual_offset: Vector2 = Vector2.ZERO,
	visual_scale: Vector2 = Vector2.ONE,
	visual_rotation: float = 0.0,
	flip_h: bool = false,
	flip_v: bool = false
) -> void:
	if frames == null or not frames.has_animation(animation_name):
		queue_free()
		return
	_sprite.sprite_frames = frames
	_sprite.offset = visual_offset
	_sprite.scale = visual_scale
	_sprite.rotation = visual_rotation
	_sprite.flip_h = flip_h
	_sprite.flip_v = flip_v
	_sprite.play(animation_name)


func _on_animation_finished() -> void:
	queue_free()
