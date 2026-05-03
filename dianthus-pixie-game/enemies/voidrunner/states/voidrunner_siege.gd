extends EnemySiegeState


func _get_scout_fallback_state() -> StringName:
	return &"Rush"


func _check_retreat(_e: EnemyBase) -> bool:
	return false
