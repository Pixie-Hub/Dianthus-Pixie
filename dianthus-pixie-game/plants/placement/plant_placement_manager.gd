extends Node2D

signal placement_mode_changed(active: bool)
signal plant_placed(seed_id: String, grid_pos: Vector2i)
signal placement_failed(reason: String)

const GRID_SIZE: int = 16
const DEFAULT_GARDEN_SIZE: Vector2i = Vector2i(12, 10)

# Each tier: { size, plant_cap, min_day, cost_verdant_sap, cost_stone }
const EXPANSION_TIERS: Array[Dictionary] = [
	{ "size": Vector2i(14, 12), "plant_cap": 10, "min_day": 3,  "cost_verdant_sap": 5,  "cost_stone": 8  },
	{ "size": Vector2i(16, 13), "plant_cap": 12, "min_day": 5,  "cost_verdant_sap": 8,  "cost_stone": 12 },
	{ "size": Vector2i(18, 15), "plant_cap": 14, "min_day": 8,  "cost_verdant_sap": 12, "cost_stone": 18 },
	{ "size": Vector2i(20, 16), "plant_cap": 16, "min_day": 12, "cost_verdant_sap": 16, "cost_stone": 24 },
]

const SEED_TO_SCENE: Dictionary = {
	"bougainvillea_seed": "res://plants/entities/bougainvillea.tscn",
	"rafflesia_seed": "res://plants/entities/rafflesia.tscn",
	"bunga_api_seed": "res://plants/entities/bunga_api.tscn",
	"bunga_bayang_seed": "res://plants/entities/bunga_bayang.tscn",
	"melati_emas_seed": "res://plants/entities/melati_emas.tscn",
	"baja_kuning_seed": "res://plants/entities/baja_kuning.tscn",
	"melati_seed": "res://plants/entities/melati.tscn",
	"wijaya_kusuma_seed": "res://plants/entities/wijaya_kusuma.tscn",
	"beringin_seed": "res://plants/entities/beringin.tscn",
	"kecombrang_seed": "res://plants/entities/kecombrang.tscn",
	"kunyit_seed": "res://plants/entities/kunyit.tscn",
}

const SEED_RADIUS_COLORS: Dictionary = {
	"bougainvillea_seed": Color(0.85, 0.15, 0.45, 0.25),
	"rafflesia_seed": Color(0.65, 0.12, 0.15, 0.25),
	"bunga_api_seed": Color(1.0, 0.4, 0.1, 0.25),
	"bunga_bayang_seed": Color(0.3, 0.1, 0.4, 0.25),
	"melati_emas_seed": Color(1.0, 0.85, 0.3, 0.25),
	"baja_kuning_seed": Color(0.85, 0.7, 0.15, 0.25),
	"melati_seed": Color(0.9, 0.95, 1.0, 0.25),
	"wijaya_kusuma_seed": Color(0.94, 0.91, 1.0, 0.25),
	"beringin_seed": Color(0.24, 0.48, 0.13, 0.25),
	"kecombrang_seed": Color(1.0, 0.22, 0.38, 0.25),
	"kunyit_seed": Color(0.83, 0.72, 0.13, 0.25),
}

const SEED_EFFECT_RADIUS: Dictionary = {
	"bougainvillea_seed": 24.0,
	"rafflesia_seed": 40.0,
	"bunga_api_seed": 28.0,
	"bunga_bayang_seed": 36.0,
	"melati_emas_seed": 32.0,
	"baja_kuning_seed": 28.0,
	"melati_seed": 32.0,
	"wijaya_kusuma_seed": 48.0,
	"beringin_seed": 32.0,
	"kecombrang_seed": 28.0,
	"kunyit_seed": 24.0,
}

var is_placement_mode: bool = false
var selected_seed_id: String = ""
var _ghost_grid_pos: Vector2i = Vector2i.ZERO
var _garden_origin: Vector2 = Vector2.ZERO
var _garden_size: Vector2i = DEFAULT_GARDEN_SIZE
var _occupied_tiles: Dictionary = {}
var _core_tile: Vector2i = Vector2i(-1, -1)
var _palette_ui: Node = null
var expansion_tier: int = 0


