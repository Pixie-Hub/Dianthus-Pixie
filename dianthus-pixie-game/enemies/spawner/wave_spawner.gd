class_name WaveSpawner
extends Node

signal wave_started()
signal wave_cleared()
signal enemy_spawned(enemy: EnemyBase)

@export var enemy_scene: PackedScene = preload("res://enemies/shadowling/shadowling.tscn")  # Fallback — ENEMY_POOL takes priority.

const ENEMY_SCENES: Dictionary = {
	"shadowling": preload("res://enemies/shadowling/shadowling.tscn"),
	"voidrunner": preload("res://enemies/voidrunner/voidrunner.tscn"),
	"stonehusk": preload("res://enemies/stonehusk/stonehusk.tscn"),
	"phantom_weaver": preload("res://enemies/phantom_weaver/phantom_weaver.tscn"),
	"swarm_larva": preload("res://enemies/swarm_larva/swarm_larva.tscn"),
}

# Each entry: { "type": String, "weight": float, "min_day": int }
const ENEMY_POOL: Array[Dictionary] = [
	{ "type": "shadowling", "weight": 1.0, "min_day": 1 },
	{ "type": "voidrunner", "weight": 0.6, "min_day": 2 },
	{ "type": "stonehusk", "weight": 0.3, "min_day": 4 },
	{ "type": "phantom_weaver", "weight": 0.4, "min_day": 6 },
	{ "type": "swarm_larva", "weight": 0.5, "min_day": 8 },
]

@export var total_enemies: int = 5
@export var min_entry_points: int = 1
@export var max_entry_points: int = 3
@export var spawn_interval: float = 1.5
@export var spawn_batch_size: int = 1
@export var spawn_offset_radius: float = 24.0
@export var enemy_container_path: NodePath = NodePath("")

const SWARM_BATCH_MIN: int = 5
const SWARM_BATCH_MAX: int = 10

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
	if GameManager.endless_mode and day >= 30:
		var endless_exp: float = pow(1.5, floor(float(day - 30) / 5.0))
		_current_hp_multiplier *= endless_exp
		_current_wave_total = total_enemies + spawn_growth_per_day * days_passed
		count = _spawn_point_markers.size()
	var shuffled: Array[Marker2D] = _spawn_point_markers.duplicate()
	shuffled.shuffle()
	_active_spawn_points.clear()
	for i: int in range(count):
		_active_spawn_points.append(shuffled[i].global_position)
	wave_started.emit()
	SfxManager.play("wave_start")
	var available_types: Array[String] = []
	for entry: Dictionary in ENEMY_POOL:
		if day >= entry["min_day"]:
			available_types.append(entry["type"])
	print("[WaveSpawner] Wave started. Day: %d, Difficulty: %s, Endless: %s, Entry points: %d, Enemies: %d, HP x%.2f, Types: %s" \
		% [day, DifficultyManager.get_tier_label(), str(GameManager.endless_mode), count, _current_wave_total, _current_hp_multiplier, available_types])


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
	var picked_type: String = _pick_enemy_type()
	var batch: int = _get_batch_size(picked_type)
	var base_pos: Vector2 = _active_spawn_points[randi() % _active_spawn_points.size()]
	for _b: int in batch:
		if _enemies_spawned >= _current_wave_total:
			break
		_spawn_single_enemy(ENEMY_SCENES[picked_type], base_pos)


func _spawn_single_enemy(scene: PackedScene, base_pos: Vector2) -> void:
	var rand_dir: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if rand_dir != Vector2.ZERO:
		rand_dir = rand_dir.normalized()
	var spawn_pos: Vector2 = base_pos + rand_dir * randf_range(0.0, spawn_offset_radius)
	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	if enemy == null:
		push_warning("[WaveSpawner] Failed to instantiate enemy scene as EnemyBase.")
		return
	enemy.global_position = spawn_pos
	# DIFF-01: Per-day HP scaling.
	var effective_hp_mult: float = _current_hp_multiplier
	# ACCESS-01: Difficulty tier HP modifier (stacks multiplicatively).
	effective_hp_mult *= DifficultyManager.get_hp_multiplier()
	if effective_hp_mult != 1.0:
		enemy.max_hp = int(round(enemy.max_hp * effective_hp_mult))
		enemy.current_hp = enemy.max_hp

	# ACCESS-01: Difficulty tier damage modifier.
	var dmg_mult: float = DifficultyManager.get_dmg_multiplier()
	# END-04: Endless exponential damage scaling (stacks on top of difficulty tier).
	if GameManager.endless_mode and DayNightCycle.day_count >= 30:
		var day_now: int = DayNightCycle.day_count
		dmg_mult *= pow(1.5, floor(float(day_now - 30) / 5.0))
	if dmg_mult != 1.0:
		enemy.damage = int(round(enemy.damage * dmg_mult))

	# ACCESS-01: Difficulty tier speed modifier.
	var spd_mult: float = DifficultyManager.get_speed_multiplier()
	if spd_mult != 1.0:
		enemy.move_speed *= spd_mult
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


func _get_batch_size(enemy_type: String) -> int:
	if enemy_type == "swarm_larva":
		return randi_range(SWARM_BATCH_MIN, SWARM_BATCH_MAX)
	return 1


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
		SfxManager.play("wave_cleared")
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
	return _enemies_alive


func get_active_spawn_points() -> Array[Vector2]:
	return _active_spawn_points.duplicate()


func get_wave_total() -> int:
	return _current_wave_total


func is_wave_active() -> bool:
	return _wave_active


func _pick_enemy_type() -> String:
	if ENEMY_POOL.is_empty():
		return "shadowling"
	var day: int = max(1, DayNightCycle.day_count)
	var pool: Array[Dictionary] = []
	var total_weight: float = 0.0
	for entry: Dictionary in ENEMY_POOL:
		if day >= entry["min_day"]:
			pool.append(entry)
			total_weight += entry["weight"]
	if pool.is_empty():
		return "shadowling"
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for entry: Dictionary in pool:
		cumulative += entry["weight"]
		if roll <= cumulative:
			return entry["type"]
	return pool.back()["type"]


# TODO (DIFF-02): Add override_entry_point_count(n: int) for Surge Night to force all 4 entry points.
