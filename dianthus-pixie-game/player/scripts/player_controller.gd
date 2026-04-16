extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned

const TILE_SIZE: int = 16
const SPEED: float = TILE_SIZE * 5.0
const MAX_HP: int = 100
const RESPAWN_DELAY: float = 5.0
const INVINCIBILITY_DURATION: float = 3.0
const ENERGY_DEATH_PENALTY: float = 0.25

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_tree: AnimationTree = %AnimationTree
@onready var _camera: Camera2D = %Camera2D

var _state_machine: AnimationNodeStateMachinePlayback

var last_direction: Vector2 = Vector2.DOWN
var current_hp: int = MAX_HP
var is_dead: bool = false
var is_invincible: bool = false
var _blink_tween: Tween = null

func _ready() -> void:
	_anim_tree.active = true
	_state_machine = _anim_tree["parameters/playback"]
	_update_blend_position()
	hp_changed.emit(current_hp, MAX_HP)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	var dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		last_direction = _dominant_direction(dir)
		velocity = dir * SPEED
		_travel("walk")
	else:
		velocity = Vector2.ZERO
		_travel("idle")
	_update_blend_position()
	move_and_slide()

func _dominant_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) >= abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP

func _travel(state: String) -> void:
	var current: StringName = _state_machine.get_current_node()
	if current == state:
		return
	if current == &"hurt" or current == &"death":
		return
	_state_machine.travel(state)

func _direction_to_blend() -> Vector2:
	if last_direction == Vector2.DOWN:
		return Vector2(0, 1)
	if last_direction == Vector2.UP:
		return Vector2(0, -1)
	if last_direction == Vector2.LEFT:
		return Vector2(-1, 0)
	return Vector2(1, 0)

func _update_blend_position() -> void:
	var blend: Vector2 = _direction_to_blend()
	_anim_tree["parameters/idle/blend_position"] = blend
	_anim_tree["parameters/walk/blend_position"] = blend
	_anim_tree["parameters/run/blend_position"] = blend
	_anim_tree["parameters/hurt/blend_position"] = blend
	_anim_tree["parameters/death/blend_position"] = blend

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	_camera.limit_left = left
	_camera.limit_top = top
	_camera.limit_right = right
	_camera.limit_bottom = bottom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			take_damage(25)
			print("DEBUG: Player took 25 damage. HP: %d/%d" % [current_hp, MAX_HP])
		elif event.keycode == KEY_F4:
			heal(25)
			print("DEBUG: Player healed 25. HP: %d/%d" % [current_hp, MAX_HP])

func take_damage(amount: int) -> void:
	if is_dead or is_invincible:
		return
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, MAX_HP)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	if current_hp <= 0:
		_die()

func heal(amount: int) -> void:
	if is_dead:
		return
	current_hp = min(current_hp + amount, MAX_HP)
	hp_changed.emit(current_hp, MAX_HP)

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()
	_state_machine.travel("death")
	_sprite.modulate.a = 0.3
	set_collision_layer_value(3, false)
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_respawn()

func _respawn() -> void:
	if is_instance_valid(GameManager.dianthus_core):
		global_position = GameManager.dianthus_core.global_position + Vector2(0, 32)
	current_hp = MAX_HP
	is_dead = false
	_sprite.modulate = Color.WHITE
	set_collision_layer_value(3, true)
	hp_changed.emit(current_hp, MAX_HP)
	player_respawned.emit()
	# TODO (PLANT-07): Apply -25% stored energy penalty here.
	_state_machine.travel("idle")
	_update_blend_position()
	_start_invincibility()

func _start_invincibility() -> void:
	is_invincible = true
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_sprite, "modulate:a", 0.4, 0.15)
	_blink_tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	is_invincible = false
	if is_instance_valid(_blink_tween):
		_blink_tween.kill()
	_sprite.modulate = Color.WHITE
