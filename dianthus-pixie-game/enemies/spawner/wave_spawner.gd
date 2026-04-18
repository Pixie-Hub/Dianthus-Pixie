class_name WaveSpawner
extends Node

signal wave_started()
signal wave_cleared()
signal enemy_spawned(enemy: EnemyBase)

@export var enemy_scene: PackedScene = preload("res://enemies/shadowling/shadowling.tscn")
@export var total_enemies: int = 5
@export var min_entry_points: int = 1
@export var max_entry_points: int = 3
@export var spawn_interval: float = 1.5
@export var spawn_batch_size: int = 1
@export var spawn_offset_radius: float = 24.0
@export var enemy_container_path: NodePath = NodePath("")

@export_group("Difficulty Scaling")
@export var hp_growth_per_day: float = 0.10
@export var spawn_growth_per_day: int = 1
@export var max_hp_multiplier: float = 3.0
@export var max_spawn_count: int = 20

var _spawn_point_markers: Array[Marker2D] = []
var _active_spawn_points: Array[Vector2] = []
var _enemies_alive: int = 0
var _enemies_spawned: int = 0
var _current_wave_total: int = 0
var _current_hp_multiplier: float = 1.0
var _spawn_timer: float = 0.0
var _wave_active: bool = false
var _spawned_enemies: Array[EnemyBase] = []
var _enemy_container: Node = null
var _counted_dead: Dictionary = {}


func _ready() -> void:
	for child: Node in get_children():
		if child is Marker2D:
			_spawn_point_markers.append(child as Marker2D)
	if enemy_container_path.is_empty():
		_enemy_container = get_tree().current_scene
	else:
		_enemy_container = get_node_or_null(enemy_container_path)
		if _enemy_container == null:
			_enemy_container = get_tree().current_scene
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	if DayNightCycle.is_night():
		start_wave()


func _on_phase_changed(phase: String) -> void:
	if phase == "NIGHT":
		start_wave()
	elif phase == "DAY":
		_cleanup_wave()


func start_wave() -> void:
	if _wave_active:
		return
	if _spawn_point_markers.is_empty():
		push_warning("[WaveSpawner] No Marker2D spawn points found as children.")
		return
	_wave_active = true
	_enemies_alive = 0
	_enemies_spawned = 0
	_spawn_timer = 0.0
	_spawned_enemies.clear()
	_counted_dead.clear()
	var day: int = max(1, DayNightCycle.day_count)
	var days_passed: int = day - 1
	_current_hp_multiplier = min(1.0 + hp_growth_per_day * days_passed, max_hp_multiplier)
	_current_wave_total = min(total_enemies + spawn_growth_per_day * days_passed, max_spawn_count)
	var count: int = randi_range(min_entry_points, min(max_entry_points, _spawn_point_markers.size()))
	var shuffled: Array[Marker2D] = _spawn_point_markers.duplicate()
	shuffled.shuffle()
	_active_spawn_points.clear()
	for i: int in range(count):
		_active_spawn_points.append(shuffled[i].global_position)
	wave_started.emit()
	print("[WaveSpawner] Wave started. Day: %d, Entry points: %d, Enemies: %d, HP x%.2f" \
		% [day, count, _current_wave_total, _current_hp_multiplier])


func _process(delta: float) -> void:
	if not _wave_active or _enemies_spawned >= _current_wave_total:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		for _i: int in range(spawn_batch_size):
			if _enemies_spawned < _current_wave_total:
				_spawn_enemy()
		_spawn_timer = spawn_interval


func _spawn_enemy() -> void:
	if _active_spawn_points.is_empty():
		return
	var base_pos: Vector2 = _active_spawn_points[randi() % _active_spawn_points.size()]
	var rand_dir: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if rand_dir != Vector2.ZERO:
		rand_dir = rand_dir.normalized()
	var spawn_pos: Vector2 = base_pos + rand_dir * randf_range(0.0, spawn_offset_radius)
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		push_warning("[WaveSpawner] Failed to instantiate enemy scene as EnemyBase.")
		return
	enemy.global_position = spawn_pos
	if _current_hp_multiplier > 1.0:
		enemy.max_hp = int(round(enemy.max_hp * _current_hp_multiplier))
		enemy.current_hp = enemy.max_hp
	_enemy_container.add_child(enemy)
	if enemy.has_method("activate"):
		enemy.activate()
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	_enemies_spawned += 1
	_enemies_alive += 1
	_spawned_enemies.append(enemy)
	_counted_dead[enemy] = false
	enemy_spawned.emit(enemy)
	print("[WaveSpawner] Spawned enemy %d/%d at %s" % [_enemies_spawned, _current_wave_total, spawn_pos])


func _on_enemy_died(enemy: EnemyBase) -> void:
	if _counted_dead.get(enemy, true):
		return
	_counted_dead[enemy] = true
	_enemies_alive -= 1
	print("[WaveSpawner] Enemy removed. Remaining: %d" % _enemies_alive)
	_check_wave_cleared()


func _on_enemy_removed(enemy: EnemyBase) -> void:
	if _counted_dead.get(enemy, true):
		return
	_counted_dead[enemy] = true
	_enemies_alive -= 1
	print("[WaveSpawner] Enemy removed. Remaining: %d" % _enemies_alive)
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if _enemies_alive <= 0 and _enemies_spawned >= _current_wave_total:
		_wave_active = false
		wave_cleared.emit()
		print("[WaveSpawner] Wave cleared!")


func cleanup_wave() -> void:
	_cleanup_wave()


func _cleanup_wave() -> void:
	_wave_active = false
	_counted_dead.clear()
	_enemies_alive = 0
	_enemies_spawned = 0
	_active_spawn_points.clear()
	var to_free: Array[EnemyBase] = _spawned_enemies.duplicate()
	_spawned_enemies.clear()
	for enemy: EnemyBase in to_free:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.queue_free()


func get_alive_count() -> int:
	# TODO (AUDIO-03): Used by dynamic music layer intensity.
	# TODO (UI-01): HUD reads this for remaining enemy count display.
	return _enemies_alive


# TODO (DIFF-02): Add override_entry_point_count(n: int) for Surge Night to force all 4 entry points.