func _ready() -> void:
	_update_garden_origin()
	_rebuild_occupied_tiles()
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	SaveManager.load_completed.connect(_on_load_completed)
	_create_palette_ui()
	set_process(false)
	# TODO: CORE-09 — restrict placement to Afternoon sub-phase when sub-phases are added


func _create_palette_ui() -> void:
	var palette: Node = preload("res://plants/placement/plant_palette_ui.gd").new()
	_palette_ui = palette
	add_child(palette)
	palette.setup(self)


func toggle_placement_mode() -> void:
	if is_placement_mode:
		exit_placement_mode()
	else:
		if not DayNightCycle.is_day():
			placement_failed.emit("Cannot place plants at night.")
			print("[PlantPlacement] Blocked: cannot place plants at night.")
			return
		is_placement_mode = true
		if is_instance_valid(_palette_ui):
			_palette_ui.show_palette()
		placement_mode_changed.emit(true)
		queue_redraw()


func exit_placement_mode() -> void:
	is_placement_mode = false
	selected_seed_id = ""
	if is_instance_valid(_palette_ui):
		_palette_ui.hide_palette()
	placement_mode_changed.emit(false)
	queue_redraw()


func select_seed(seed_id: String) -> void:
	if not SEED_TO_SCENE.has(seed_id):
		return
	if not InventoryManager.has_item(seed_id):
		return
	selected_seed_id = seed_id
	queue_redraw()


