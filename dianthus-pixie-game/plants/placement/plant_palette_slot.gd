extends PanelContainer
class_name PlantPaletteSlot

signal slot_clicked(seed_id: String, quality: int)

@export var normal_style: StyleBoxFlat
@export var selected_style: StyleBoxFlat

@onready var _plant_icon: TextureRect = %PlantIcon
@onready var _quality_label: Label = %QualityLabel
@onready var _count_label: Label = %CountLabel

var _seed_id: String = ""
var _quality: int = 0


func bind_slot(seed_id: String, quality: int, count: int, texture: Texture2D, selected: bool) -> void:
	_seed_id = seed_id
	_quality = ItemDatabase.normalize_quality(quality)
	_plant_icon.texture = texture
	_quality_label.text = ItemDatabase.get_quality_marker(_quality)
	_quality_label.add_theme_color_override("font_color", ItemDatabase.get_quality_color(_quality))
	_count_label.text = "x%d" % count
	tooltip_text = "%s\n%s" % [
		ItemDatabase.get_display_name_with_quality(_seed_id, _quality),
		ItemDatabase.get_quality_description(_seed_id, _quality),
	]
	_apply_selected_state(selected)


func _apply_selected_state(selected: bool) -> void:
	var style: StyleBoxFlat = selected_style if selected else normal_style
	if style != null:
		add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(_seed_id, _quality)
		accept_event()
