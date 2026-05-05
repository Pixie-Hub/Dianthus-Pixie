extends State

const SUMMON_INTERVAL: float = 12.0
const VOID_SLAM_COOLDOWN: float = 1.8
const DARK_PULSE_COOLDOWN: float = 4.0
const DARK_PULSE_CHARGE_TIME: float = 0.8
const NAV_UPDATE_INTERVAL: float = 0.5
const PLAYER_CHASE_DURATION: float = 3.0
const MINIONS_PER_SUMMON: Array[String] = ["voidrunner", "shadowling"]
const DARK_PULSE_SCENE: PackedScene = preload("res://enemies/devourer/devourer_dark_pulse.tscn")

var _nav_agent: NavigationAgent2D = null
var _attack_timer: float = 0.0
var _summon_timer: float = 0.0
var _dark_pulse_timer: float = 0.0
var _nav_timer: float = 0.0
var _player_chase_timer: float = 0.0
var _is_charging_pulse: bool = false


func enter() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	e.move_speed = 45.0
	e.play_animation(&"walk")
	_nav_agent = e.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	_attack_timer = VOID_SLAM_COOLDOWN
	_summon_timer = SUMMON_INTERVAL
	_dark_pulse_timer = DARK_PULSE_COOLDOWN
	_nav_timer = 0.0
	_player_chase_timer = 0.0
	_is_charging_pulse = false
	SfxManager.play_at("devourer_phase_transition", e.global_position)
	e.modulate = Color(0.7, 0.15, 0.5, 1.0)
	_update_nav_target(e)


func update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null:
		return
	_attack_timer -= delta
	_summon_timer -= delta
	_dark_pulse_timer -= delta
	if _attack_timer <= 0.0 and not _is_charging_pulse:
		_attack_timer = VOID_SLAM_COOLDOWN
		_do_void_slam(e)
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_INTERVAL
		_summon_minions(e, MINIONS_PER_SUMMON)
	if _dark_pulse_timer <= 0.0 and not _is_charging_pulse:
		_dark_pulse_timer = DARK_PULSE_COOLDOWN
		_start_dark_pulse(e)


func physics_update(delta: float) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e == null or e.is_stunned():
		return
	if _is_charging_pulse:
		e.velocity = Vector2.ZERO
		e.move_and_slide()
		return
	var core: Node2D = GameManager.dianthus_core as Node2D
	var player: Node2D = GameManager.player as Node2D
	var target_pos: Vector2
	if is_instance_valid(player) and _player_chase_timer > 0.0:
		_player_chase_timer -= delta
		target_pos = player.global_position
	else:
		_player_chase_timer = 0.0
		if is_instance_valid(player) and is_instance_valid(core):
			var dist_player: float = e.global_position.distance_to(player.global_position)
			if dist_player <= e.detection_radius * 0.8:
				_player_chase_timer = PLAYER_CHASE_DURATION
				target_pos = player.global_position
			else:
				target_pos = core.global_position
		elif is_instance_valid(core):
			target_pos = core.global_position
		else:
			return
	var dist: float = e.global_position.distance_to(target_pos)
	if dist <= e.attack_range:
		e.velocity = Vector2.ZERO
		e.move_and_slide()
		return
	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = NAV_UPDATE_INTERVAL
		if is_instance_valid(_nav_agent):
			_nav_agent.target_position = target_pos
	var direction: Vector2
	if is_instance_valid(_nav_agent) and _nav_agent.get_current_navigation_path().size() > 1:
		direction = (_nav_agent.get_next_path_position() - e.global_position).normalized()
	else:
		direction = (target_pos - e.global_position).normalized()
	e.velocity = direction * e.get_effective_speed()
	e.move_and_slide()


func _update_nav_target(_e: EnemyBase) -> void:
	if is_instance_valid(_nav_agent) and is_instance_valid(GameManager.dianthus_core):
		_nav_agent.target_position = GameManager.dianthus_core.global_position


func _do_void_slam(e: EnemyBase) -> void:
	e.play_animation(&"attack")
	SfxManager.play_at("devourer_slam", e.global_position)
	var slam_area: Area2D = e.get_node_or_null("VoidSlamArea") as Area2D
	if slam_area == null:
		return
	var col: CollisionShape2D = slam_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		col.disabled = false
	for body in slam_area.get_overlapping_bodies():
		if body == e:
			continue
		if body.has_method("take_damage"):
			var dmg: int = e.damage
			if body.is_in_group(&"plants"):
				dmg = 30
			body.take_damage(dmg)
	if col != null:
		col.disabled = true


func _start_dark_pulse(e: EnemyBase) -> void:
	_is_charging_pulse = true
	e.play_animation(&"charge")
	SfxManager.play_at("devourer_dark_pulse_charge", e.global_position)
	var tween: Tween = e.create_tween()
	tween.tween_interval(DARK_PULSE_CHARGE_TIME)
	tween.tween_callback(_fire_dark_pulse.bind(e))


func _fire_dark_pulse(e: EnemyBase) -> void:
	if not is_instance_valid(e) or e.is_dead:
		_is_charging_pulse = false
		return
	e.play_animation(&"walk")
	SfxManager.play_at("devourer_dark_pulse", e.global_position)
	var player: Node2D = GameManager.player as Node2D
	if not is_instance_valid(player):
		_is_charging_pulse = false
		return
	var pulse: Node2D = DARK_PULSE_SCENE.instantiate() as Node2D
	pulse.global_position = e.global_position
	pulse.set_meta("damage", 35)
	pulse.set_meta("target_pos", player.global_position)
	e.get_parent().add_child(pulse)
	_is_charging_pulse = false


func _summon_minions(e: EnemyBase, types: Array[String]) -> void:
	SfxManager.play_at("devourer_summon", e.global_position)
	var spawner: WaveSpawner = _find_wave_spawner(e)
	if spawner == null:
		return
	var container: Node = spawner._enemy_container
	if container == null:
		return
	for type_name: String in types:
		var scene: PackedScene = WaveSpawner.ENEMY_SCENES.get(type_name) as PackedScene
		if scene == null:
			continue
		var minion: EnemyBase = scene.instantiate() as EnemyBase
		if minion == null:
			continue
		var offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(32.0, 64.0)
		minion.global_position = e.global_position + offset
		container.add_child(minion)
		if minion.has_method("activate"):
			minion.activate()
		spawner._enemies_alive += 1
		spawner._current_wave_total += 1
		minion.enemy_died.connect(spawner._on_enemy_died)
		var devourer: TheDevourer = e as TheDevourer
		if devourer != null:
			devourer.register_minion(minion)


func _find_wave_spawner(e: EnemyBase) -> WaveSpawner:
	for node in e.get_tree().get_nodes_in_group(&"wave_spawner"):
		if node is WaveSpawner:
			return node as WaveSpawner
	var scene_root: Node = e.get_tree().current_scene
	if scene_root == null:
		return null
	return scene_root.find_child("WaveSpawner", true, false) as WaveSpawner
