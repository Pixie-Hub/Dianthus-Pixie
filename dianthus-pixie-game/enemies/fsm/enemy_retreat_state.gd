class_name EnemyRetreatState
extends State

const RETREAT_SPEED_MULTIPLIER: float = 1.5
const ARRIVE_THRESHOLD: float = 32.0
const NAV_UPDATE_INTERVAL: float = 0.4
const MAP_WIDTH: float = 1536.0
const MAP_HEIGHT: float = 1152.0

var _exit_target: Vector2 = Vector2.ZERO
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false
var _nav_timer: float = 0.0


func enter() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	var flee_dir: Vector2 = (e.global_position - e.get_core_position()).normalized()
	if flee_dir == Vector2.ZERO:
		flee_dir = Vector2.RIGHT
	_exit_target = _compute_edge_exit(e.global_position, flee_dir)
	_nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_use_direct_steering = _nav_agent == null
	if not _use_direct_steering and is_instance_valid(_nav_agent):
		_nav_agent.target_position = _exit_target
	_nav_timer = 0.0
	e.play_animation(&"retreat")


func physics_update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return

	if e.global_position.distance_to(_exit_target) <= ARRIVE_THRESHOLD:
		e.queue_free()
		return

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = NAV_UPDATE_INTERVAL
		if not _use_direct_steering and is_instance_valid(_nav_agent):
			_nav_agent.target_position = _exit_target

	var direction: Vector2
	var has_path: bool = (not _use_direct_steering
		and is_instance_valid(_nav_agent)
		and _nav_agent.get_current_navigation_path().size() > 1)
	if has_path:
		direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
	else:
		direction = (e.global_position - e.get_core_position()).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT

	e.velocity = direction * e.get_effective_speed() * RETREAT_SPEED_MULTIPLIER
	e.move_and_slide()


func _compute_edge_exit(from: Vector2, flee_dir: Vector2) -> Vector2:
	var best_t: float = INF
	if flee_dir.x != 0.0:
		var tx: float = ((MAP_WIDTH if flee_dir.x > 0.0 else 0.0) - from.x) / flee_dir.x
		if tx > 0.0:
			best_t = min(best_t, tx)
	if flee_dir.y != 0.0:
		var ty: float = ((MAP_HEIGHT if flee_dir.y > 0.0 else 0.0) - from.y) / flee_dir.y
		if ty > 0.0:
			best_t = min(best_t, ty)
	if best_t == INF:
		best_t = 800.0
	return from + flee_dir * best_t
