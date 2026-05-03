extends EnemyAttackState


# Shorter leash — Stonehusk gives up on player sooner and returns to Core.
func _get_leash_multiplier() -> float:
	return 1.2


func _get_chase_speed_multiplier() -> float:
	return 1.0


func _get_player_dead_fallback_state() -> StringName:
	return &"Scout"


func _check_retreat(_e: EnemyBase) -> bool:
	return false
