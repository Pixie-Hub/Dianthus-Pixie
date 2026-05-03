extends EnemyScoutState


func _get_nav_update_interval() -> float:
	return 0.3


func _get_wander_angle_max() -> float:
	return 0.0


func _get_scout_fallback_state() -> StringName:
	return &"Rush"


func _check_retreat(_e: EnemyBase) -> bool:
	return false


# Only switch to Attack if player is CLOSER than Core and within detection range.
func _check_player_detection(e: EnemyBase) -> bool:
	return not e.is_player_dead() and e.distance_to_player() <= e.detection_radius and e.distance_to_player() < e.distance_to_core()
