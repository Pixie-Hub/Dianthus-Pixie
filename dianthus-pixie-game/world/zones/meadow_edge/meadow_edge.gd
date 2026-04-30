extends Node2D

const ZONE_WIDTH: int = 96
const ZONE_HEIGHT: int = 72
const TILE_SIZE: int = 16
const MAP_WIDTH: int = ZONE_WIDTH * TILE_SIZE
const MAP_HEIGHT: int = ZONE_HEIGHT * TILE_SIZE
const GROUND_SOURCE_ID: int = 0
const ROUTE_COLOR: Color = Color(0.58, 0.49, 0.30, 0.58)
const SOFT_GRASS_COLOR: Color = Color(0.32, 0.50, 0.24, 0.34)
const PETAL_FIELD_COLOR: Color = Color(0.58, 0.70, 0.36, 0.40)
const SAP_GROVE_COLOR: Color = Color(0.22, 0.43, 0.26, 0.42)
const ROOT_HOLLOW_COLOR: Color = Color(0.40, 0.31, 0.22, 0.42)
const RUIN_COLOR: Color = Color(0.46, 0.43, 0.38, 0.65)
const WATER_COLOR: Color = Color(0.18, 0.38, 0.52, 0.55)
const BARK_COLOR: Color = Color(0.34, 0.22, 0.12, 0.82)
const FLOWER_COLOR: Color = Color(0.96, 0.48, 0.72, 0.86)
const FLOWER_CORE_COLOR: Color = Color(1.0, 0.86, 0.35, 0.9)
const MAP_BLOCKER_COLOR: Color = Color(0.14, 0.24, 0.12, 0.74)

const GRASS_TILES: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(0, 5),
	Vector2i(1, 5),
	Vector2i(2, 5),
	Vector2i(3, 5),
	Vector2i(4, 5),
	Vector2i(5, 5),
	Vector2i(0, 6),
	Vector2i(1, 6),
	Vector2i(2, 6),
	Vector2i(3, 6),
	Vector2i(4, 6),
]

@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _tile_map: TileMapLayer = $TileMapLayer
@onready var _phase_label: Label = $DebugOverlay/PhaseLabel
@onready var _day_label: Label = $DebugOverlay/DayLabel
@onready var _timer_label: Label = $DebugOverlay/TimerLabel
@onready var _player: CharacterBody2D = $YSortLayer/Player

var _wave_spawner: WaveSpawner = null
var _map_visuals: Node2D = null
var _map_collision: Node2D = null

func _ready() -> void:
	_setup_expedition_map()
	DayNightCycle.register_canvas_modulate(_canvas_modulate)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_update_debug_labels()
	_setup_camera()
	_restore_player_position()
	var core: Node = $YSortLayer/DianthusCore
	if is_instance_valid(core) and core.has_method("get_hp_ratio"):
		GameManager.register_core(core)
	if is_instance_valid(_player):
		GameManager.register_player(_player)
	_refresh_placement_bounds()
	TutorialManager.notify_scene_ready()
	_wave_spawner = get_node_or_null("WaveSpawner") as WaveSpawner
	if is_instance_valid(_wave_spawner):
		_setup_wave_spawn_points()
		_wave_spawner.wave_started.connect(_on_wave_started)
		_wave_spawner.wave_cleared.connect(_on_wave_cleared)

func _process(_delta: float) -> void:
	if is_instance_valid(_timer_label):
		_timer_label.text = "Time: %.1fs" % DayNightCycle.get_time_remaining()

func _setup_camera() -> void:
	if is_instance_valid(_player) and _player.has_method("set_camera_limits"):
		_player.set_camera_limits(0, 0, MAP_WIDTH, MAP_HEIGHT)

