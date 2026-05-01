extends Node2D

const ZONE_WIDTH: int = 96
const ZONE_HEIGHT: int = 72
const TILE_SIZE: int = 16
const MAP_WIDTH: int = ZONE_WIDTH * TILE_SIZE
const MAP_HEIGHT: int = ZONE_HEIGHT * TILE_SIZE

@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _phase_label: Label = $DebugOverlay/PhaseLabel
@onready var _day_label: Label = $DebugOverlay/DayLabel
@onready var _timer_label: Label = $DebugOverlay/TimerLabel
@onready var _player: CharacterBody2D = $YSortLayer/Player

var _wave_spawner: WaveSpawner = null

func _ready() -> void:
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


func get_map_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(MAP_WIDTH, MAP_HEIGHT))


func get_map_display_name() -> String:
	return "Meadow Edge"

func _setup_camera() -> void:
	if is_instance_valid(_player) and _player.has_method("set_camera_limits"):
		_player.set_camera_limits(0, 0, MAP_WIDTH, MAP_HEIGHT)

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
