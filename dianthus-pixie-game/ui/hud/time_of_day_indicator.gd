extends Control

const SUN_TEXTURE: Texture2D = preload("res://ui/hud/sun.png")
const MOON_TEXTURE: Texture2D = preload("res://ui/hud/moon.png")

@onready var _icon: TextureRect = %ToDIcon
@onready var _track: ColorRect = %ToDTrack
@onready var _label: Label = %ToDLabel
@onready var _phase_label: Label = %ToDPhaseLabel

const NIGHT_WARNING_THRESHOLD: float = 0.75
const RETURN_PRESSURE_THRESHOLD: float = 30.0
const FLASH_THRESHOLD: float = 15.0
const TRACK_NORMAL_COLOR: Color = Color(0.20, 0.40, 0.60, 0.7)
const TRACK_WARNING_COLOR: Color = Color(0.80, 0.20, 0.20, 0.9)
const TRACK_NIGHT_COLOR: Color = Color(0.15, 0.10, 0.30, 0.9)
const TRACK_RETURN_PULSE_A: Color = Color(0.85, 0.40, 0.10, 0.95)
const TRACK_RETURN_PULSE_B: Color = Color(0.80, 0.20, 0.20, 0.9)
const ICON_SUN_MODULATE: Color = Color(1.0, 0.85, 0.2, 1)
const ICON_MOON_MODULATE: Color = Color(0.6, 0.75, 1.0, 1)

var _pulse_time: float = 0.0
var _return_warning_played: bool = false


func _ready() -> void:
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	GameManager.colorblind_mode_changed.connect(_on_colorblind_changed)
	_on_colorblind_changed(GameManager.colorblind_mode)
	_refresh_icon()


func _process(delta: float) -> void:
	_pulse_time += delta
	var progress: float = DayNightCycle.get_phase_progress()
	var is_night: bool = DayNightCycle.is_night()
	var remaining: float = DayNightCycle.get_time_remaining()

	# Slide icon along track.
	var track_w: float = _track.size.x
	var icon_w: float = _icon.size.x
	_icon.position.x = lerp(0.0, max(0.0, track_w - icon_w), progress)

	# Track colour — return pressure pulse overrides standard warning.
	if is_night:
		_track.color = TRACK_NIGHT_COLOR
	elif not is_night and remaining <= RETURN_PRESSURE_THRESHOLD:
		var pulse: float = 0.5 + 0.5 * sin(_pulse_time * TAU * 1.5)
		_track.color = TRACK_RETURN_PULSE_A.lerp(TRACK_RETURN_PULSE_B, pulse)
	elif progress >= NIGHT_WARNING_THRESHOLD:
		_track.color = TRACK_WARNING_COLOR
	else:
		_track.color = TRACK_NORMAL_COLOR

	# Time label text.
	var remaining_i: int = int(remaining)
	var mm: int = floori(remaining_i / 60.0)
	var ss: int = remaining_i % 60
	_label.text = "Day %d   %02d:%02d" % [DayNightCycle.day_count, mm, ss]

	# Label flash at ≤15s remaining (DAY only).
	if not is_night and remaining <= FLASH_THRESHOLD:
		var flash: float = 0.5 + 0.5 * sin(_pulse_time * TAU * 2.5)
		_label.modulate = Color(1.0, flash * 0.5 + 0.5, flash * 0.3 + 0.2, 1.0)
	else:
		_label.modulate = Color.WHITE

	# One-shot SFX at 30s remaining (DAY only).
	if not is_night and remaining <= RETURN_PRESSURE_THRESHOLD and not _return_warning_played:
		_return_warning_played = true
		SfxManager.play("night_transition")


func _on_phase_changed(_phase: String) -> void:
	_return_warning_played = false
	_label.modulate = Color.WHITE
	_refresh_icon()


func _refresh_icon() -> void:
	if DayNightCycle.is_night():
		_icon.texture = MOON_TEXTURE
		_icon.modulate = ICON_MOON_MODULATE
		_phase_label.text = "NIGHT"
	else:
		_icon.texture = SUN_TEXTURE
		_icon.modulate = ICON_SUN_MODULATE
		_phase_label.text = "DAY"


func _on_colorblind_changed(enabled: bool) -> void:
	_phase_label.visible = enabled
