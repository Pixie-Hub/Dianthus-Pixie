extends EnemyScoutState


# Tighter wander — Stonehusk marches more directly toward Core.
func _get_wander_angle_max() -> float:
	return deg_to_rad(5.0)


func _check_retreat(_e: EnemyBase) -> bool:
	return false
