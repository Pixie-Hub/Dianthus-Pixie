class_name DevourerOmenDecipherCutscene
extends CanvasLayer

signal finished

const NARRATION_LINES: PackedStringArray = [
	"The glyphs answer your touch.",
	"Beneath Veld, something vast leans against the stone.",
	"Not a herald. Not a warning.",
	"A door.",
]
const FADE_IN_SECONDS: float = 0.45
const HOLD_SECONDS: float = 1.05
const FADE_OUT_SECONDS: float = 0.35

var _done: bool = false
var _pause_requested: bool = false
var _sequence_tween: Tween = null
var _pulse_tween: Tween = null

@onready var _backdrop: ColorRect = %Backdrop
@onready var _vignette: TextureRect = %Vignette
@onready var _omen_echo: TextureRect = %OmenEcho
@onready var _void_pulse: TextureRect = %VoidPulse
@onready var _glyph_flash: ColorRect = %GlyphFlash
@onready var _narration_label: Label = %NarrationLabel
@onready var _skip_hint: Label = %SkipHint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_prepare_initial_state()
	PauseManager.request_pause(self)
	_pause_requested = true
	_start_pulse()
	_play_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var key_event := event as InputEventKey
	var pressed_skip_key: bool = key_event != null \
		and key_event.pressed \
		and not key_event.echo \
		and (key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_SPACE)
	if pressed_skip_key or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_finish()
		get_viewport().set_input_as_handled()


func cancel() -> void:
	_cleanup_tweens()
	_release_pause()
	if is_inside_tree():
		queue_free()


func _exit_tree() -> void:
	_cleanup_tweens()
	_release_pause()


func _prepare_initial_state() -> void:
	_backdrop.modulate.a = 0.0
	_vignette.modulate.a = 0.0
	_omen_echo.modulate.a = 0.0
	_omen_echo.scale = Vector2(0.86, 0.86)
	_void_pulse.modulate.a = 0.0
	_void_pulse.scale = Vector2(0.8, 0.8)
	_glyph_flash.modulate.a = 0.0
	_narration_label.modulate.a = 0.0
	_skip_hint.modulate.a = 0.0


func _start_pulse() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pulse_tween.tween_property(_void_pulse, "modulate:a", 0.74, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_void_pulse, "scale", Vector2(1.08, 1.08), 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_omen_echo, "scale", Vector2(0.91, 0.91), 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_void_pulse, "modulate:a", 0.36, 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_void_pulse, "scale", Vector2(0.9, 0.9), 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_omen_echo, "scale", Vector2(0.86, 0.86), 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _play_sequence() -> void:
	_sequence_tween = create_tween()
	_sequence_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_sequence_tween.tween_property(_backdrop, "modulate:a", 0.55, 0.45)
	_sequence_tween.parallel().tween_property(_vignette, "modulate:a", 0.92, 0.45)
	_sequence_tween.parallel().tween_property(_omen_echo, "modulate:a", 1.0, 0.65)
	_sequence_tween.parallel().tween_property(_void_pulse, "modulate:a", 0.42, 0.65)
	_sequence_tween.parallel().tween_property(_skip_hint, "modulate:a", 0.68, 0.45)
	_sequence_tween.tween_callback(_flash_glyph.bind(0.38))
	for line: String in NARRATION_LINES:
		_sequence_tween.tween_callback(_show_line.bind(line))
		_sequence_tween.tween_property(_narration_label, "modulate:a", 1.0, FADE_IN_SECONDS)
		_sequence_tween.tween_interval(HOLD_SECONDS)
		_sequence_tween.tween_property(_narration_label, "modulate:a", 0.0, FADE_OUT_SECONDS)
	_sequence_tween.tween_callback(_flash_glyph.bind(0.82))
	_sequence_tween.tween_interval(0.3)
	_sequence_tween.tween_callback(_finish)


func _show_line(text: String) -> void:
	_narration_label.text = text


func _flash_glyph(alpha: float) -> void:
	var flash_tween: Tween = create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(_glyph_flash, "modulate:a", alpha, 0.12)
	flash_tween.tween_property(_glyph_flash, "modulate:a", 0.0, 0.42)


func _finish() -> void:
	if _done:
		return
	_done = true
	_cleanup_tweens()
	_release_pause()
	finished.emit()
	queue_free()


func _cleanup_tweens() -> void:
	if _sequence_tween and _sequence_tween.is_valid():
		_sequence_tween.kill()
	_sequence_tween = null
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null


func _release_pause() -> void:
	if not _pause_requested:
		return
	PauseManager.release_pause(self)
	_pause_requested = false
