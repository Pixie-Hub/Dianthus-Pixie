class_name MapView
extends Control

@export var map_size: Vector2 = Vector2(80, 80)
@export var world_to_map_scale: float = 0.08
@export var center_on_player: bool = true
@export var fit_world_bounds: bool = false
@export var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1536, 1152))
@export var map_padding: float = 0.0
@export var marker_scale: float = 1.0
@export var show_world_bounds: bool = false

const PLAYER_DOT_RADIUS: float = 3.0
const CORE_DOT_RADIUS: float = 3.5
const PLANT_DOT_RADIUS: float = 2.0
const ENEMY_DOT_RADIUS: float = 2.5
const ARROW_SIZE: float = 5.0

const PLAYER_DOT_COLOR: Color = Color(1, 1, 1)
const CORE_DOT_COLOR: Color = Color(1.0, 0.4, 0.7)
const PLANT_DOT_COLOR: Color = Color(0.3, 0.9, 0.3)
const ENEMY_DOT_COLOR: Color = Color(0.95, 0.25, 0.25)
const SCOUT_ARROW_COLOR: Color = Color(1.0, 0.85, 0.2, 1)
const EVENT_MARKER_COLOR: Color = Color(1.0, 0.85, 0.2, 1.0)
const EVENT_MARKER_RADIUS: float = 4.0
const BOUNDS_COLOR: Color = Color(0.65, 0.50, 0.25, 0.9)
const WORLD_BOUNDS_COLOR: Color = Color(0.45, 0.72, 0.42, 0.85)
const BG_COLOR: Color = Color(0.08, 0.08, 0.12, 0.85)

var _spawner: WaveSpawner = null
var _plant_manager: Node = null
var _event_spawner: Node = null


func _ready() -> void:
	custom_minimum_size = map_size
	call_deferred("refresh_references")


func refresh_references() -> void:
	if not is_inside_tree():
		return
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	_spawner = scene_root.find_child("WaveSpawner", true, false) as WaveSpawner
	_plant_manager = scene_root.find_child("PlantPlacementManager", true, false)
	_event_spawner = scene_root.find_child("DaytimeEventSpawner", true, false)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var draw_size: Vector2 = _get_draw_size()
	var draw_rect_area: Rect2 = Rect2(Vector2.ZERO, draw_size)
	draw_rect(draw_rect_area, BG_COLOR)

	var player: Node = GameManager.player
	var core: Node = GameManager.dianthus_core
	if not is_instance_valid(player):
		return

	var player_pos: Vector2 = (player as Node2D).global_position

	if show_world_bounds:
		_draw_world_rect(world_bounds, player_pos, WORLD_BOUNDS_COLOR, 1.0)

	if is_instance_valid(_plant_manager) and _plant_manager.has_method("get_garden_origin"):
		var origin: Vector2 = _plant_manager.get_garden_origin()
		var size_w: Vector2 = _plant_manager.get_garden_size_world()
		_draw_world_rect(Rect2(origin, size_w), player_pos, BOUNDS_COLOR, 1.0)

	if is_instance_valid(_plant_manager) and _plant_manager.has_method("get_active_plants"):
		var plants: Array = _plant_manager.get_active_plants()
		for plant: Node2D in plants:
			if is_instance_valid(plant):
				var plant_mp: Vector2 = _world_to_map(plant.global_position, player_pos)
				if draw_rect_area.has_point(plant_mp):
					draw_circle(plant_mp, PLANT_DOT_RADIUS * marker_scale, PLANT_DOT_COLOR)

	if is_instance_valid(core):
		var core_mp: Vector2 = _world_to_map((core as Node2D).global_position, player_pos)
		core_mp = _clamp_to_map(core_mp, draw_size)
		draw_circle(core_mp, CORE_DOT_RADIUS * marker_scale, CORE_DOT_COLOR)

	for enemy: Node2D in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy):
			var enemy_mp: Vector2 = _world_to_map(enemy.global_position, player_pos)
			if draw_rect_area.has_point(enemy_mp):
				draw_circle(enemy_mp, ENEMY_DOT_RADIUS * marker_scale, ENEMY_DOT_COLOR)

	var player_mp: Vector2 = _get_player_map_position(player_pos)
	if draw_rect_area.has_point(player_mp):
		draw_circle(player_mp, PLAYER_DOT_RADIUS * marker_scale, PLAYER_DOT_COLOR)

	if not DayNightCycle.is_night():
		if is_instance_valid(_event_spawner) and _event_spawner.has_method("has_active_event"):
			if _event_spawner.has_active_event():
				var ev_pos: Vector2 = _event_spawner.get_active_event_position()
				_draw_event_marker(ev_pos, player_pos, draw_size, draw_rect_area)
		return
	if _spawner == null or not _spawner.is_wave_active():
		return

	for spawn_pt: Vector2 in _spawner.get_active_spawn_points():
		var dir: Vector2 = (spawn_pt - player_pos).normalized()
		var edge_pt: Vector2 = _compute_box_edge(player_mp, dir, draw_size)
		_draw_arrow(edge_pt, dir)


