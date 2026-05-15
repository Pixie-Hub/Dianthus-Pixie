class_name WaveSpawner
extends Node

signal wave_started()
signal wave_cleared()
signal enemy_spawned(enemy: EnemyBase)
signal boss_spawned(boss: EnemyBase)
signal boss_defeated()
signal forecast_updated(forecast: Dictionary)

@export var enemy_scene: PackedScene = preload("res://enemies/shadowling/shadowling.tscn")  # Fallback — ENEMY_POOL takes priority.

const DEVOURER_SCENE: PackedScene = preload("res://enemies/devourer/the_devourer.tscn")

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
const FORECAST_SEED_BASE: int = 73031
const FORECAST_SEED_DAY_STEP: int = 9973
const NIGHT_START_READY_RETRIES: int = 4

const ENEMY_DISPLAY_NAMES: Dictionary = {
	"shadowling": "Shadowling",
	"voidrunner": "Voidrunner",
	"stonehusk": "Stonehusk",
	"phantom_weaver": "Phantom Weaver",
	"swarm_larva": "Swarm Larva",
	"the_devourer": "The Devourer",
}

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
var _is_boss_fight: bool = false
var _active_boss: EnemyBase = null
var _next_wave_forecast: Dictionary = {}
var _pending_spawn_groups: Array[Dictionary] = []
var _next_spawn_group_index: int = 0


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
	if QuestManager.has_signal(&"quest_started"):
		QuestManager.quest_started.connect(_on_forecast_relevant_quest_changed)
	if QuestManager.has_signal(&"quest_completed"):
		QuestManager.quest_completed.connect(_on_forecast_relevant_quest_changed)
	if QuestManager.has_signal(&"quest_failed"):
		QuestManager.quest_failed.connect(_on_forecast_relevant_quest_changed)
	call_deferred("_regenerate_next_wave_forecast")
	if DayNightCycle.is_night():
		call_deferred("_start_wave_after_scene_ready")


func _start_wave_after_scene_ready(retries_remaining: int = NIGHT_START_READY_RETRIES) -> void:
	if not DayNightCycle.is_night() or _wave_active:
		return
	if not is_instance_valid(GameManager.dianthus_core):
		if retries_remaining > 0:
			call_deferred("_start_wave_after_scene_ready", retries_remaining - 1)
		else:
			push_warning("[WaveSpawner] Cannot start night wave because the Dianthus Core is not registered.")
		return
	_ensure_forecast_for_current_day()
	if bool(_next_wave_forecast.get("is_boss", false)):
		_start_devourer_fight()
	else:
		start_wave()


func _on_phase_changed(phase: String) -> void:
	if phase == "NIGHT":
		_ensure_forecast_for_current_day()
		if bool(_next_wave_forecast.get("is_boss", false)):
			_start_devourer_fight()
		else:
			start_wave()
	elif phase == "DAY":
		_cleanup_wave()
		_regenerate_next_wave_forecast()


func start_wave() -> void:
	if _wave_active:
		return
	if _spawn_point_markers.is_empty():
		push_warning("[WaveSpawner] No Marker2D spawn points found as children.")
		return
	_ensure_forecast_for_current_day()
	if bool(_next_wave_forecast.get("is_boss", false)):
		_start_devourer_fight()
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
	if GameManager.endless_mode and day >= 30:
		_current_hp_multiplier *= pow(1.5, floor(float(day - 30) / 5.0))
	_current_wave_total = int(_next_wave_forecast.get("wave_total", 0))
	_active_spawn_points.clear()
	var lanes: Array = _next_wave_forecast.get("lanes", [])
	for lane: Variant in lanes:
		if lane is Dictionary:
			var lane_position: Vector2 = (lane as Dictionary).get("position", Vector2.ZERO)
			_active_spawn_points.append(lane_position)
	_pending_spawn_groups = _get_typed_spawn_groups(_next_wave_forecast.get("spawn_groups", []))
	_next_spawn_group_index = 0
	wave_started.emit()
	SfxManager.play("wave_start")
	print("[WaveSpawner] Wave started. Day: %d, Difficulty: %s, Endless: %s, Entry points: %d, Enemies: %d, HP x%.2f, Forecast types: %s" \
		% [day, DifficultyManager.get_tier_label(), str(GameManager.endless_mode), _active_spawn_points.size(), _current_wave_total, _current_hp_multiplier, _next_wave_forecast.get("enemy_totals", {})])


