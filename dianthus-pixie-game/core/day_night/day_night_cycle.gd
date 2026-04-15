extends Node

signal phase_changed(phase: String)

enum Phase {
	MORNING,
	AFTERNOON,
	NIGHT,
}

const PHASE_DURATIONS: Dictionary = {
	Phase.MORNING: 120.0,
	Phase.AFTERNOON: 60.0,
	Phase.NIGHT: 90.0,
}

const PHASE_TINTS: Dictionary = {
	Phase.MORNING: Color(1.0, 0.95, 0.85),
	Phase.AFTERNOON: Color(0.9, 0.75, 0.50),
	Phase.NIGHT: Color(0.25, 0.20, 0.40),
}

const TINT_DURATION: float = 3.0

var current_phase: Phase = Phase.MORNING
var day_count: int = 1

var _phase_timer: float = 0.0
var _tween: Tween = null
var _canvas_modulate: CanvasModulate = null

func _ready() -> void:
	_phase_timer = PHASE_DURATIONS[current_phase]

func _process(delta: float) -> void:
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_advance_phase()

func _advance_phase() -> void:
	match current_phase:
		Phase.MORNING:
			current_phase = Phase.AFTERNOON
			GameManager.set_state(GameManager.GameState.PREPARATION)
		Phase.AFTERNOON:
			current_phase = Phase.NIGHT
			GameManager.set_state(GameManager.GameState.DEFENSE)
		Phase.NIGHT:
			current_phase = Phase.MORNING
			day_count += 1
			GameManager.set_state(GameManager.GameState.EXPLORATION)
	_phase_timer = PHASE_DURATIONS[current_phase]
	phase_changed.emit(get_phase_name())
	_apply_tint()

func register_canvas_modulate(node: CanvasModulate) -> void:
	_canvas_modulate = node
	if is_instance_valid(_canvas_modulate):
		_canvas_modulate.color = PHASE_TINTS[current_phase]

func _apply_tint() -> void:
	if not is_instance_valid(_canvas_modulate):
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_canvas_modulate, "color", PHASE_TINTS[current_phase], TINT_DURATION)

func get_phase_name() -> String:
	return Phase.keys()[current_phase]

func get_time_remaining() -> float:
	return _phase_timer

func get_phase_progress() -> float:
	return 1.0 - (_phase_timer / PHASE_DURATIONS[current_phase])

func is_night() -> bool:
	return current_phase == Phase.NIGHT
