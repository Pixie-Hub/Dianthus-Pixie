extends EnemyScoutState

const FLOCK_COHESION_WEIGHT: float = 0.3
const FLOCK_RADIUS: float = 64.0


func _get_wander_angle_max() -> float:
	return deg_to_rad(20.0)


func _get_scout_fallback_state() -> StringName:
	return &"Swarm"


func _check_retreat(_e: EnemyBase) -> bool:
	return false


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

	# Flocking: steer toward center of nearby swarm members.
	var flock_center: Vector2 = Vector2.ZERO
	var flock_count: int = 0
	for node in e.get_tree().get_nodes_in_group(&"swarm_larvae"):
		if node == e or not is_instance_valid(node):
			continue
		if e.global_position.distance_to(node.global_position) <= FLOCK_RADIUS:
			flock_center += node.global_position
			flock_count += 1
	if flock_count > 0:
		flock_center /= float(flock_count)
		var to_flock: Vector2 = (flock_center - e.global_position).normalized()
		direction = (direction * (1.0 - FLOCK_COHESION_WEIGHT) + to_flock * FLOCK_COHESION_WEIGHT).normalized()

	e.velocity = direction * e.get_effective_speed()
	e.move_and_slide()