func _process(delta: float) -> void:
	if not _wave_active or _enemies_spawned >= _current_wave_total:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		for _i: int in range(spawn_batch_size):
			if _enemies_spawned < _current_wave_total:
				_spawn_next_group()
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


func _spawn_next_group() -> void:
	if _next_spawn_group_index >= _pending_spawn_groups.size():
		push_warning("[WaveSpawner] Forecast spawn plan ran out before wave total was reached.")
		return
	var group: Dictionary = _pending_spawn_groups[_next_spawn_group_index]
	_next_spawn_group_index += 1
	var picked_type: String = str(group.get("enemy_type", "shadowling"))
	var scene: PackedScene = ENEMY_SCENES.get(picked_type, enemy_scene) as PackedScene
	if scene == null:
		scene = enemy_scene
	var base_pos: Vector2 = group.get("position", Vector2.ZERO)
	var count: int = max(1, int(group.get("count", 1)))
	for _b: int in range(count):
		if _enemies_spawned >= _current_wave_total:
			break
		_spawn_single_enemy(scene, base_pos)


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
	enemy.spawn_grace_period()
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
	_pending_spawn_groups.clear()
	_next_spawn_group_index = 0
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


func _start_devourer_fight() -> void:
	if _wave_active:
		return
	if _spawn_point_markers.is_empty():
		push_warning("[WaveSpawner] Cannot start Devourer fight — no spawn markers.")
		return
	_ensure_forecast_for_current_day()
	_wave_active = true
	_is_boss_fight = true
	_enemies_alive = 0
	_enemies_spawned = 0
	_spawn_timer = 0.0
	_spawned_enemies.clear()
	_counted_dead.clear()
	var boss: EnemyBase = DEVOURER_SCENE.instantiate() as EnemyBase
	if boss == null:
		push_warning("[WaveSpawner] Failed to instantiate Devourer scene.")
		_wave_active = false
		_is_boss_fight = false
		return
	boss.global_position = _get_boss_spawn_position()
	# Apply difficulty tier multipliers — skip per-day growth (boss_hp_multiplier = 1.0).
	var hp_mult: float = DifficultyManager.get_hp_multiplier()
	if hp_mult != 1.0:
		boss.max_hp = int(round(boss.max_hp * hp_mult))
		boss.current_hp = boss.max_hp
	var dmg_mult: float = DifficultyManager.get_dmg_multiplier()
	if dmg_mult != 1.0:
		boss.damage = int(round(boss.damage * dmg_mult))
	var spd_mult: float = DifficultyManager.get_speed_multiplier()
	if spd_mult != 1.0:
		boss.move_speed *= spd_mult
	_enemy_container.add_child(boss)
	boss.spawn_grace_period()
	if boss.has_method("activate"):
		boss.activate()
	_active_boss = boss
	_enemies_alive = 1
	_enemies_spawned = 1
	_current_wave_total = 1
	_active_spawn_points.clear()
	_active_spawn_points.append(boss.global_position)
	_spawned_enemies.append(boss)
	_counted_dead[boss] = false
	boss.enemy_died.connect(_on_boss_died)
	boss.tree_exiting.connect(_on_enemy_removed.bind(boss))
	MusicManager.play_boss_music()
	wave_started.emit()
	SfxManager.play("wave_start")
	boss_spawned.emit(boss)
	print("[WaveSpawner] Devourer fight started! HP: %d  DMG: %d" % [boss.max_hp, boss.damage])


