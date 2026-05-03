extends State

var _attack_timer: float = 0.0


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
	var e: PhantomWeaver = enemy as PhantomWeaver
	if e == null or e.is_stunned():
		return
	if e._pending_teleport:
		state_machine.transition_to(&"Teleport")
		return
	if not e.is_player_dead() and e.distance_to_player() <= e.attack_range:
		e.current_siege_target = null
		state_machine.transition_to(&"Attack")
		return
	if e.global_position.distance_to(e.get_siege_target_position()) > e.attack_range:
		e.current_siege_target = null
		state_machine.transition_to(&"Scout")
		return

	e.velocity = Vector2.ZERO
	e.move_and_slide()
