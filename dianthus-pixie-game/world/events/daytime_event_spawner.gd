class_name DaytimeEventSpawner
extends Node2D

signal active_event_position_changed(world_pos: Vector2)
signal active_event_cleared()

const CORRUPTED_ROOT_SCENE: PackedScene = preload("res://world/events/corrupted_root_event.tscn")
const WILD_SEEDLING_SCENE: PackedScene = preload("res://world/events/wild_seedling_event.tscn")
const VOID_FISSURE_SCENE: PackedScene = preload("res://world/events/void_fissure_event.tscn")
const DIANTHUS_RESONANCE_SCENE: PackedScene = preload("res://world/events/dianthus_resonance_event.tscn")

const EVENT_CANDIDATES: Array[StringName] = [
	&"corrupted_root",
	&"wild_seedling",
	&"void_fissure",
	&"dianthus_resonance",
]

const EVENT_POSITIONS: Dictionary = {
	&"corrupted_root": [
		Vector2(480, 820),
		Vector2(680, 760),
		Vector2(1100, 650),
	],
	&"wild_seedling": [
		Vector2(300, 520),
		Vector2(1360, 490),
		Vector2(740, 260),
	],
	&"void_fissure": [
		Vector2(700, 220),
		Vector2(1310, 510),
	],
	&"dianthus_resonance": [
		Vector2(380, 760),
		Vector2(460, 800),
		Vector2(360, 820),
	],
}

const DESPAWN_TIME_REMAINING: float = 30.0

var _active_event: DaytimeEvent = null
var _last_event_id: StringName = &""
var _completed_day: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	if DayNightCycle.get_phase_name() == "DAY":
		_spawn_event()


func _on_phase_changed(phase: String) -> void:
	if phase == "DAY":
		_spawn_event()
	elif phase == "NIGHT":
		_despawn_active()


func _process(_delta: float) -> void:
	if DayNightCycle.is_night():
		return
	if not is_instance_valid(_active_event):
		return
	var remaining: float = DayNightCycle.get_time_remaining()
	if remaining <= DESPAWN_TIME_REMAINING and remaining > 0.0:
		_despawn_active()


func serialize() -> Dictionary:
	var active_id: String = ""
	var active_pos_x: float = 0.0
	var active_pos_y: float = 0.0
	if is_instance_valid(_active_event) and not _active_event._is_complete:
		active_id = str(_active_event.event_id)
		active_pos_x = _active_event.global_position.x
		active_pos_y = _active_event.global_position.y
	return {
		"last_event_id": str(_last_event_id),
		"completed_day": _completed_day,
		"active_event_id": active_id,
		"active_event_pos_x": active_pos_x,
		"active_event_pos_y": active_pos_y,
	}


func deserialize(data: Dictionary) -> void:
	_last_event_id = StringName(str(data.get("last_event_id", "")))
	_completed_day = int(data.get("completed_day", -1))
	var saved_active_id: StringName = StringName(str(data.get("active_event_id", "")))
	if _completed_day == DayNightCycle.day_count:
		_despawn_active()
		return
	if saved_active_id != &"" and DayNightCycle.get_phase_name() == "DAY":
		_despawn_active()
		var scene: PackedScene = _get_scene(saved_active_id)
		if scene != null:
			var event: DaytimeEvent = scene.instantiate() as DaytimeEvent
			if event != null:
				var pos_x: float = float(data.get("active_event_pos_x", 0.0))
				var pos_y: float = float(data.get("active_event_pos_y", 0.0))
				event.global_position = Vector2(pos_x, pos_y)
				event.event_completed.connect(_on_event_completed)
				event.event_despawned.connect(_on_event_despawned)
				if event.has_signal("spawn_sealed"):
					event.spawn_sealed.connect(_on_spawn_sealed)
				add_child(event)
				event.activate()
				_active_event = event
				active_event_position_changed.emit(event.global_position)
				print("[DaytimeEventSpawner] Restored saved event: %s at %s" % [saved_active_id, event.global_position])


