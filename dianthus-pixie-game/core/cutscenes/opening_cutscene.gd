extends Control

const MEADOW_SCENE := "res://world/zones/meadow_edge/meadow_edge.tscn"
const DIALOGIC_TIMELINE: StringName = &"opening_cutscene"

const NARRATION_FADE_IN := 0.8
const NARRATION_HOLD := 2.5
const NARRATION_FADE_OUT := 0.7
const PETAL_COUNT := 14
const POLLEN_MOTE_COUNT := 24
const ENERGY_PETAL_COUNT := 8

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
var _core_breathe_tween: Tween = null
var _core_emphasis_tween: Tween = null
var _done: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pollen_motes: Array[ColorRect] = []
var _energy_petals: Array[ColorRect] = []

@onready var _petal_container: Control = %PetalContainer
@onready var _core_reveal: Control = %CoreReveal
@onready var _ground_glow: TextureRect = %GroundGlow
@onready var _outer_halo: TextureRect = %OuterHalo
@onready var _inner_halo: TextureRect = %InnerHalo
@onready var _core_sprite: TextureRect = %CoreSprite
@onready var _life_spark: ColorRect = %LifeSpark
@onready var _pollen_container: Control = %PollenContainer
@onready var _dark_vignette: TextureRect = %DarkVignette
@onready var _pink_pulse: ColorRect = %PinkPulse
@onready var _shadow_left: ColorRect = %ShadowLeft
@onready var _shadow_right: ColorRect = %ShadowRight
@onready var _narration_label: Label = %NarrationLabel
@onready var _skip_hint: Label = %SkipHint


