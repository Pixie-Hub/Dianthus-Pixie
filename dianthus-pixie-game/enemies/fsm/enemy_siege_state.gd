class_name EnemySiegeState
extends State

const APPROACH_GIVE_UP_DISTANCE: float = 400.0

var _attack_timer: float = 0.0
var _nav_timer: float = 0.0
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false


func _get_scout_fallback_state() -> StringName:
	return &"Scout"


func _get_nav_update_interval() -> float:
	return 0.4


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
	_nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_use_direct_steering = _nav_agent == null
	_nav_timer = 0.0
	_update_nav_target()


func update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	if not is_instance_valid(e.current_siege_target):
		e.current_siege_target = GameManager.dianthus_core
	_attack_timer -= delta
	if _attack_timer <= 0.0 and e.distance_to_siege_target() <= e.attack_range:
		_attack_timer = e.attack_cooldown
		e.play_animation(&"attack")
		if is_instance_valid(e.current_siege_target) and e.current_siege_target.has_method("take_damage"):
			e.current_siege_target.take_damage(e.damage)
			e.damage_dealt.emit(e.current_siege_target, e.damage)


func physics_update(delta: float) -> void:
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
	if not is_instance_valid(e.current_siege_target):
		state_machine.transition_to(_get_scout_fallback_state())
		return

	var dist: float = e.distance_to_siege_target()
	if dist > APPROACH_GIVE_UP_DISTANCE:
		e.current_siege_target = null
		state_machine.transition_to(_get_scout_fallback_state())
		return

	if dist <= e.attack_range:
		e.velocity = Vector2.ZERO
		e.move_and_slide()
		return

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = _get_nav_update_interval()
		_update_nav_target()

	var direction: Vector2
	var has_path: bool = (not _use_direct_steering
		and is_instance_valid(_nav_agent)
		and _nav_agent.get_current_navigation_path().size() > 1)
	if has_path:
		direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
	else:
		direction = (e.get_siege_target_position() - e.global_position).normalized()
	e.velocity = direction * e.get_effective_speed()
	e.move_and_slide()


func _update_nav_target() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	var target: Vector2 = e.get_siege_target_position()
	if not _use_direct_steering and is_instance_valid(_nav_agent):
		_nav_agent.target_position = target
