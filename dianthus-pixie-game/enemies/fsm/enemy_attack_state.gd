class_name EnemyAttackState
extends State

var _nav_timer: float = 0.0
var _attack_timer: float = 0.0
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false


func _get_nav_update_interval() -> float:
	return 0.3


func _get_leash_multiplier() -> float:
	return 1.5


func _get_chase_speed_multiplier() -> float:
	return 1.2


func _get_scout_fallback_state() -> StringName:
	return &"Scout"


func _get_player_dead_fallback_state() -> StringName:
	return &"Siege"


func _check_retreat(e: EnemyBase) -> bool:
	return e.should_retreat()


func _pre_checks(_e: EnemyBase) -> bool:
	return false


func enter() -> void:
	_nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_use_direct_steering = _nav_agent == null
	_nav_timer = _get_nav_update_interval()
	_attack_timer = 0.0
	_update_target()
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		e.play_animation(&"walk")


func update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	_attack_timer -= delta


func physics_update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return

	if _pre_checks(e):
		return
	if e.is_player_dead():
		state_machine.transition_to(_get_player_dead_fallback_state())
		return
	if _check_retreat(e):
		state_machine.transition_to(&"Retreat")
		return
	if e.distance_to_player() > e.detection_radius * _get_leash_multiplier():
		state_machine.transition_to(_get_scout_fallback_state())
		return

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = _get_nav_update_interval()
		_update_target()

	var dist_to_player: float = e.distance_to_player()
	if dist_to_player <= e.attack_range:
		e.velocity = Vector2.ZERO
		e.move_and_slide()
		if _attack_timer <= 0.0:
			_attack_timer = e.attack_cooldown
			e.play_animation(&"attack")
			if is_instance_valid(GameManager.player) and not e.is_player_dead():
				GameManager.player.take_damage(e.damage)
				e.damage_dealt.emit(GameManager.player, e.damage)
	else:
		e.play_animation(&"walk")
		_move(e)


func _update_target() -> void:
	var target: Vector2 = (enemy as EnemyBase).get_player_position()
	if not _use_direct_steering and is_instance_valid(_nav_agent):
		_nav_agent.target_position = target


func _move(e: EnemyBase) -> void:
	var direction: Vector2
	var has_path: bool = (not _use_direct_steering
		and is_instance_valid(_nav_agent)
		and _nav_agent.get_current_navigation_path().size() > 1)
	if has_path:
		direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
	else:
		direction = (e.get_player_position() - e.global_position).normalized()
	e.velocity = direction * e.get_effective_speed() * _get_chase_speed_multiplier()
	e.move_and_slide()