func _setup_expedition_map() -> void:
	_paint_ground_tiles()
	_clear_generated_map_nodes()
	_map_visuals = Node2D.new()
	_map_visuals.name = "ExpeditionMapVisuals"
	_map_visuals.z_index = -9
	add_child(_map_visuals)
	move_child(_map_visuals, 2)

	_map_collision = Node2D.new()
	_map_collision.name = "ExpeditionMapCollision"
	add_child(_map_collision)

	_build_route_visuals()
	_build_landmarks()
	_build_collision_bounds()

func _paint_ground_tiles() -> void:
	if not is_instance_valid(_tile_map):
		return
	_tile_map.clear()
	_tile_map.z_index = -10
	for x: int in range(ZONE_WIDTH):
		for y: int in range(ZONE_HEIGHT):
			_tile_map.set_cell(Vector2i(x, y), GROUND_SOURCE_ID, _get_ground_tile(x, y), 0)

func _get_ground_tile(x: int, y: int) -> Vector2i:
	var index: int = abs((x * 31 + y * 17 + x * y) % GRASS_TILES.size())
	return GRASS_TILES[index]

func _clear_generated_map_nodes() -> void:
	for node_name: String in ["ExpeditionMapVisuals", "ExpeditionMapCollision"]:
		var node: Node = get_node_or_null(node_name)
		if node == null:
			continue
		remove_child(node)
		node.queue_free()

func _build_route_visuals() -> void:
	_create_ellipse_visual("GardenGateClearing", Vector2(768, 842), Vector2(230, 160), SOFT_GRASS_COLOR)
	_create_ellipse_visual("PetalFieldMeadow", Vector2(420, 640), Vector2(280, 210), PETAL_FIELD_COLOR)
	_create_ellipse_visual("SapGroveCanopy", Vector2(1160, 570), Vector2(300, 230), SAP_GROVE_COLOR)
	_create_ellipse_visual("OldRootHollowFloor", Vector2(720, 340), Vector2(250, 150), ROOT_HOLLOW_COLOR)
	_create_ellipse_visual("RuinGlimmerFloor", Vector2(760, 210), Vector2(210, 120), Color(0.38, 0.39, 0.34, 0.38))
	_create_ellipse_visual("SouthReturnPocket", Vector2(1030, 800), Vector2(180, 95), SOFT_GRASS_COLOR)

	_create_route_line("InnerReturnLoop", [
		Vector2(728, 882),
		Vector2(600, 820),
		Vector2(470, 720),
		Vector2(362, 612),
		Vector2(470, 520),
		Vector2(700, 540),
		Vector2(940, 640),
		Vector2(1030, 760),
		Vector2(880, 842),
		Vector2(728, 882),
	], 66.0, ROUTE_COLOR)
	_create_route_line("OuterRuinPath", [
		Vector2(470, 520),
		Vector2(560, 390),
		Vector2(690, 245),
		Vector2(845, 278),
		Vector2(1030, 410),
		Vector2(1205, 545),
	], 48.0, Color(0.50, 0.41, 0.27, 0.52))
	_create_route_line("SapSidePocketPath", [
		Vector2(1030, 760),
		Vector2(1115, 665),
		Vector2(1215, 590),
		Vector2(1320, 475),
	], 42.0, Color(0.40, 0.36, 0.24, 0.54))
	_create_route_line("PetalSidePocketPath", [
		Vector2(362, 612),
		Vector2(255, 548),
		Vector2(305, 455),
		Vector2(430, 470),
	], 42.0, Color(0.58, 0.49, 0.30, 0.44))

