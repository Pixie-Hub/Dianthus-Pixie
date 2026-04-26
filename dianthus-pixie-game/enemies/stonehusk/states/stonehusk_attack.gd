extends State

const NAV_UPDATE_INTERVAL: float = 0.3
# Shorter leash — Stonehusk gives up on player sooner and returns to Core.
const LEASH_MULTIPLIER: float = 1.2

var _nav_timer: float = 0.0
var _attack_timer: float = 0.0
var _nav_agent: NavigationAgent2D = null
var _use_direct_steering: bool = false


func enter() -> void:
	_nav_agent = enemy.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_use_direct_steering = _nav_agent == null
	_nav_timer = NAV_UPDATE_INTERVAL
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

	if e.is_player_dead():
		state_machine.transition_to(&"Scout")
		return
	# No retreat check — Stonehusk never retreats.
	if e.distance_to_player() > e.detection_radius * LEASH_MULTIPLIER:
		state_machine.transition_to(&"Scout")
		return

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = NAV_UPDATE_INTERVAL
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
	e.velocity = direction * e.get_effective_speed()
	e.move_and_slide()