func _snap_to_grid(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = world_pos - _garden_origin
	return Vector2i(floori(local.x / GRID_SIZE), floori(local.y / GRID_SIZE))


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return _garden_origin + Vector2(grid_pos.x * GRID_SIZE + GRID_SIZE * 0.5, grid_pos.y * GRID_SIZE + GRID_SIZE * 0.5)


func _is_within_garden(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < _garden_size.x and grid_pos.y >= 0 and grid_pos.y < _garden_size.y


func _is_tile_occupied(grid_pos: Vector2i) -> bool:
	return _occupied_tiles.has(grid_pos) or grid_pos == _core_tile


func _get_active_plant_count() -> int:
	return get_tree().get_nodes_in_group("plants").filter(
		func(p: Node) -> bool: return p is PlantBase and not (p as PlantBase).is_destroyed
	).size()


func _can_place() -> bool:
	return (
		selected_seed_id != "" and
		DayNightCycle.is_day() and
		_is_within_garden(_ghost_grid_pos) and
		not _is_tile_occupied(_ghost_grid_pos) and
		_get_active_plant_count() < get_plant_cap() and
		InventoryManager.has_item(selected_seed_id)
	)


func _place_plant() -> void:
	if not _can_place():
		return
	var packed: PackedScene = load(SEED_TO_SCENE[selected_seed_id]) as PackedScene
	if packed == null:
		push_warning("[PlantPlacement] Could not load scene for %s" % selected_seed_id)
		return
	var plant: PlantBase = packed.instantiate() as PlantBase
	plant.global_position = _grid_to_world(_ghost_grid_pos)
	var _ys: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	(_ys if _ys != null else get_tree().current_scene).add_child(plant)
	_occupied_tiles[_ghost_grid_pos] = plant
	plant.plant_destroyed.connect(_on_plant_destroyed)
	InventoryManager.remove_item(selected_seed_id, 1)
	var placed_plant_id: String = selected_seed_id.trim_suffix("_seed")
	CodexManager.discover_plant(placed_plant_id)
	SfxManager.play("plant_placed")
	plant_placed.emit(selected_seed_id, _ghost_grid_pos)
	print("[PlantPlacement] Placed %s at grid %s (world %s)" % [
		selected_seed_id, _ghost_grid_pos, plant.global_position])
	if not InventoryManager.has_item(selected_seed_id):
		selected_seed_id = ""
	if is_instance_valid(_palette_ui):
		_palette_ui.refresh()
	queue_redraw()


func _on_plant_destroyed(plant: PlantBase) -> void:
	for tile: Vector2i in _occupied_tiles.keys():
		if _occupied_tiles[tile] == plant:
			_occupied_tiles.erase(tile)
			break
	queue_redraw()


func _on_phase_changed(_phase: String) -> void:
	if DayNightCycle.is_night() and is_placement_mode:
		exit_placement_mode()


func _on_load_completed(_success: bool) -> void:
	_update_garden_origin()
	_rebuild_occupied_tiles()
	if is_placement_mode:
		queue_redraw()


func _update_garden_origin() -> void:
	if expansion_tier > 0 and expansion_tier <= EXPANSION_TIERS.size():
		_garden_size = EXPANSION_TIERS[expansion_tier - 1]["size"]
	else:
		_garden_size = DEFAULT_GARDEN_SIZE
	if is_instance_valid(GameManager.dianthus_core):
		var core_pos: Vector2 = GameManager.dianthus_core.global_position
		_garden_origin = core_pos - Vector2(_garden_size.x * GRID_SIZE / 2.0, _garden_size.y * GRID_SIZE / 2.0)
		_core_tile = _snap_to_grid(core_pos)
	else:
		_garden_origin = Vector2(224.0, 160.0)
		_core_tile = Vector2i(6, 5)


func _rebuild_occupied_tiles() -> void:
	_occupied_tiles.clear()
	for plant: Node in get_tree().get_nodes_in_group("plants"):
		if not plant is PlantBase:
			continue
		var pb: PlantBase = plant as PlantBase
		if pb.is_destroyed:
			continue
		var tile: Vector2i = _snap_to_grid(pb.global_position)
		_occupied_tiles[tile] = pb
		if not pb.plant_destroyed.is_connected(_on_plant_destroyed):
			pb.plant_destroyed.connect(_on_plant_destroyed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("plant_mode_toggle"):
		toggle_placement_mode()
		get_viewport().set_input_as_handled()
		return

	if not is_placement_mode:
		return

	if event is InputEventMouseMotion:
		_ghost_grid_pos = _snap_to_grid(get_global_mouse_position())
		queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if selected_seed_id != "" and _can_place():
				_place_plant()
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if selected_seed_id != "":
				selected_seed_id = ""
				queue_redraw()
			else:
				exit_placement_mode()
			get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel"):
		if selected_seed_id != "":
			selected_seed_id = ""
			queue_redraw()
		else:
			exit_placement_mode()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if not is_placement_mode:
		return

	# 1. Garden bounds outline (white rectangle).
	var garden_rect: Rect2 = Rect2(
		_garden_origin - global_position,
		Vector2(_garden_size.x * GRID_SIZE, _garden_size.y * GRID_SIZE)
	)
	draw_rect(garden_rect, Color(1, 1, 1, 0.3), false, 1.0)

	# 2. Grid lines (subtle).
	for x: int in range(_garden_size.x + 1):
		var from_pt: Vector2 = garden_rect.position + Vector2(x * GRID_SIZE, 0)
		var to_pt: Vector2 = from_pt + Vector2(0, garden_rect.size.y)
		draw_line(from_pt, to_pt, Color(1, 1, 1, 0.08), 1.0)
	for y: int in range(_garden_size.y + 1):
		var from_pt: Vector2 = garden_rect.position + Vector2(0, y * GRID_SIZE)
		var to_pt: Vector2 = from_pt + Vector2(garden_rect.size.x, 0)
		draw_line(from_pt, to_pt, Color(1, 1, 1, 0.08), 1.0)

	# 3. Occupied tiles — small red squares.
	for tile: Vector2i in _occupied_tiles:
		var tile_world: Vector2 = _grid_to_world(tile) - global_position
		draw_rect(
			Rect2(tile_world - Vector2(GRID_SIZE * 0.5, GRID_SIZE * 0.5), Vector2(GRID_SIZE, GRID_SIZE)),
			Color(1, 0.3, 0.3, 0.15), true
		)

	# 4. Core tile — blocked indicator.
	if _core_tile != Vector2i(-1, -1):
		var core_world: Vector2 = _grid_to_world(_core_tile) - global_position
		draw_rect(
			Rect2(core_world - Vector2(GRID_SIZE * 0.5, GRID_SIZE * 0.5), Vector2(GRID_SIZE, GRID_SIZE)),
			Color(1, 0.8, 0.9, 0.2), true
		)

	# 5. Existing plant radius circles (dim).
	for tile: Vector2i in _occupied_tiles:
		var plant: PlantBase = _occupied_tiles[tile]
		if is_instance_valid(plant) and not plant.is_destroyed:
			var center: Vector2 = plant.global_position - global_position
			draw_circle(center, plant.effect_radius, Color(0.6, 0.8, 1.0, 0.1))
			draw_arc(center, plant.effect_radius, 0, TAU, 64, Color(0.6, 0.8, 1.0, 0.2), 1.0)

	# 6. Ghost preview + radius (only if seed selected).
	if selected_seed_id == "":
		return

	var ghost_world: Vector2 = _grid_to_world(_ghost_grid_pos) - global_position
	var can_place: bool = _can_place()
	var ghost_color: Color = Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

	# Ghost tile highlight.
	draw_rect(
		Rect2(ghost_world - Vector2(GRID_SIZE * 0.5, GRID_SIZE * 0.5), Vector2(GRID_SIZE, GRID_SIZE)),
		ghost_color, true
	)

	# Effect radius circle.
	var radius: float = SEED_EFFECT_RADIUS.get(selected_seed_id, 24.0)
	var radius_color: Color = SEED_RADIUS_COLORS.get(selected_seed_id, Color(0.5, 0.5, 1.0, 0.25))
	if not can_place:
		radius_color = Color(1.0, 0.2, 0.2, 0.15)
	draw_circle(ghost_world, radius, radius_color)
	draw_arc(ghost_world, radius, 0, TAU, 64, Color(radius_color, 0.6), 1.0)
	# TODO: UI-09 — plant removal/uprooting mechanic


func get_active_plants() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for tile: Vector2i in _occupied_tiles.keys():
		var plant: Node2D = _occupied_tiles[tile] as Node2D
		if is_instance_valid(plant):
			result.append(plant)
	return result


func get_garden_origin() -> Vector2:
	return _garden_origin


func get_garden_size_world() -> Vector2:
	return Vector2(_garden_size.x * GRID_SIZE, _garden_size.y * GRID_SIZE)


func get_plant_cap() -> int:
	if expansion_tier > 0 and expansion_tier <= EXPANSION_TIERS.size():
		return int(EXPANSION_TIERS[expansion_tier - 1]["plant_cap"])
	return 8


func get_next_tier_data() -> Dictionary:
	if expansion_tier >= EXPANSION_TIERS.size():
		return {}
	return EXPANSION_TIERS[expansion_tier]


func can_expand() -> bool:
	if expansion_tier >= EXPANSION_TIERS.size():
		return false
	var tier: Dictionary = EXPANSION_TIERS[expansion_tier]
	if DayNightCycle.day_count < int(tier["min_day"]):
		return false
	if not DayNightCycle.is_day():
		return false
	if InventoryManager.get_total_count("verdant_sap") < int(tier["cost_verdant_sap"]):
		return false
	if InventoryManager.get_total_count("stone") < int(tier["cost_stone"]):
		return false
	return true


func expand_garden() -> bool:
	if not can_expand():
		return false
	var tier: Dictionary = EXPANSION_TIERS[expansion_tier]
	InventoryManager.remove_item("verdant_sap", int(tier["cost_verdant_sap"]))
	InventoryManager.remove_item("stone", int(tier["cost_stone"]))
	expansion_tier += 1
	_update_garden_origin()
	_rebuild_occupied_tiles()
	queue_redraw()
	print("[PlantPlacement] Garden expanded to tier %d: %s, cap=%d" % [
		expansion_tier, _garden_size, get_plant_cap()])
	return true