func _build_landmarks() -> void:
	_create_flower_ring("PetalFieldFlowerRing", Vector2(356, 596), 74.0)
	_create_rect_visual("SapGroveFallenTree", Rect2(Vector2(1078, 486), Vector2(282, 34)), BARK_COLOR)
	_create_rect_visual("SapGroveFallenTreeShadow", Rect2(Vector2(1090, 520), Vector2(248, 12)), Color(0.12, 0.11, 0.08, 0.42))
	_create_ellipse_visual("SapGrovePond", Vector2(1165, 725), Vector2(112, 54), WATER_COLOR)
	_create_ellipse_visual("OldRootGlow", Vector2(720, 342), Vector2(88, 38), Color(0.78, 0.62, 0.28, 0.35))
	_create_rect_visual("OldRootWestWall", Rect2(Vector2(565, 332), Vector2(150, 30)), BARK_COLOR)
	_create_rect_visual("OldRootEastWall", Rect2(Vector2(815, 332), Vector2(150, 30)), BARK_COLOR)
	_create_stone_arch()
	_create_rect_visual("WestThicketMarker", Rect2(Vector2(520, 622), Vector2(54, 180)), MAP_BLOCKER_COLOR)
	_create_rect_visual("SapThicketMarker", Rect2(Vector2(928, 592), Vector2(58, 188)), MAP_BLOCKER_COLOR)
	_create_rect_visual("NorthThicketMarker", Rect2(Vector2(952, 360), Vector2(78, 112)), MAP_BLOCKER_COLOR)

func _build_collision_bounds() -> void:
	var thickness: float = 32.0
	_add_rect_collider("NorthBoundary", Rect2(Vector2(-thickness, -thickness), Vector2(MAP_WIDTH + thickness * 2.0, thickness)))
	_add_rect_collider("SouthBoundary", Rect2(Vector2(-thickness, MAP_HEIGHT), Vector2(MAP_WIDTH + thickness * 2.0, thickness)))
	_add_rect_collider("WestBoundary", Rect2(Vector2(-thickness, 0.0), Vector2(thickness, MAP_HEIGHT)))
	_add_rect_collider("EastBoundary", Rect2(Vector2(MAP_WIDTH, 0.0), Vector2(thickness, MAP_HEIGHT)))

	_add_rect_collider("WestThicketBlocker", Rect2(Vector2(520, 622), Vector2(54, 180)))
	_add_rect_collider("SapGrovePondBlocker", Rect2(Vector2(1062, 690), Vector2(206, 76)))
	_add_rect_collider("SapFallenTreeBlocker", Rect2(Vector2(1078, 486), Vector2(282, 34)))
	_add_rect_collider("SapThicketBlocker", Rect2(Vector2(928, 592), Vector2(58, 188)))
	_add_rect_collider("NorthThicketBlocker", Rect2(Vector2(952, 360), Vector2(78, 112)))
	_add_rect_collider("OldRootWestBlocker", Rect2(Vector2(565, 332), Vector2(150, 30)))
	_add_rect_collider("OldRootEastBlocker", Rect2(Vector2(815, 332), Vector2(150, 30)))
	_add_rect_collider("RuinWestPillarBlocker", Rect2(Vector2(642, 150), Vector2(44, 150)))
	_add_rect_collider("RuinEastPillarBlocker", Rect2(Vector2(832, 150), Vector2(44, 150)))
	_add_rect_collider("RuinArchTopBlocker", Rect2(Vector2(642, 150), Vector2(234, 30)))

func _setup_wave_spawn_points() -> void:
	if not is_instance_valid(_wave_spawner):
		return
	var spawn_positions: Dictionary = {
		"SpawnNorth": Vector2(MAP_WIDTH * 0.5, -32.0),
		"SpawnSouth": Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT + 32.0),
		"SpawnEast": Vector2(MAP_WIDTH + 32.0, 832.0),
		"SpawnWest": Vector2(-32.0, 832.0),
	}
	for marker_name: String in spawn_positions:
		var marker: Marker2D = _wave_spawner.get_node_or_null(marker_name) as Marker2D
		if marker != null:
			marker.position = spawn_positions[marker_name]

func _refresh_placement_bounds() -> void:
	var manager: Node = get_node_or_null("PlantPlacementManager")
	if manager == null:
		return
	if manager.has_method("_update_garden_origin"):
		manager.call("_update_garden_origin")
	if manager.has_method("_rebuild_occupied_tiles"):
		manager.call("_rebuild_occupied_tiles")
	if manager.has_method("queue_redraw"):
		manager.queue_redraw()

