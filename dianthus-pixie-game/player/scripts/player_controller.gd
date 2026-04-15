extends CharacterBody2D

const TILE_SIZE: int = 16
const SPEED: float = TILE_SIZE * 5.0

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _camera: Camera2D = %Camera2D

var last_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		last_direction = _dominant_direction(dir)
		velocity = dir * SPEED
		_play_animation("walk")
	else:
		velocity = Vector2.ZERO
		_play_animation("idle")
	move_and_slide()

func _dominant_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) >= abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP

func _play_animation(prefix: String) -> void:
	var suffix: String
	if last_direction == Vector2.UP:
		suffix = "_up"
	elif last_direction == Vector2.DOWN:
		suffix = "_down"
	elif last_direction == Vector2.LEFT:
		suffix = "_left"
	else:
		suffix = "_right"
	var anim: String = prefix + suffix
	if _sprite.animation != anim:
		_sprite.play(anim)

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	_camera.limit_left = left
	_camera.limit_top = top
	_camera.limit_right = right
	_camera.limit_bottom = bottom
