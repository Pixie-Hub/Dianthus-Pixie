class_name EnemyRetreatState
extends State

const RETREAT_SPEED_MULTIPLIER: float = 1.5
const RETREAT_DURATION: float = 5.0
const RETREAT_SAFE_DISTANCE: float = 300.0

var _retreat_timer: float = 0.0
var _flee_direction: Vector2 = Vector2.ZERO


func enter() -> void:
	_retreat_timer = RETREAT_DURATION
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		_flee_direction = (e.global_position - e.get_core_position()).normalized()
		if _flee_direction == Vector2.ZERO:
			_flee_direction = Vector2.RIGHT
		e.play_animation(&"walk")


func physics_update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return

	_retreat_timer -= delta
	var far_enough: bool = e.distance_to_core() > RETREAT_SAFE_DISTANCE
	if _retreat_timer <= 0.0 or far_enough:
		e.queue_free()
		return

	e.velocity = _flee_direction * e.get_effective_speed() * RETREAT_SPEED_MULTIPLIER
	e.move_and_slide()