func _on_boss_died(boss: EnemyBase) -> void:
	if _counted_dead.get(boss, true):
		return
	_counted_dead[boss] = true
	_enemies_alive -= 1
	_active_boss = null
	_is_boss_fight = false
	boss_defeated.emit()
	MusicManager.stop_music(true)
	print("[WaveSpawner] Devourer defeated!")
	_check_wave_cleared()


func is_boss_fight_active() -> bool:
	return _is_boss_fight


func get_active_boss() -> EnemyBase:
	return _active_boss


func predict_spawn_direction() -> Vector2:
	if _spawn_point_markers.is_empty():
		return Vector2.DOWN
	var marker: Marker2D = _spawn_point_markers[randi() % _spawn_point_markers.size()]
	return marker.global_position


func predict_all_spawn_directions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for marker: Marker2D in _spawn_point_markers:
		result.append(marker.global_position)
	return result


func has_next_wave_forecast() -> bool:
	return not _next_wave_forecast.is_empty()


func get_next_wave_forecast() -> Dictionary:
	return _next_wave_forecast.duplicate(true)


func _ensure_forecast_for_current_day() -> void:
	var day: int = max(1, DayNightCycle.day_count)
	if _next_wave_forecast.is_empty() \
			or int(_next_wave_forecast.get("day", 0)) != day \
			or bool(_next_wave_forecast.get("is_boss", false)) != QuestManager.is_active(&"story_07_devourer"):
		_regenerate_next_wave_forecast()


func _regenerate_next_wave_forecast() -> void:
	if _spawn_point_markers.is_empty():
		_next_wave_forecast = {}
		forecast_updated.emit({})
		return
	if QuestManager.is_active(&"story_07_devourer"):
		_next_wave_forecast = _build_devourer_forecast()
	else:
		_next_wave_forecast = _build_regular_wave_forecast()
	forecast_updated.emit(get_next_wave_forecast())


func _on_forecast_relevant_quest_changed(quest_id: StringName, _extra: Variant = null) -> void:
	if quest_id != &"story_07_devourer":
		return
	_regenerate_next_wave_forecast()


func _build_regular_wave_forecast() -> Dictionary:
	var day: int = max(1, DayNightCycle.day_count)
	var rng: RandomNumberGenerator = _make_forecast_rng(day, false)
	var days_passed: int = day - 1
	var wave_total: int = min(total_enemies + spawn_growth_per_day * days_passed, max_spawn_count)
	var entry_count: int = rng.randi_range(min_entry_points, min(max_entry_points, _spawn_point_markers.size()))
	if GameManager.endless_mode and day >= 30:
		wave_total = total_enemies + spawn_growth_per_day * days_passed
		entry_count = _spawn_point_markers.size()
	var shuffled: Array[Marker2D] = _get_shuffled_spawn_markers(rng)
	var lanes: Array[Dictionary] = []
	for i: int in range(entry_count):
		lanes.append(_make_lane_data(shuffled[i]))
	var enemy_totals: Dictionary = {}
	var spawn_groups: Array[Dictionary] = []
	var planned_total: int = 0
	while planned_total < wave_total:
		var enemy_type: String = _pick_enemy_type_for_day(rng, day)
		var count: int = min(_get_batch_size_for_forecast(enemy_type, rng), wave_total - planned_total)
		var lane_index: int = rng.randi_range(0, lanes.size() - 1)
		var lane: Dictionary = lanes[lane_index]
		lane["count"] = int(lane.get("count", 0)) + count
		lanes[lane_index] = lane
		enemy_totals[enemy_type] = int(enemy_totals.get(enemy_type, 0)) + count
		spawn_groups.append({
			"lane_id": lane["id"],
			"lane_name": lane["name"],
			"position": lane["position"],
			"enemy_type": enemy_type,
			"enemy_name": ENEMY_DISPLAY_NAMES.get(enemy_type, enemy_type.capitalize()),
			"count": count,
		})
		planned_total += count
	return {
		"day": day,
		"is_boss": false,
		"special_label": "",
		"wave_total": wave_total,
		"lanes": lanes,
		"enemy_totals": enemy_totals,
		"spawn_groups": spawn_groups,
	}


