extends Control

@onready var _label: Label = %WaveCounterLabel

var _spawner: WaveSpawner = null
var _alive: int = 0
var _total: int = 0
var _poll_timer: float = 0.0
const POLL_INTERVAL: float = 0.2


func _ready() -> void:
	visible = false
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	call_deferred("_connect_spawner")


func _connect_spawner() -> void:
	if not is_inside_tree():
		return
	_spawner = get_tree().current_scene.find_child("WaveSpawner", true, false) as WaveSpawner
	if _spawner:
		_spawner.wave_started.connect(_on_wave_started)
		_spawner.wave_cleared.connect(_on_wave_cleared)


func _process(delta: float) -> void:
	if not visible or _spawner == null:
		return
	_poll_timer -= delta
	if _poll_timer <= 0.0:
		_poll_timer = POLL_INTERVAL
		_alive = _spawner.get_alive_count()
		# TODO (DIFF-02): replace "1 / 1" with real wave_index / wave_count for Surge Night
		_label.text = "Wave 1 / 1   Enemies: %d / %d" % [_alive, _total]


func _on_phase_changed(phase: String) -> void:
	visible = (phase == "NIGHT")
	if phase == "NIGHT":
		_alive = 0
		_total = 0
		_label.text = "Wave 1 / 1   Enemies: 0 / 0"


func _on_wave_started() -> void:
	if _spawner:
		_total = _spawner.get_wave_total()
	_alive = 0
	_label.text = "Wave 1 / 1   Enemies: 0 / %d" % _total


func _on_wave_cleared() -> void:
	_alive = 0
	_label.text = "Wave 1 / 1   Enemies: 0 / %d" % _total
