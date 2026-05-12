extends PanelContainer

const CATEGORY_STYLES: Dictionary = {
	"offense": {
		"accent": Color(1.0, 0.48, 0.28, 1.0),
		"symbol": "ATK",
	},
	"defense": {
		"accent": Color(0.55, 0.78, 1.0, 1.0),
		"symbol": "DEF",
	},
	"regeneration": {
		"accent": Color(0.42, 0.88, 0.46, 1.0),
		"symbol": "REG",
	},
	"mobility": {
		"accent": Color(0.9, 0.75, 1.0, 1.0),
		"symbol": "SPD",
	},
	"utility": {
		"accent": Color(1.0, 0.8, 0.25, 1.0),
		"symbol": "FX",
	},
}

@onready var _accent_bar: ColorRect = %AccentBar
@onready var _icon_texture: TextureRect = %IconTexture
@onready var _icon_label: Label = %IconLabel
@onready var _stack_label: Label = %StackLabel
@onready var _duration_label: Label = %DurationLabel

var _effect: Dictionary = {}


func configure(effect: Dictionary) -> void:
	_effect = effect.duplicate(true)
	_refresh()


func update_effect(effect: Dictionary) -> void:
	_effect = effect.duplicate(true)
	_refresh()


func tick_display(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var category: String = str(_effect.get("category", "utility"))
	var style: Dictionary = CATEGORY_STYLES.get(category, CATEGORY_STYLES["utility"])
	var accent: Color = style.get("accent", Color(1.0, 0.8, 0.25, 1.0))
	var remaining: float = float(_effect.get("remaining_time", -1.0))
	if remaining >= 0.0 and remaining < 3.0:
		accent = Color(1.0, 0.35, 0.2, 1.0)

	_accent_bar.color = accent
	_icon_label.text = str(style.get("symbol", "FX"))
	_icon_label.add_theme_color_override("font_color", accent)
	tooltip_text = _build_tooltip_text()
	var stack_count: int = int(_effect.get("stack_count", 1))
	_stack_label.visible = stack_count > 1
	_stack_label.text = str(stack_count)
	_duration_label.visible = remaining >= 0.0
	_duration_label.text = "%d" % int(ceil(remaining)) if remaining >= 0.0 else ""

	var icon_path: String = str(_effect.get("icon", ""))
	if not icon_path.is_empty():
		var icon: Texture2D = load(icon_path) as Texture2D
		_icon_texture.texture = icon
		_icon_texture.visible = icon != null
		_icon_label.visible = icon == null
	else:
		_icon_texture.visible = false
		_icon_label.visible = true

	var panel_style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.border_color = accent
	add_theme_stylebox_override("panel", panel_style)


func _build_detail_text() -> String:
	var parts: Array[String] = []
	parts.append(str(_effect.get("description", "")))
	parts.append(str(_effect.get("strength_text", "")))
	return " - ".join(parts)


func _build_tooltip_text() -> String:
	var lines: Array[String] = [str(_effect.get("display_name", "Status"))]
	var description: String = str(_effect.get("description", ""))
	var strength: String = str(_effect.get("strength_text", ""))
	if not description.is_empty() or not strength.is_empty():
		var detail_line: String = "%s %s" % [description, strength]
		lines.append(detail_line.strip_edges())
	var category: String = str(_effect.get("category", "utility")).capitalize()
	if not category.is_empty():
		lines.append("Category: %s" % category)
	var stack_count: int = int(_effect.get("stack_count", 1))
	if stack_count > 1:
		lines.append("Stacks: %d" % stack_count)
	var remaining: float = float(_effect.get("remaining_time", -1.0))
	if remaining >= 0.0:
		lines.append("%ds remaining" % int(ceil(remaining)))
	else:
		lines.append("Duration: Passive")
	return "\n".join(lines)
