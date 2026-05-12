extends PanelContainer
class_name CraftingAssemblyComponentSlot

enum SlotRole { COMPONENT, TARGET }

const ROLE_COMPONENT: int = SlotRole.COMPONENT
const ROLE_TARGET: int = SlotRole.TARGET
const PANEL_NORMAL: Color = Color(0.18, 0.12, 0.07, 1.0)
const PANEL_FOCUSED: Color = Color(0.24, 0.17, 0.08, 1.0)
const BORDER_NORMAL: Color = Color(0.72, 0.55, 0.22, 1.0)
const BORDER_FILLED: Color = Color(0.30, 0.75, 0.32, 1.0)
const BORDER_WRONG: Color = Color(0.90, 0.18, 0.16, 1.0)
const BORDER_DISABLED: Color = Color(0.35, 0.30, 0.25, 1.0)

@onready var _swatch: ColorRect = %Swatch
@onready var _icon: TextureRect = %Icon
@onready var _label: Label = %Label

const FALLBACK_ICON_COLOR: Color = Color(0.45, 0.38, 0.28, 1.0)

var material_id: String = ""
var role: int = ROLE_COMPONENT
var filled: bool = false
var locked: bool = false
var is_decoy: bool = false
var focused_by_gamepad: bool = false
var _component_color: Color = Color.WHITE
var _wrong_flash: bool = false


func configure(slot_role: int, item_id: String, component_label: String, component_color: Color, decoy: bool = false) -> void:
	role = slot_role
	material_id = item_id
	is_decoy = decoy
	_component_color = component_color
	_ensure_refs()
	_label.text = component_label
	_swatch.color = Color(component_color.r, component_color.g, component_color.b, 0.30)
	_load_icon(item_id, decoy)
	_apply_slot_visibility()
	filled = false
	locked = false
	_wrong_flash = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_visual()


func mark_filled() -> void:
	filled = true
	locked = true
	_apply_slot_visibility()
	_refresh_visual()


func mark_removed() -> void:
	filled = false
	locked = true
	_apply_slot_visibility()
	_refresh_visual()


func set_focus_state(focused: bool) -> void:
	focused_by_gamepad = focused
	_refresh_visual()


func flash_wrong() -> void:
	_wrong_flash = true
	_refresh_visual()
	await get_tree().create_timer(0.18).timeout
	_wrong_flash = false
	if is_instance_valid(self):
		_refresh_visual()


func _ensure_refs() -> void:
	if _swatch == null:
		_swatch = get_node("MarginContainer/VBoxContainer/Swatch") as ColorRect
	if _icon == null:
		_icon = get_node("MarginContainer/VBoxContainer/Icon") as TextureRect
	if _label == null:
		_label = get_node("MarginContainer/VBoxContainer/Label") as Label


func _load_icon(item_id: String, decoy: bool) -> void:
	if _icon == null:
		return
	if decoy or item_id.is_empty() or item_id == "__decoy__":
		_icon.texture = null
		_icon.modulate = Color.WHITE
		return
	var icon_path: String = ItemDatabase.get_icon_path(item_id)
	if icon_path.is_empty():
		push_warning("[ComponentSlot] No icon path for item '%s' — showing fallback." % item_id)
		_icon.texture = null
		_icon.modulate = FALLBACK_ICON_COLOR
		return
	var tex: Texture2D = load(icon_path) as Texture2D
	if tex == null:
		push_warning("[ComponentSlot] Failed to load icon texture '%s' for item '%s'." % [icon_path, item_id])
		_icon.texture = null
		_icon.modulate = FALLBACK_ICON_COLOR
		return
	_icon.texture = tex
	_icon.modulate = Color.WHITE


func _apply_slot_visibility() -> void:
	_ensure_refs()
	if role == ROLE_COMPONENT:
		_icon.visible = not locked or not filled
		_swatch.visible = false
	else:
		_swatch.visible = true
		_icon.visible = filled


func _refresh_visual() -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = PANEL_FOCUSED if focused_by_gamepad else PANEL_NORMAL
	style.border_width_left = 2 if focused_by_gamepad else 1
	style.border_width_top = 2 if focused_by_gamepad else 1
	style.border_width_right = 2 if focused_by_gamepad else 1
	style.border_width_bottom = 2 if focused_by_gamepad else 1
	if _wrong_flash:
		style.border_color = BORDER_WRONG
	elif locked and role == ROLE_COMPONENT:
		style.border_color = BORDER_DISABLED
	elif filled:
		style.border_color = BORDER_FILLED
	else:
		style.border_color = BORDER_NORMAL
	add_theme_stylebox_override("panel", style)
	modulate = Color(0.75, 0.75, 0.75, 1.0) if locked and role == ROLE_COMPONENT else Color.WHITE