func _draw_world_rect(world_rect: Rect2, player_pos: Vector2, color: Color, width: float) -> void:
	var draw_size: Vector2 = _get_draw_size()
	var tl: Vector2 = _world_to_map(world_rect.position, player_pos)
	var br: Vector2 = _world_to_map(world_rect.position + world_rect.size, player_pos)
	tl = _clamp_to_map(tl, draw_size)
	br = _clamp_to_map(br, draw_size)
	var rect_size: Vector2 = br - tl
	if absf(rect_size.x) < 1.0 or absf(rect_size.y) < 1.0:
		return
	draw_rect(Rect2(tl, rect_size), color, false, width)


func _world_to_map(world_pos: Vector2, player_pos: Vector2) -> Vector2:
	var draw_size: Vector2 = _get_draw_size()
	if fit_world_bounds:
		return _world_to_fitted_map(world_pos, draw_size)
	return (world_pos - player_pos) * world_to_map_scale + draw_size * 0.5


func _world_to_fitted_map(world_pos: Vector2, draw_size: Vector2) -> Vector2:
	var bounds: Rect2 = _get_effective_world_bounds()
	var fit_scale: float = _get_fit_scale(bounds, draw_size)
	var content_size: Vector2 = bounds.size * fit_scale
	var offset: Vector2 = (draw_size - content_size) * 0.5
	return offset + (world_pos - bounds.position) * fit_scale


func _get_effective_world_bounds() -> Rect2:
	if world_bounds.size.x <= 0.0 or world_bounds.size.y <= 0.0:
		return Rect2(Vector2.ZERO, Vector2.ONE)
	return world_bounds


func _get_fit_scale(bounds: Rect2, draw_size: Vector2) -> float:
	var usable_size: Vector2 = Vector2(
		maxf(1.0, draw_size.x - map_padding * 2.0),
		maxf(1.0, draw_size.y - map_padding * 2.0)
	)
	var fit_scale: float = minf(usable_size.x / bounds.size.x, usable_size.y / bounds.size.y)
	return fit_scale


func _get_player_map_position(player_pos: Vector2) -> Vector2:
	if center_on_player:
		return _get_draw_size() * 0.5
	return _world_to_map(player_pos, player_pos)


func _get_draw_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	return map_size


func _clamp_to_map(map_pos: Vector2, draw_size: Vector2) -> Vector2:
	return map_pos.clamp(Vector2.ZERO, draw_size)


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


func _draw_event_marker(world_pos: Vector2, player_pos: Vector2, draw_size: Vector2, draw_rect_area: Rect2) -> void:
	var mp: Vector2 = _world_to_map(world_pos, player_pos)
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse_alpha: float = 0.6 + 0.4 * sin(t * TAU * 1.5)
	var color: Color = Color(EVENT_MARKER_COLOR.r, EVENT_MARKER_COLOR.g, EVENT_MARKER_COLOR.b, pulse_alpha)
	var edge_mp: Vector2 = mp
	if not draw_rect_area.has_point(mp):
		var dir: Vector2 = (mp - draw_size * 0.5).normalized()
		edge_mp = _compute_box_edge(draw_size * 0.5, dir, draw_size)
	draw_circle(edge_mp, EVENT_MARKER_RADIUS * marker_scale, color)


func _draw_arrow(tip: Vector2, dir: Vector2) -> void:
	_draw_arrow_colored(tip, dir, SCOUT_ARROW_COLOR)


func _draw_arrow_colored(tip: Vector2, dir: Vector2, color: Color) -> void:
	var scaled_arrow_size: float = ARROW_SIZE * marker_scale
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var base: Vector2 = tip - dir * scaled_arrow_size
	var p1: Vector2 = base + perp * (scaled_arrow_size * 0.5)
	var p2: Vector2 = base - perp * (scaled_arrow_size * 0.5)
	var points: PackedVector2Array = [tip, p1, p2]
	draw_colored_polygon(points, color)
