extends Camera2D

@export var follow_speed: float = 5.0
@export var look_ahead_distance: float = 24.0
@export var look_ahead_speed: float = 3.0
@export var deadzone_size: Vector2 = Vector2(16.0, 12.0)

var _player: CharacterBody2D
var _target_position: Vector2
var _look_ahead_offset: Vector2
var _initialized: bool = false

func _ready() -> void:
	top_level = true
	position_smoothing_enabled = false
	_player = get_parent() as CharacterBody2D

func _physics_process(delta: float) -> void:
	if not _player:
		return

	if not _initialized:
		_target_position = _player.global_position
		global_position = _clamp_to_limits(_target_position).round()
		_initialized = true
		return

	var player_pos := _player.global_position
	var player_vel := _player.velocity

	# Look-ahead: smoothly interpolate toward velocity direction
	var look_target := Vector2.ZERO
	if player_vel.length_squared() > 0.01:
		look_target = player_vel.normalized() * look_ahead_distance
	_look_ahead_offset = _look_ahead_offset.lerp(
		look_target, 1.0 - exp(-look_ahead_speed * delta)
	)

	# Deadzone: only push tracking target when player exceeds the dead band
	var diff := player_pos - _target_position
	if abs(diff.x) > deadzone_size.x:
		_target_position.x += diff.x - sign(diff.x) * deadzone_size.x
	if abs(diff.y) > deadzone_size.y:
		_target_position.y += diff.y - sign(diff.y) * deadzone_size.y

	# Smooth follow toward target + look-ahead
	var desired := _target_position + _look_ahead_offset
	var current_pos := global_position
	var smoothed := current_pos.lerp(
		desired, 1.0 - exp(-follow_speed * delta)
	)

	# Clamp to zone limits and snap to pixel grid
	global_position = _clamp_to_limits(smoothed).round()

func _clamp_to_limits(pos: Vector2) -> Vector2:
	var vp_size := get_viewport_rect().size / zoom
	var half_w := vp_size.x * 0.5
	var half_h := vp_size.y * 0.5
	var min_x := ceilf(limit_left + half_w)
	var max_x := floorf(limit_right - half_w)
	var min_y := ceilf(limit_top + half_h)
	var max_y := floorf(limit_bottom - half_h)
	if min_x > max_x:
		pos.x = roundf((limit_left + limit_right) * 0.5)
	else:
		pos.x = clampf(pos.x, min_x, max_x)
	if min_y > max_y:
		pos.y = roundf((limit_top + limit_bottom) * 0.5)
	else:
		pos.y = clampf(pos.y, min_y, max_y)
	return pos
