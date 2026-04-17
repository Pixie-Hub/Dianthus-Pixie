extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
signal attack_hit(target: Node, damage: int)

const TILE_SIZE: int = 16
const SPEED: float = TILE_SIZE * 5.0
const MAX_HP: int = 100
const RESPAWN_DELAY: float = 5.0
const INVINCIBILITY_DURATION: float = 3.0
const ENERGY_DEATH_PENALTY: float = 0.25

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_tree: AnimationTree = %AnimationTree
@onready var _camera: Camera2D = %Camera2D
@onready var _sword_hitbox: Area2D = %SwordHitbox
@onready var _sword_sfx: AudioStreamPlayer2D = %SwordSFX

var _state_machine: AnimationNodeStateMachinePlayback

var last_direction: Vector2 = Vector2.DOWN
var current_hp: int = MAX_HP
var is_dead: bool = false
var is_invincible: bool = false
var _blink_tween: Tween = null
var is_attacking: bool = false
var _attack_cooldown_timer: float = 0.0
var _hit_bodies: Array[Node2D] = []
var _current_weapon: WeaponData = null

func _ready() -> void:
	_anim_tree.active = true
	_state_machine = _anim_tree["parameters/playback"]
	_update_blend_position()
	hp_changed.emit(current_hp, MAX_HP)
	_current_weapon = load("res://combat/weapons/thorn_sword/thorn_sword_data.tres")
	_sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_cooldown_timer = max(_attack_cooldown_timer - delta, 0.0)
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
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
	if current == &"hurt" or current == &"death" or current == &"attack":
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
	if (_anim_tree.tree_root as AnimationNodeStateMachine).has_node(&"attack"):
		_anim_tree["parameters/attack/blend_position"] = blend

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	_camera.limit_left = left
	_camera.limit_top = top
	_camera.limit_right = right
	_camera.limit_bottom = bottom

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("attack"):
		if not is_dead and not is_attacking and _attack_cooldown_timer <= 0.0:
			_start_attack()
			return
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

func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	_hit_bodies.clear()
	_state_machine.travel("attack")
	_update_blend_position()
	var hitbox_offset: Vector2
	if last_direction == Vector2.DOWN:
		hitbox_offset = Vector2(0, 4)
	elif last_direction == Vector2.UP:
		hitbox_offset = Vector2(0, -28)
	elif last_direction == Vector2.LEFT:
		hitbox_offset = Vector2(-16, -12)
	else:
		hitbox_offset = Vector2(16, -12)
	_sword_hitbox.position = hitbox_offset
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	print("DEBUG: Attack! Damage: %d, Direction: %s" % [_current_weapon.damage, last_direction])
	if _sword_sfx.stream != null:
		_sword_sfx.play()
	await get_tree().create_timer(_current_weapon.cooldown * 0.25).timeout
	hitbox_shape.disabled = false
	await get_tree().create_timer(_current_weapon.cooldown * 0.5).timeout
	hitbox_shape.disabled = true
	await get_tree().create_timer(_current_weapon.cooldown * 0.25).timeout
	_end_attack()

func _end_attack() -> void:
	is_attacking = false
	_attack_cooldown_timer = _current_weapon.cooldown
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	hitbox_shape.disabled = true
	_state_machine.travel("idle")

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(_current_weapon.damage)
	attack_hit.emit(body, _current_weapon.damage)
	print("DEBUG: Hit %s for %d damage" % [body.name, _current_weapon.damage])
	# TODO (PLANT-07): Add +3 energy per hit here.
	# TODO (VFX-05): Add impact particles on hit.
