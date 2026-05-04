extends EnemyAttackState

const SEPARATION_RADIUS: float = 20.0
const SEPARATION_WEIGHT: float = 0.9


func _get_leash_multiplier() -> float:
	return 1.0


func _get_chase_speed_multiplier() -> float:
	return 1.0


func _get_scout_fallback_state() -> StringName:
	return &"Swarm"


func _get_player_dead_fallback_state() -> StringName:
	return &"Swarm"


func _check_retreat(_e: EnemyBase) -> bool:
	return false


func _move(e: EnemyBase) -> void:
	var direction: Vector2
	var has_path: bool = (not _use_direct_steering
		and is_instance_valid(_nav_agent)
		and _nav_agent.get_current_navigation_path().size() > 1)
	if has_path:
		direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
	else:
		direction = (e.get_player_position() - e.global_position).normalized()

	var separation_force: Vector2 = Vector2.ZERO
	for node in e.get_tree().get_nodes_in_group(&"swarm_larvae"):
		if node == e or not is_instance_valid(node):
			continue
		var dist: float = e.global_position.distance_to(node.global_position)
		if dist < SEPARATION_RADIUS and dist > 0.0:
			separation_force += (e.global_position - node.global_position).normalized() * (1.0 - dist / SEPARATION_RADIUS)
	if separation_force.length_squared() > 0.0:
		direction = (direction + separation_force * SEPARATION_WEIGHT).normalized()

	e.velocity = direction * e.get_effective_speed() * _get_chase_speed_multiplier()
	e.move_and_slide()
