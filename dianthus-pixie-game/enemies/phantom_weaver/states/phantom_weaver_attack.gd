extends EnemyAttackState


func _check_retreat(_e: EnemyBase) -> bool:
	return false


func _pre_checks(e: EnemyBase) -> bool:
	var pw: PhantomWeaver = e as PhantomWeaver
	if pw != null and pw._pending_teleport:
		state_machine.transition_to(&"Teleport")
		return true
	return false
