extends Node

signal defense_started(day: int)
signal defense_ended(day: int)
signal defense_progressed(elapsed_time: float, core_damage: int)
signal notification_requested(title: String, message: String, notification_type: String, key: String)

const MEADOW_EDGE_SCENE: String = "res://world/zones/meadow_edge/meadow_edge.tscn"
const BACKGROUND_GRACE_SECONDS: float = 12.0
const BACKGROUND_DAMAGE_INTERVAL: float = 8.0
const BACKGROUND_DAMAGE_PER_TICK: int = 8
const LOW_CORE_HP_RATIO: float = 0.50
const CRITICAL_CORE_HP_RATIO: float = 0.25

var active: bool = false
var night_day: int = 0
var elapsed_time: float = 0.0
var background_core_damage: int = 0
var spawner_has_resumed: bool = false

var _background_tick_timer: float = 0.0
var _warned_night_start: bool = false
var _warned_low_core: bool = false
var _warned_critical_core: bool = false
var _registered_spawner: WaveSpawner = null


func _ready() -> void:
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	if DayNightCycle.is_night():
		_start_defense(false)


func _process(delta: float) -> void:
	if not active or GameManager.current_state == GameManager.GameState.GAME_OVER:
		return
	elapsed_time += delta
	if _is_meadow_edge_loaded():
		return
	if elapsed_time < BACKGROUND_GRACE_SECONDS:
		return
	_background_tick_timer -= delta
	if _background_tick_timer > 0.0:
		return
	_background_tick_timer = BACKGROUND_DAMAGE_INTERVAL
	_apply_background_core_pressure()


func register_wave_spawner(spawner: WaveSpawner) -> void:
	_registered_spawner = spawner
	if active and DayNightCycle.is_night():
		resume_wave_spawner(spawner)


func unregister_wave_spawner(spawner: WaveSpawner) -> void:
	if _registered_spawner == spawner:
		_registered_spawner = null


func resume_wave_spawner(spawner: WaveSpawner) -> void:
	if not active or not is_instance_valid(spawner):
		return
	if spawner.is_wave_active():
		spawner_has_resumed = true
		return
	spawner.start_or_resume_night_defense(elapsed_time)
	spawner_has_resumed = true


func serialize() -> Dictionary:
	return {
		"active": active,
		"night_day": night_day,
		"elapsed_time": elapsed_time,
		"background_core_damage": background_core_damage,
		"background_tick_timer": _background_tick_timer,
		"warned_night_start": _warned_night_start,
		"warned_low_core": _warned_low_core,
		"warned_critical_core": _warned_critical_core,
		"spawner_has_resumed": spawner_has_resumed,
	}


func deserialize(data: Dictionary) -> void:
	active = bool(data.get("active", false)) and DayNightCycle.is_night()
	night_day = int(data.get("night_day", DayNightCycle.day_count))
	elapsed_time = maxf(0.0, float(data.get("elapsed_time", 0.0)))
	background_core_damage = maxi(0, int(data.get("background_core_damage", 0)))
	_background_tick_timer = maxf(0.0, float(data.get("background_tick_timer", BACKGROUND_DAMAGE_INTERVAL)))
	_warned_night_start = bool(data.get("warned_night_start", false))
	_warned_low_core = bool(data.get("warned_low_core", false))
	_warned_critical_core = bool(data.get("warned_critical_core", false))
	spawner_has_resumed = bool(data.get("spawner_has_resumed", false))
	if active:
		GameManager.set_state(GameManager.GameState.DEFENSE)
		if is_instance_valid(_registered_spawner):
			resume_wave_spawner(_registered_spawner)


func sync_to_day_night_state() -> void:
	if DayNightCycle.is_night():
		_start_defense(false)
	else:
		_end_defense(false)


func is_meadow_edge_loaded() -> bool:
	return _is_meadow_edge_loaded()


func get_elapsed_time() -> float:
	return elapsed_time


func _on_phase_changed(phase: String) -> void:
	if phase == "NIGHT":
		_start_defense(true)
	elif phase == "DAY":
		_end_defense(true)


func _start_defense(announce: bool) -> void:
	if active and night_day == DayNightCycle.day_count:
		return
	active = true
	night_day = DayNightCycle.day_count
	elapsed_time = 0.0
	background_core_damage = 0
	spawner_has_resumed = false
	_background_tick_timer = BACKGROUND_DAMAGE_INTERVAL
	_warned_night_start = false
	_warned_low_core = false
	_warned_critical_core = false
	defense_started.emit(night_day)
	if announce and not _is_meadow_edge_loaded():
		_warned_night_start = true
		notification_requested.emit(
				"Night has fallen",
				"The Dianthus Core is under attack. Return before it is too late.",
				"danger",
				"night_defense:start:%d" % night_day)
	if is_instance_valid(_registered_spawner):
		resume_wave_spawner(_registered_spawner)


func _end_defense(emit_signal: bool) -> void:
	if not active:
		return
	var ended_day: int = night_day
	active = false
	night_day = 0
	elapsed_time = 0.0
	background_core_damage = 0
	spawner_has_resumed = false
	_background_tick_timer = 0.0
	if emit_signal:
		defense_ended.emit(ended_day)


func _apply_background_core_pressure() -> void:
	if _is_meadow_edge_loaded():
		return
	var damage: int = _get_background_damage_per_tick()
	if damage <= 0:
		return
	background_core_damage += damage
	GameManager.apply_core_damage(damage)
	defense_progressed.emit(elapsed_time, background_core_damage)
	_maybe_emit_core_pressure_warning()


func _get_background_damage_per_tick() -> int:
	var day_bonus: int = int(floor(float(maxi(0, DayNightCycle.day_count - 1)) / 5.0)) * 2
	return BACKGROUND_DAMAGE_PER_TICK + day_bonus


func _maybe_emit_core_pressure_warning() -> void:
	var ratio: float = GameManager.get_core_hp_ratio()
	if ratio <= CRITICAL_CORE_HP_RATIO and not _warned_critical_core:
		_warned_critical_core = true
		notification_requested.emit(
				"Core critical",
				"The Dianthus Core is close to collapsing. Return now.",
				"danger",
				"night_defense:critical:%d" % night_day)
	elif ratio <= LOW_CORE_HP_RATIO and not _warned_low_core:
		_warned_low_core = true
		notification_requested.emit(
				"Core under heavy attack",
				"The Dianthus Core is taking damage while you are away.",
				"danger",
				"night_defense:low:%d" % night_day)


func _is_meadow_edge_loaded() -> bool:
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path == MEADOW_EDGE_SCENE