func _ready() -> void:
	_narration_label.modulate.a = 0.0
	_pink_pulse.modulate.a = 0.0
	_core_reveal.modulate.a = 0.0
	_dark_vignette.modulate.a = 0.65
	_shadow_left.modulate.a = 0.0
	_shadow_right.modulate.a = 0.0
	_rng.randomize()
	_prepare_core_reveal_nodes()
	_spawn_petals()
	_spawn_pollen_motes()
	_spawn_energy_petals()
	_start_core_breathing()
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
		if _core_emphasis_tween and _core_emphasis_tween.is_valid():
			_core_emphasis_tween.kill()
			_core_emphasis_tween = null
		_narration_label.modulate.a = 0.0
		_pink_pulse.modulate.a = 0.0
		_prepare_dialogic_visual_state()
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
	_pulse_tween.tween_property(_pink_pulse, "modulate:a", 0.16, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_core_reveal, "modulate:a", 0.18, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_pink_pulse, "modulate:a", 0.04, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_core_reveal, "modulate:a", 0.08, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _play_core_visual() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	_narration_label.modulate.a = 0.0
	_core_reveal.scale = Vector2(0.9, 0.9)
	_beat_tween = create_tween()
	_beat_tween.tween_property(_dark_vignette, "modulate:a", 1.0, 0.45)
	_beat_tween.parallel().tween_property(_shadow_left, "modulate:a", 0.82, 0.45)
	_beat_tween.parallel().tween_property(_shadow_right, "modulate:a", 0.82, 0.45)
	_beat_tween.parallel().tween_property(_pink_pulse, "modulate:a", 0.2, 0.45)
	_beat_tween.tween_property(_core_reveal, "modulate:a", 1.0, 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_beat_tween.parallel().tween_property(_core_reveal, "scale", Vector2.ONE, 0.95) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_beat_tween.parallel().tween_property(_ground_glow, "self_modulate:a", 0.92, 0.95)
	_beat_tween.tween_interval(0.45)
	_beat_tween.tween_callback(_pulse_core_emphasis)
	_beat_tween.tween_interval(1.05)
	_beat_tween.tween_property(_shadow_left, "modulate:a", 0.45, 0.55)
	_beat_tween.parallel().tween_property(_shadow_right, "modulate:a", 0.45, 0.55)
	_beat_tween.parallel().tween_property(_pink_pulse, "modulate:a", 0.0, 0.55)
	_beat_tween.parallel().tween_property(_core_reveal, "modulate:a", 0.9, 0.55)
	_beat_tween.tween_callback(_play_beat.bind(Beat.DIALOGIC))


func _start_dialogic() -> void:
	_narration_label.modulate.a = 0.0
	_pink_pulse.modulate.a = 0.0
	_prepare_dialogic_visual_state()
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


func _prepare_core_reveal_nodes() -> void:
	for node in [_core_reveal, _ground_glow, _outer_halo, _inner_halo, _core_sprite, _life_spark]:
		var control := node as Control
		control.pivot_offset = control.size * 0.5
	_ground_glow.self_modulate.a = 0.5
	_outer_halo.self_modulate.a = 0.62
	_inner_halo.self_modulate.a = 0.78
	_life_spark.modulate.a = 0.0


func _start_core_breathing() -> void:
	if _core_breathe_tween and _core_breathe_tween.is_valid():
		_core_breathe_tween.kill()
	_core_breathe_tween = create_tween().set_loops()
	_core_breathe_tween.tween_property(_outer_halo, "scale", Vector2(1.06, 1.06), 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_core_breathe_tween.parallel().tween_property(_outer_halo, "self_modulate:a", 0.82, 1.6)
	_core_breathe_tween.parallel().tween_property(_inner_halo, "scale", Vector2(0.96, 0.96), 1.6)
	_core_breathe_tween.parallel().tween_property(_core_sprite, "scale", Vector2(0.98, 1.04), 1.6)
	_core_breathe_tween.parallel().tween_property(_life_spark, "modulate:a", 0.9, 1.6)
	_core_breathe_tween.tween_property(_outer_halo, "scale", Vector2.ONE, 1.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_core_breathe_tween.parallel().tween_property(_outer_halo, "self_modulate:a", 0.48, 1.9)
	_core_breathe_tween.parallel().tween_property(_inner_halo, "scale", Vector2.ONE, 1.9)
	_core_breathe_tween.parallel().tween_property(_core_sprite, "scale", Vector2.ONE, 1.9)
	_core_breathe_tween.parallel().tween_property(_life_spark, "modulate:a", 0.32, 1.9)


func _pulse_core_emphasis() -> void:
	if _core_emphasis_tween and _core_emphasis_tween.is_valid():
		_core_emphasis_tween.kill()
	_core_emphasis_tween = create_tween()
	_core_emphasis_tween.tween_property(_inner_halo, "self_modulate:a", 1.0, 0.22)
	_core_emphasis_tween.parallel().tween_property(_outer_halo, "scale", Vector2(1.12, 1.12), 0.22)
	_core_emphasis_tween.parallel().tween_property(_ground_glow, "scale", Vector2(1.06, 1.02), 0.22)
	_core_emphasis_tween.tween_property(_inner_halo, "self_modulate:a", 0.72, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_core_emphasis_tween.parallel().tween_property(_outer_halo, "scale", Vector2.ONE, 0.55)
	_core_emphasis_tween.parallel().tween_property(_ground_glow, "scale", Vector2.ONE, 0.55)


func _prepare_dialogic_visual_state() -> void:
	_core_reveal.scale = Vector2.ONE
	_core_reveal.modulate.a = 0.9
	_dark_vignette.modulate.a = 1.0
	_shadow_left.modulate.a = 0.45
	_shadow_right.modulate.a = 0.45


func _spawn_pollen_motes() -> void:
	for _i: int in POLLEN_MOTE_COUNT:
		var mote := ColorRect.new()
		var size_px: float = _rng.randf_range(1.0, 2.0)
		mote.size = Vector2(size_px, size_px)
		mote.color = Color(1.0, _rng.randf_range(0.72, 0.9), _rng.randf_range(0.82, 1.0), _rng.randf_range(0.28, 0.74))
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pollen_container.add_child(mote)
		_pollen_motes.append(mote)
		_do_pollen_loop(mote)


func _do_pollen_loop(mote: ColorRect) -> void:
	if not is_instance_valid(mote):
		return
	var start_x: float = _rng.randf_range(122.0, 198.0)
	var start_y: float = _rng.randf_range(82.0, 146.0)
	mote.position = Vector2(start_x, start_y)
	var drift := Vector2(_rng.randf_range(-24.0, 24.0), _rng.randf_range(-54.0, -18.0))
	var duration: float = _rng.randf_range(2.6, 5.2)
	var t: Tween = create_tween()
	t.tween_property(mote, "position", mote.position + drift, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(mote, "modulate:a", _rng.randf_range(0.12, 0.34), duration)
	t.tween_callback(func() -> void:
		if is_instance_valid(mote):
			mote.modulate.a = 1.0
			_do_pollen_loop(mote)
	)


func _spawn_energy_petals() -> void:
	for _i: int in ENERGY_PETAL_COUNT:
		var petal := ColorRect.new()
		petal.size = Vector2(_rng.randf_range(3.0, 6.0), 2.0)
		petal.pivot_offset = petal.size * 0.5
		petal.color = Color(1.0, 0.55, 0.78, _rng.randf_range(0.22, 0.5))
		petal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pollen_container.add_child(petal)
		_energy_petals.append(petal)
		_do_energy_petal_loop(petal)


func _do_energy_petal_loop(petal: ColorRect) -> void:
	if not is_instance_valid(petal):
		return
	var angle: float = _rng.randf_range(0.0, TAU)
	var radius: float = _rng.randf_range(34.0, 58.0)
	var center := Vector2(160.0, 106.0)
	var next_angle: float = angle + _rng.randf_range(0.5, 0.9)
	var start := center + Vector2(cos(angle), sin(angle)) * radius
	var end := center + Vector2(cos(next_angle), sin(next_angle)) * _rng.randf_range(44.0, 72.0)
	petal.position = start
	petal.rotation = angle
	var duration: float = _rng.randf_range(3.4, 6.0)
	var t: Tween = create_tween()
	t.tween_property(petal, "position", end, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(petal, "rotation", petal.rotation + _rng.randf_range(0.8, 1.8), duration)
	t.parallel().tween_property(petal, "modulate:a", _rng.randf_range(0.08, 0.22), duration)
	t.tween_callback(func() -> void:
		if is_instance_valid(petal):
			petal.modulate.a = 1.0
			_do_energy_petal_loop(petal)
	)
