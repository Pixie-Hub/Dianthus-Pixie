extends PanelContainer

signal dismissed(notification: Control)

const TYPE_STYLES: Dictionary = {
	"item": {
		"accent": Color(0.8, 0.92, 0.48, 1.0),
		"symbol": "+",
	},
	"codex_plant": {
		"accent": Color(0.35, 0.78, 0.34, 1.0),
		"symbol": "*",
	},
	"codex_enemy": {
		"accent": Color(0.78, 0.28, 0.36, 1.0),
		"symbol": "!",
	},
	"quest_complete": {
		"accent": Color(1.0, 0.78, 0.25, 1.0),
		"symbol": "Q",
	},
	"quest_update": {
		"accent": Color(0.55, 0.78, 1.0, 1.0),
		"symbol": ">",
	},
	"unlock": {
		"accent": Color(0.9, 0.65, 1.0, 1.0),
		"symbol": "*",
	},
}

@onready var _accent_bar: ColorRect = %AccentBar
@onready var _icon_texture: TextureRect = %IconTexture
@onready var _icon_label: Label = %IconLabel
@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _life_timer: Timer = %LifeTimer

var _dismiss_tween: Tween = null
var _pulse_tween: Tween = null
var _dismissing: bool = false
var notification_key: String = ""


func _ready() -> void:
	_life_timer.timeout.connect(dismiss)
	pivot_offset = size * 0.5


func configure(title: String, message: String, notification_type: String, icon: Texture2D = null) -> void:
	var style: Dictionary = TYPE_STYLES.get(notification_type, TYPE_STYLES["unlock"])
	var accent: Color = style.get("accent", Color(1.0, 0.8, 0.25, 1.0))
	_title_label.text = title
	_message_label.text = message
	_accent_bar.color = accent
	_icon_label.text = str(style.get("symbol", "*"))
	_icon_label.add_theme_color_override("font_color", accent)
	if icon != null:
		_icon_texture.texture = icon
		_icon_texture.visible = true
		_icon_label.visible = false
	else:
		_icon_texture.visible = false
		_icon_label.visible = true
	var panel_style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.border_color = accent
	add_theme_stylebox_override("panel", panel_style)


func begin(duration: float) -> void:
	_dismissing = false
	modulate.a = 0.0
	position.x += 18.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(self, "position:x", position.x - 18.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_life_timer.start(duration)


func refresh(title: String, message: String, notification_type: String, icon: Texture2D, duration: float) -> void:
	configure(title, message, notification_type, icon)
	_life_timer.start(duration)
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.08)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func dismiss() -> void:
	if _dismissing:
		return
	_dismissing = true
	_life_timer.stop()
	if is_instance_valid(_dismiss_tween):
		_dismiss_tween.kill()
	_dismiss_tween = create_tween()
	_dismiss_tween.set_parallel(true)
	_dismiss_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_dismiss_tween.tween_property(self, "position:x", position.x + 12.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await _dismiss_tween.finished
	dismissed.emit(self)
	queue_free()
