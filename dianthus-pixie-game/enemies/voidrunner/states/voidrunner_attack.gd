extends EnemyAttackState


func _get_leash_multiplier() -> float:
	return 1.2


func _get_scout_fallback_state() -> StringName:
	return &"Rush"


func _get_player_dead_fallback_state() -> StringName:
	return &"Rush"


func _check_retreat(_e: EnemyBase) -> bool:
	return false
