extends Control

const SUN_TEXTURE: Texture2D = preload("res://ui/hud/sun.png")
const MOON_TEXTURE: Texture2D = preload("res://ui/hud/moon.png")

@onready var _icon: TextureRect = %ToDIcon
@onready var _track: ColorRect = %ToDTrack
@onready var _label: Label = %ToDLabel
@onready var _phase_label: Label = %ToDPhaseLabel

const NIGHT_WARNING_THRESHOLD: float = 0.75
const TRACK_NORMAL_COLOR: Color = Color(0.20, 0.40, 0.60, 0.7)
const TRACK_WARNING_COLOR: Color = Color(0.80, 0.20, 0.20, 0.9)
const TRACK_NIGHT_COLOR: Color = Color(0.15, 0.10, 0.30, 0.9)
const ICON_SUN_MODULATE: Color = Color(1.0, 0.85, 0.2, 1)
const ICON_MOON_MODULATE: Color = Color(0.6, 0.75, 1.0, 1)


func _ready() -> void:
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	GameManager.colorblind_mode_changed.connect(_on_colorblind_changed)
	_on_colorblind_changed(GameManager.colorblind_mode)
	_refresh_icon()


func _process(_delta: float) -> void:
	var progress: float = DayNightCycle.get_phase_progress()
	var is_night: bool = DayNightCycle.is_night()

	# Slide icon along track.
	var track_w: float = _track.size.x
	var icon_w: float = _icon.size.x
	_icon.position.x = lerp(0.0, max(0.0, track_w - icon_w), progress)

	# Warning / phase tint on track.
	if is_night:
		_track.color = TRACK_NIGHT_COLOR
	elif progress >= NIGHT_WARNING_THRESHOLD:
		_track.color = TRACK_WARNING_COLOR
	else:
		_track.color = TRACK_NORMAL_COLOR

	# Time label.
	var remaining: int = int(DayNightCycle.get_time_remaining())
	var mm: int = floori(remaining / 60.0)
	var ss: int = remaining % 60
	_label.text = "Day %d   %02d:%02d" % [DayNightCycle.day_count, mm, ss]


func _on_phase_changed(_phase: String) -> void:
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
