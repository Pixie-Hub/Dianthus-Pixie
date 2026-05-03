class_name EnemyScoutState
extends State

var _nav_timer: float = 0.0
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false


func _get_nav_update_interval() -> float:
	return 0.5


func _get_wander_angle_max() -> float:
	return deg_to_rad(15.0)


func _get_scout_fallback_state() -> StringName:
	return &"Scout"


func _check_retreat(e: EnemyBase) -> bool:
	return e.should_retreat()


func _check_player_detection(e: EnemyBase) -> bool:
	return not e.is_player_dead() and e.distance_to_player() <= e.detection_radius


func _pre_checks(_e: EnemyBase) -> bool:
	return false


func enter() -> void:
	_nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_use_direct_steering = _nav_agent == null
	_nav_timer = _get_nav_update_interval()
	_update_target()
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		e.play_animation(&"walk")


func physics_update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return

	if _pre_checks(e):
		return
	if _check_retreat(e):
		state_machine.transition_to(&"Retreat")
		return
	if _check_player_detection(e):
		state_machine.transition_to(&"Attack")
		return
	var barricade: Node2D = e.get_nearby_barricade()
	if barricade != null:
		e.current_siege_target = barricade
		state_machine.transition_to(&"Siege")
		return
	if e.distance_to_core() <= e.attack_range:
		state_machine.transition_to(&"Siege")
		return

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = _get_nav_update_interval()
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

	var wander_max: float = _get_wander_angle_max()
	if wander_max > 0.0:
		var wander_angle: float = randf_range(-wander_max, wander_max)
		direction = direction.rotated(wander_angle)
	e.velocity = direction * e.get_effective_speed()
	e.move_and_slide()