func _spawn_event() -> void:
	if DayNightCycle.day_count < 1:
		return
	if _completed_day == DayNightCycle.day_count:
		return
	_despawn_active()
	_rng.seed = 94321 + DayNightCycle.day_count * 31337

	var pool: Array[StringName] = []
	for ev_id: StringName in EVENT_CANDIDATES:
		if ev_id != _last_event_id:
			pool.append(ev_id)
	if pool.is_empty():
		pool = EVENT_CANDIDATES.duplicate()

	var chosen_id: StringName = pool[_rng.randi() % pool.size()]
	_last_event_id = chosen_id

	var positions: Array = EVENT_POSITIONS.get(chosen_id, [])
	if positions.is_empty():
		return
	var chosen_pos: Vector2 = positions[_rng.randi() % positions.size()]

	var scene: PackedScene = _get_scene(chosen_id)
	if scene == null:
		return

	var event: DaytimeEvent = scene.instantiate() as DaytimeEvent
	if event == null:
		return

	event.global_position = chosen_pos
	event.event_completed.connect(_on_event_completed)
	event.event_despawned.connect(_on_event_despawned)
	if event.has_signal("spawn_sealed"):
		event.spawn_sealed.connect(_on_spawn_sealed)

	add_child(event)
	event.activate()
	_active_event = event
	active_event_position_changed.emit(chosen_pos)
	print("[DaytimeEventSpawner] Day %d event: %s at %s" % [DayNightCycle.day_count, chosen_id, chosen_pos])


func _despawn_active() -> void:
	if is_instance_valid(_active_event):
		_active_event.deactivate()
		_active_event = null
	active_event_cleared.emit()


func _get_scene(event_id: StringName) -> PackedScene:
	match event_id:
		&"corrupted_root":    return CORRUPTED_ROOT_SCENE
		&"wild_seedling":     return WILD_SEEDLING_SCENE
		&"void_fissure":      return VOID_FISSURE_SCENE
		&"dianthus_resonance": return DIANTHUS_RESONANCE_SCENE
	return null


func _on_event_completed(_id: StringName) -> void:
	_completed_day = DayNightCycle.day_count
	_active_event = null
	active_event_cleared.emit()


func _on_event_despawned(_id: StringName) -> void:
	_active_event = null
	active_event_cleared.emit()


func _on_spawn_sealed(direction_position: Vector2) -> void:
	var spawner: Node = get_tree().current_scene.find_child("WaveSpawner", true, false)
	if spawner != null and spawner.has_method("seal_spawn_point_near"):
		spawner.seal_spawn_point_near(direction_position)
	print("[DaytimeEventSpawner] Spawn point sealed near %s" % direction_position)


func get_active_event_position() -> Vector2:
	if is_instance_valid(_active_event):
		return _active_event.global_position
	return Vector2(-9999, -9999)


func has_active_event() -> bool:
	return is_instance_valid(_active_event) and not _active_event._is_complete


func force_spawn_event(event_id: StringName) -> void:
	_last_event_id = &""
	var positions: Array = EVENT_POSITIONS.get(event_id, [])
	if positions.is_empty():
		push_warning("[DaytimeEventSpawner] No positions for: %s" % event_id)
		return
	_despawn_active()
	var scene: PackedScene = _get_scene(event_id)
	if scene == null:
		return
	var event: DaytimeEvent = scene.instantiate() as DaytimeEvent
	if event == null:
		return
	event.global_position = positions[0]
	event.event_completed.connect(_on_event_completed)
	event.event_despawned.connect(_on_event_despawned)
	if event.has_signal("spawn_sealed"):
		event.spawn_sealed.connect(_on_spawn_sealed)
	add_child(event)
	event.activate()
	_active_event = event
	active_event_position_changed.emit(event.global_position)
	print("[DaytimeEventSpawner] Force-spawned: %s" % event_id)