func _create_route_line(node_name: String, points: Array, width: float, color: Color) -> void:
	if not is_instance_valid(_map_visuals):
		return
	var line: Line2D = Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var packed_points: PackedVector2Array = PackedVector2Array()
	for point in points:
		packed_points.append(point as Vector2)
	line.points = packed_points
	_map_visuals.add_child(line)

func _create_rect_visual(node_name: String, rect: Rect2, color: Color) -> void:
	_create_polygon_visual(node_name, PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]), color)

func _create_ellipse_visual(node_name: String, center: Vector2, radius: Vector2, color: Color) -> void:
	_create_polygon_visual(node_name, _ellipse_points(center, radius, 36), color)

func _create_polygon_visual(node_name: String, points: PackedVector2Array, color: Color) -> void:
	if not is_instance_valid(_map_visuals):
		return
	var poly: Polygon2D = Polygon2D.new()
	poly.name = node_name
	poly.polygon = points
	poly.color = color
	_map_visuals.add_child(poly)

func _create_flower_ring(node_name: String, center: Vector2, radius: float) -> void:
	var ring: Node2D = Node2D.new()
	ring.name = node_name
	_map_visuals.add_child(ring)
	for i: int in range(12):
		var angle: float = TAU * float(i) / 12.0
		var flower_center: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		var flower: Polygon2D = Polygon2D.new()
		flower.name = "PetalCluster%d" % i
		flower.polygon = _ellipse_points(flower_center, Vector2(12.0, 8.0), 14)
		flower.color = FLOWER_COLOR
		ring.add_child(flower)
	var core: Polygon2D = Polygon2D.new()
	core.name = "FlowerRingCenter"
	core.polygon = _ellipse_points(center, Vector2(24.0, 18.0), 20)
	core.color = FLOWER_CORE_COLOR
	ring.add_child(core)

func _create_stone_arch() -> void:
	_create_rect_visual("RuinGlimmerWestPillar", Rect2(Vector2(642, 150), Vector2(44, 150)), RUIN_COLOR)
	_create_rect_visual("RuinGlimmerEastPillar", Rect2(Vector2(832, 150), Vector2(44, 150)), RUIN_COLOR)
	_create_rect_visual("RuinGlimmerArchTop", Rect2(Vector2(642, 150), Vector2(234, 30)), RUIN_COLOR)
	_create_ellipse_visual("RuinGlimmerLight", Vector2(760, 226), Vector2(42, 22), Color(0.85, 0.78, 0.42, 0.35))

func _ellipse_points(center: Vector2, radius: Vector2, count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(count):
		var angle: float = TAU * float(i) / float(count)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points

func _add_rect_collider(node_name: String, rect: Rect2) -> void:
	if not is_instance_valid(_map_collision):
		return
	var body: StaticBody2D = StaticBody2D.new()
	body.name = node_name
	body.collision_layer = CollisionLayers.TERRAIN
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	_map_collision.add_child(body)

func _restore_player_position() -> void:
	var last_zone: String = GameManager.player_data["last_zone"]
	if last_zone != "" and last_zone != scene_file_path:
		if is_instance_valid(_player):
			_player.global_position = GameManager.player_data["position"]

func _on_phase_changed(_phase: String) -> void:
	_update_debug_labels()

func _update_debug_labels() -> void:
	if is_instance_valid(_phase_label):
		_phase_label.text = "Phase: %s" % DayNightCycle.get_phase_name()
	if is_instance_valid(_day_label):
		_day_label.text = "Day: %d" % DayNightCycle.day_count


func _on_wave_started() -> void:
	print("[MeadowEdge] Wave started.")


func _on_wave_cleared() -> void:
	GameManager.trigger_night_survived()
	print("[MeadowEdge] Wave cleared — night survived!")
