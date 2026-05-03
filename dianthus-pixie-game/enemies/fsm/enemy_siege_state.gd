class_name EnemySiegeState
extends State

var _attack_timer: float = 0.0


func _get_scout_fallback_state() -> StringName:
	return &"Scout"


func _check_retreat(e: EnemyBase) -> bool:
	return e.should_retreat()


func _pre_checks(_e: EnemyBase) -> bool:
	return false


func enter() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		_attack_timer = e.attack_cooldown
		if not is_instance_valid(e.current_siege_target):
			e.current_siege_target = GameManager.dianthus_core


func update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	if not is_instance_valid(e.current_siege_target):
		e.current_siege_target = GameManager.dianthus_core
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = e.attack_cooldown
		e.play_animation(&"attack")
		if is_instance_valid(e.current_siege_target) and e.current_siege_target.has_method("take_damage"):
			e.current_siege_target.take_damage(e.damage)
			e.damage_dealt.emit(e.current_siege_target, e.damage)


func physics_update(_delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return

	if _pre_checks(e):
		return
	if _check_retreat(e):
		state_machine.transition_to(&"Retreat")
		return
	if not e.is_player_dead() and e.distance_to_player() <= e.attack_range:
		e.current_siege_target = null
		state_machine.transition_to(&"Attack")
		return
	if e.distance_to_siege_target() > e.attack_range:
		e.current_siege_target = null
		state_machine.transition_to(_get_scout_fallback_state())
		return

	e.velocity = Vector2.ZERO
	e.move_and_slide()
