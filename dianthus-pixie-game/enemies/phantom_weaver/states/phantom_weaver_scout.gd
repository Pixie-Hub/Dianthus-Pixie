extends State

const NAV_UPDATE_INTERVAL: float = 0.5
const WANDER_ANGLE_MAX: float = deg_to_rad(15.0)

var _nav_timer: float = 0.0
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false


func enter() -> void:
	_nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_use_direct_steering = _nav_agent == null
	_nav_timer = NAV_UPDATE_INTERVAL
	_update_target()
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		e.play_animation(&"walk")


func physics_update(delta: float) -> void:
	var e: PhantomWeaver = enemy as PhantomWeaver
	if e == null or e.is_stunned():
		return
	if e._pending_teleport:
		state_machine.transition_to(&"Teleport")
		return
	if not e.is_player_dead() and e.distance_to_player() <= e.detection_radius:
		state_machine.transition_to(&"Attack")
		return
	if e.distance_to_core() <= e.attack_range:
		state_machine.transition_to(&"Siege")
		return

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = NAV_UPDATE_INTERVAL
		_update_target()

	_move(e, delta)


func _update_target() -> void:
	var target: Vector2 = (enemy as EnemyBase).get_core_position()
	if not _use_direct_steering and is_instance_valid(_nav_agent):
		_nav_agent.target_position = target


func _move(e: EnemyBase, _delta: float) -> void:
	var direction: Vector2
	var has_path: bool = (not _use_direct_steering
		and is_instance_valid(_nav_agent)
		and _nav_agent.get_current_navigation_path().size() > 1)
	if has_path:
		direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
	else:
		direction = (e.get_core_position() - e.global_position).normalized()

	var wander_angle: float = randf_range(-WANDER_ANGLE_MAX, WANDER_ANGLE_MAX)
	direction = direction.rotated(wander_angle)
	e.velocity = direction * e.get_effective_speed()
	e.move_and_slide()
