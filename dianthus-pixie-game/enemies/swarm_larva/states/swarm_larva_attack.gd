extends EnemyAttackState


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
