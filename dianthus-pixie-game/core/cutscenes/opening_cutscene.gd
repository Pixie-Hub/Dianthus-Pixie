extends Control

const MEADOW_SCENE := "res://world/zones/meadow_edge/meadow_edge.tscn"
const DIALOGIC_TIMELINE: StringName = &"opening_cutscene"

const NARRATION_FADE_IN := 0.8
const NARRATION_HOLD := 2.5
const NARRATION_FADE_OUT := 0.7
const PETAL_COUNT := 14

enum Beat {
	BLACK_HOLD,
	NARRATION_1,
	NARRATION_2,
	NARRATION_3,
	CORE_VISUAL,
	DIALOGIC,
	FINAL_NARRATION,
	TRANSITION,
}

var _current_beat: int = Beat.BLACK_HOLD
var _beat_tween: Tween = null
var _pulse_tween: Tween = null
var _done: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _petal_container: Control = %PetalContainer
@onready var _pink_pulse: ColorRect = %PinkPulse
@onready var _shadow_left: ColorRect = %ShadowLeft
@onready var _shadow_right: ColorRect = %ShadowRight
@onready var _narration_label: Label = %NarrationLabel
@onready var _skip_hint: Label = %SkipHint


func _ready() -> void:
	_narration_label.modulate.a = 0.0
	_pink_pulse.modulate.a = 0.0
	_shadow_left.modulate.a = 0.0
	_shadow_right.modulate.a = 0.0
	_rng.randomize()
	_spawn_petals()
	_play_beat(Beat.BLACK_HOLD)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE:
			_handle_skip()
			get_viewport().set_input_as_handled()


func _handle_skip() -> void:
	if _current_beat < Beat.DIALOGIC:
		if _beat_tween and _beat_tween.is_valid():
			_beat_tween.kill()
			_beat_tween = null
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
			_pulse_tween = null
		_narration_label.modulate.a = 0.0
		_pink_pulse.modulate.a = 0.0
		_shadow_left.modulate.a = 0.0
		_shadow_right.modulate.a = 0.0
		_play_beat(Beat.DIALOGIC)
	elif _current_beat == Beat.DIALOGIC:
		Dialogic.end_timeline()
	elif _current_beat == Beat.FINAL_NARRATION:
		if _beat_tween and _beat_tween.is_valid():
			_beat_tween.kill()
			_beat_tween = null
		_narration_label.modulate.a = 0.0
		_play_beat(Beat.TRANSITION)


func _play_beat(beat: int) -> void:
	_current_beat = beat
	match beat:
		Beat.BLACK_HOLD:
			_beat_tween = create_tween()
			_beat_tween.tween_interval(1.5)
			_beat_tween.tween_callback(_play_beat.bind(Beat.NARRATION_1))

		Beat.NARRATION_1:
			_show_narration(
				"A storm without rain. It carries ash, seeds, and the last breath of a dying light.",
				Beat.NARRATION_2
			)

		Beat.NARRATION_2:
			_show_narration(
				"Below — a forgotten garden. Fences split open. Soil choked with bramble and silence.",
				Beat.NARRATION_3
			)

		Beat.NARRATION_3:
			_start_pulse()
			_show_narration(
				"At its center, a faint glow. A flower-heart, pulsing like a lantern that has forgotten how to rest.",
				Beat.CORE_VISUAL
			)

		Beat.CORE_VISUAL:
			_play_core_visual()

		Beat.DIALOGIC:
			_start_dialogic()

		Beat.FINAL_NARRATION:
			_show_final_narration()

		Beat.TRANSITION:
			_do_transition()


func _show_narration(text: String, next_beat: int) -> void:
	_narration_label.text = text
	_beat_tween = create_tween()
	_beat_tween.tween_property(_narration_label, "modulate:a", 1.0, NARRATION_FADE_IN)
	_beat_tween.tween_interval(NARRATION_HOLD)
	_beat_tween.tween_property(_narration_label, "modulate:a", 0.0, NARRATION_FADE_OUT)
	_beat_tween.tween_callback(_play_beat.bind(next_beat))


func _start_pulse() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_pink_pulse, "modulate:a", 0.3, 0.9)
	_pulse_tween.tween_property(_pink_pulse, "modulate:a", 0.07, 0.9)


func _play_core_visual() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	_narration_label.modulate.a = 0.0
	_beat_tween = create_tween()
	_beat_tween.tween_property(_pink_pulse, "modulate:a", 0.75, 0.4)
	_beat_tween.tween_interval(0.35)
	_beat_tween.tween_property(_shadow_left, "modulate:a", 0.7, 0.35)
	_beat_tween.parallel().tween_property(_shadow_right, "modulate:a", 0.7, 0.35)
	_beat_tween.tween_interval(0.55)
	_beat_tween.tween_property(_shadow_left, "modulate:a", 0.0, 0.45)
	_beat_tween.parallel().tween_property(_shadow_right, "modulate:a", 0.0, 0.45)
	_beat_tween.parallel().tween_property(_pink_pulse, "modulate:a", 0.0, 0.65)
	_beat_tween.tween_callback(_play_beat.bind(Beat.DIALOGIC))


func _start_dialogic() -> void:
	_narration_label.modulate.a = 0.0
	_pink_pulse.modulate.a = 0.0
	_skip_hint.text = "Press Esc to skip"
	MusicManager.stop_music(true)
	Dialogic.timeline_ended.connect(_on_dialogic_ended, CONNECT_ONE_SHOT)
	Dialogic.start(DIALOGIC_TIMELINE)


func _on_dialogic_ended() -> void:
	_play_beat(Beat.FINAL_NARRATION)


func _show_final_narration() -> void:
	_narration_label.text = "The light holds. Not because it is strong — because something small chose to stay beside it."
	_beat_tween = create_tween()
	_beat_tween.tween_property(_narration_label, "modulate:a", 1.0, 1.0)
	_beat_tween.tween_interval(2.5)
	_beat_tween.tween_property(_narration_label, "modulate:a", 0.0, 1.2)
	_beat_tween.tween_callback(_play_beat.bind(Beat.TRANSITION))


func _do_transition() -> void:
	_done = true
	_skip_hint.modulate.a = 0.0
	_beat_tween = create_tween()
	_beat_tween.tween_interval(0.3)
	_beat_tween.tween_callback(func() -> void:
		SceneTransition.transition_to(MEADOW_SCENE)
	)


func _spawn_petals() -> void:
	for _i: int in PETAL_COUNT:
		var petal := ColorRect.new()
		var w: float = _rng.randf_range(2.0, 5.0)
		var h: float = _rng.randf_range(2.0, 5.0)
		petal.size = Vector2(w, h)
		petal.color = Color(0.98, 0.72, 0.82, _rng.randf_range(0.1, 0.4))
		petal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_petal_container.add_child(petal)
		_do_petal_loop(petal)


func _do_petal_loop(petal: ColorRect) -> void:
	if not is_instance_valid(petal):
		return
	var start_x: float = _rng.randf_range(-8.0, 648.0)
	var start_y: float = _rng.randf_range(-8.0, 4.0)
	petal.position = Vector2(start_x, start_y)
	var drift_x: float = _rng.randf_range(16.0, 48.0)
	var drift_y: float = _rng.randf_range(40.0, 90.0)
	var duration: float = _rng.randf_range(6.0, 14.0)
	var t: Tween = create_tween()
	t.tween_property(petal, "position", Vector2(start_x + drift_x, start_y + drift_y), duration)
	t.tween_callback(func() -> void:
		if is_instance_valid(petal):
			_do_petal_loop(petal)
	)
