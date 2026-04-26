extends State

var _attack_timer: float = 0.0


func enter() -> void:
	_attack_timer = 0.0


func update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = e.attack_cooldown
		e.play_animation(&"attack")
		if is_instance_valid(GameManager.dianthus_core):
			GameManager.dianthus_core.take_damage(e.damage)
			e.damage_dealt.emit(GameManager.dianthus_core, e.damage)


func physics_update(_delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return

	# No retreat check — Stonehusk never retreats.
	if not e.is_player_dead() and e.distance_to_player() <= e.attack_range:
		state_machine.transition_to(&"Attack")
		return
	if e.distance_to_core() > e.attack_range:
		state_machine.transition_to(&"Scout")
		return

	e.velocity = Vector2.ZERO
	e.move_and_slide()