func _build_devourer_forecast() -> Dictionary:
	var day: int = max(1, DayNightCycle.day_count)
	var rng: RandomNumberGenerator = _make_forecast_rng(day, true)
	var shuffled: Array[Marker2D] = _get_shuffled_spawn_markers(rng)
	var lane: Dictionary = _make_lane_data(shuffled[0])
	lane["count"] = 1
	return {
		"day": day,
		"is_boss": true,
		"special_label": "Devourer",
		"wave_total": 1,
		"lanes": [lane],
		"enemy_totals": {"the_devourer": 1},
		"spawn_groups": [{
			"lane_id": lane["id"],
			"lane_name": lane["name"],
			"position": lane["position"],
			"enemy_type": "the_devourer",
			"enemy_name": ENEMY_DISPLAY_NAMES["the_devourer"],
			"count": 1,
		}],
	}


func _make_forecast_rng(day: int, boss: bool) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var mode_offset: int = 503 if boss else 0
	var endless_offset: int = 211 if GameManager.endless_mode else 0
	rng.seed = FORECAST_SEED_BASE + (day * FORECAST_SEED_DAY_STEP) + mode_offset + endless_offset
	return rng


func _get_shuffled_spawn_markers(rng: RandomNumberGenerator) -> Array[Marker2D]:
	var shuffled: Array[Marker2D] = []
	for marker: Marker2D in _spawn_point_markers:
		shuffled.append(marker)
	for i: int in range(shuffled.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, i)
		var current: Marker2D = shuffled[i]
		shuffled[i] = shuffled[swap_index]
		shuffled[swap_index] = current
	return shuffled


func _make_lane_data(marker: Marker2D) -> Dictionary:
	var lane_id: String = _get_lane_id(marker)
	return {
		"id": lane_id,
		"name": _get_lane_display_name(lane_id),
		"position": marker.global_position,
		"count": 0,
	}


func _get_lane_id(marker: Marker2D) -> String:
	var lane_id: String = str(marker.name).replace("Spawn", "").to_lower()
	if lane_id.is_empty():
		return str(marker.name).to_snake_case()
	return lane_id


func _get_lane_display_name(lane_id: String) -> String:
	return lane_id.capitalize()


func _pick_enemy_type_for_day(rng: RandomNumberGenerator, day: int) -> String:
	if ENEMY_POOL.is_empty():
		return "shadowling"
	var pool: Array[Dictionary] = []
	var total_weight: float = 0.0
	for entry: Dictionary in ENEMY_POOL:
		if day >= int(entry["min_day"]):
			pool.append(entry)
			total_weight += float(entry["weight"])
	if pool.is_empty():
		return "shadowling"
	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for entry: Dictionary in pool:
		cumulative += float(entry["weight"])
		if roll <= cumulative:
			return str(entry["type"])
	return str(pool.back()["type"])


func _get_batch_size_for_forecast(enemy_type: String, rng: RandomNumberGenerator) -> int:
	if enemy_type == "swarm_larva":
		return rng.randi_range(SWARM_BATCH_MIN, SWARM_BATCH_MAX)
	return 1


func _get_typed_spawn_groups(raw_groups: Variant) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	if raw_groups is Array:
		for group: Variant in raw_groups:
			if group is Dictionary:
				groups.append(group)
	return groups


func _get_boss_spawn_position() -> Vector2:
	var lanes: Array = _next_wave_forecast.get("lanes", [])
	if not lanes.is_empty() and lanes[0] is Dictionary:
		var lane_position: Vector2 = (lanes[0] as Dictionary).get("position", _spawn_point_markers[0].global_position)
		return lane_position
	return _spawn_point_markers[0].global_position


# TODO (DIFF-02): Add override_entry_point_count(n: int) for Surge Night to force all 4 entry points.
