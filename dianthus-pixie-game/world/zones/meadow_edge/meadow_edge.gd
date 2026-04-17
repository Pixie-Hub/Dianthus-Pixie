extends Node2D

const ZONE_WIDTH: int = 40
const ZONE_HEIGHT: int = 30
const TILE_SIZE: int = 16

@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _phase_label: Label = $DebugOverlay/PhaseLabel
@onready var _day_label: Label = $DebugOverlay/DayLabel
@onready var _timer_label: Label = $DebugOverlay/TimerLabel
@onready var _player: CharacterBody2D = $Player

var _wave_spawner: WaveSpawner = null

func _ready() -> void:
	DayNightCycle.register_canvas_modulate(_canvas_modulate)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_update_debug_labels()
	_setup_camera()
	_restore_player_position()
	var core: Node = $DianthusCore
	if is_instance_valid(core) and core.has_method("get_hp_ratio"):
		GameManager.register_core(core)
	if is_instance_valid(_player):
		GameManager.register_player(_player)
	_wave_spawner = get_node_or_null("WaveSpawner") as WaveSpawner
	if is_instance_valid(_wave_spawner):
		_wave_spawner.wave_started.connect(_on_wave_started)
		_wave_spawner.wave_cleared.connect(_on_wave_cleared)

func _process(_delta: float) -> void:
	if is_instance_valid(_timer_label):
		_timer_label.text = "Time: %.1fs" % DayNightCycle.get_time_remaining()

func _setup_camera() -> void:
	if is_instance_valid(_player) and _player.has_method("set_camera_limits"):
		_player.set_camera_limits(0, 0, ZONE_WIDTH * TILE_SIZE, ZONE_HEIGHT * TILE_SIZE)

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
	# TODO (CORE-09): Notify win condition manager that defense phase has begun.
	print("[MeadowEdge] Wave started.")


func _on_wave_cleared() -> void:
	# TODO (CORE-09): Trigger night-survived result screen here.
	print("[MeadowEdge] Wave cleared — night survived!")
