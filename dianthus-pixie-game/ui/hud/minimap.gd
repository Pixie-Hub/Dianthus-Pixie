extends Control

const MAP_SIZE: Vector2 = Vector2(80, 80)
const WORLD_TO_MAP_SCALE: float = 0.08
const PLAYER_DOT_RADIUS: float = 3.0
const CORE_DOT_RADIUS: float = 3.5
const PLANT_DOT_RADIUS: float = 2.0
const ARROW_SIZE: float = 5.0

const PLAYER_DOT_COLOR: Color = Color(1, 1, 1)
const CORE_DOT_COLOR: Color = Color(1.0, 0.4, 0.7)
const PLANT_DOT_COLOR: Color = Color(0.3, 0.9, 0.3)
const ENEMY_DOT_COLOR: Color = Color(0.95, 0.25, 0.25)
const ENEMY_DOT_RADIUS: float = 2.5
const SPAWN_ARROW_COLOR: Color = Color(0.95, 0.25, 0.25)
const BOUNDS_COLOR: Color = Color(0.65, 0.50, 0.25, 0.9)
const BG_COLOR: Color = Color(0.08, 0.08, 0.12, 0.85)

var _spawner: WaveSpawner = null
var _plant_manager: Node = null


func _ready() -> void:
	custom_minimum_size = MAP_SIZE
	call_deferred("_cache_refs")


func _cache_refs() -> void:
	if not is_inside_tree():
		return
	var scene_root: Node = get_tree().current_scene
	_spawner = scene_root.find_child("WaveSpawner", true, false) as WaveSpawner
	_plant_manager = scene_root.find_child("PlantPlacementManager", true, false)


func _process(_delta: float) -> void:
	queue_redraw()


func _world_to_map(world_pos: Vector2, player_pos: Vector2) -> Vector2:
	return (world_pos - player_pos) * WORLD_TO_MAP_SCALE + MAP_SIZE * 0.5


func _clamp_to_map(mp: Vector2) -> Vector2:
	return mp.clamp(Vector2.ZERO, MAP_SIZE)


func _draw() -> void:
	# Background.
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), BG_COLOR)

	var player: Node = GameManager.player
	var core: Node = GameManager.dianthus_core

	if not is_instance_valid(player):
		return

	var player_pos: Vector2 = (player as Node2D).global_position

	# Garden bounds rectangle.
	if is_instance_valid(_plant_manager) and _plant_manager.has_method("get_garden_origin"):
		var origin: Vector2 = _plant_manager.get_garden_origin()
		var size_w: Vector2 = _plant_manager.get_garden_size_world()
		var tl: Vector2 = _world_to_map(origin, player_pos)
		var br: Vector2 = _world_to_map(origin + size_w, player_pos)
		tl = tl.clamp(Vector2.ZERO, MAP_SIZE)
		br = br.clamp(Vector2.ZERO, MAP_SIZE)
		draw_rect(Rect2(tl, br - tl), BOUNDS_COLOR, false, 1.0)

	# Plant dots.
	if is_instance_valid(_plant_manager) and _plant_manager.has_method("get_active_plants"):
		var plants: Array = _plant_manager.get_active_plants()
		for plant: Node2D in plants:
			if is_instance_valid(plant):
				var mp: Vector2 = _world_to_map((plant as Node2D).global_position, player_pos)
				if Rect2(Vector2.ZERO, MAP_SIZE).has_point(mp):
					draw_circle(mp, PLANT_DOT_RADIUS, PLANT_DOT_COLOR)

	# Core dot.
	if is_instance_valid(core):
		var core_mp: Vector2 = _world_to_map((core as Node2D).global_position, player_pos)
		core_mp = _clamp_to_map(core_mp)
		draw_circle(core_mp, CORE_DOT_RADIUS, CORE_DOT_COLOR)

	# Enemy dots.
	for enemy: Node2D in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy):
			var emp: Vector2 = _world_to_map(enemy.global_position, player_pos)
			if Rect2(Vector2.ZERO, MAP_SIZE).has_point(emp):
				draw_circle(emp, ENEMY_DOT_RADIUS, ENEMY_DOT_COLOR)

	# Player dot (always center).
	draw_circle(MAP_SIZE * 0.5, PLAYER_DOT_RADIUS, PLAYER_DOT_COLOR)

	# Spawn-direction arrows — night only.
	if not DayNightCycle.is_night():
		return
	if _spawner == null or not _spawner.is_wave_active():
		return

	for spawn_pt: Vector2 in _spawner.get_active_spawn_points():
		var dir: Vector2 = (spawn_pt - player_pos).normalized()
		var edge_pt: Vector2 = _compute_box_edge(MAP_SIZE * 0.5, dir, MAP_SIZE)
		_draw_arrow(edge_pt, dir)


func _compute_box_edge(center: Vector2, dir: Vector2, box_size: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return center
	var t_values: Array[float] = []
	if dir.x != 0.0:
		t_values.append((0.0 - center.x) / dir.x)
		t_values.append((box_size.x - center.x) / dir.x)
	if dir.y != 0.0:
		t_values.append((0.0 - center.y) / dir.y)
		t_values.append((box_size.y - center.y) / dir.y)
	var best_t: float = 0.0
	for t: float in t_values:
		if t > 0.0:
			var candidate: Vector2 = center + dir * t
			if candidate.x >= -0.5 and candidate.x <= box_size.x + 0.5 and \
			   candidate.y >= -0.5 and candidate.y <= box_size.y + 0.5:
				if t < best_t or best_t == 0.0:
					best_t = t
	return center + dir * best_t


func _draw_arrow(tip: Vector2, dir: Vector2) -> void:
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var base: Vector2 = tip - dir * ARROW_SIZE
	var p1: Vector2 = base + perp * (ARROW_SIZE * 0.5)
	var p2: Vector2 = base - perp * (ARROW_SIZE * 0.5)
	var points: PackedVector2Array = [tip, p1, p2]
	draw_colored_polygon(points, SPAWN_ARROW_COLOR)
