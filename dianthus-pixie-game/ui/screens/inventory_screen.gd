extends CanvasLayer

const COLUMNS: int = 6
const SLOT_SIZE: int = 40
var RARITY_COLORS: Dictionary = {
	0: Color(0.25, 0.25, 0.25, 1.0),
	1: Color(0.15, 0.25, 0.50, 1.0),
	2: Color(0.45, 0.35, 0.05, 1.0),
}
const EMPTY_COLOR: Color = Color(0.12, 0.12, 0.12, 1.0)

@onready var _grid: GridContainer = %SlotGrid
@onready var _tooltip: Label = %Tooltip

var _slot_panels: Array[PanelContainer] = []
var _slot_labels: Array[Label] = []
var _slot_icons: Array[TextureRect] = []
var _icon_cache: Dictionary = {}


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_grid()
	InventoryManager.inventory_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _build_grid() -> void:
	_grid.columns = COLUMNS
	_slot_panels.clear()
	_slot_labels.clear()
	_slot_icons.clear()
	for i: int in range(InventoryManager.max_slots):
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.mouse_entered.connect(_on_slot_hover.bind(i))
		panel.mouse_exited.connect(_on_slot_exit)

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = EMPTY_COLOR
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.4, 0.4, 0.4, 1.0)
		panel.add_theme_stylebox_override("panel", style)

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.visible = false

		var count_label: Label = Label.new()
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_font_size_override("font_size", 8)
		count_label.anchors_preset = Control.PRESET_FULL_RECT
		count_label.visible = false

		panel.add_child(icon_rect)
		panel.add_child(count_label)
		_grid.add_child(panel)
		_slot_panels.append(panel)
		_slot_labels.append(count_label)
		_slot_icons.append(icon_rect)


func _get_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _icon_cache.has(path):
		_icon_cache[path] = load(path) as Texture2D
	return _icon_cache[path]


func _refresh() -> void:
	for i: int in range(_slot_panels.size()):
		var slot: Dictionary = InventoryManager.get_slot(i)
		var panel: PanelContainer = _slot_panels[i]
		var label: Label = _slot_labels[i]
		var icon_rect: TextureRect = _slot_icons[i]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat

		if slot.is_empty():
			style.bg_color = EMPTY_COLOR
			label.visible = false
			icon_rect.texture = null
			icon_rect.visible = false
		else:
			var item_id: String = str(slot.get("item_id", ""))
			var count: int = int(slot.get("count", 0))
			var rarity: int = ItemDatabase.get_rarity(item_id)
			style.bg_color = RARITY_COLORS.get(rarity, EMPTY_COLOR)
			label.text = str(count)
			label.visible = true
			var icon_path: String = ItemDatabase.get_icon_path(item_id)
			var tex: Texture2D = _get_icon(icon_path)
			icon_rect.texture = tex
			icon_rect.visible = tex != null


func _on_slot_hover(index: int) -> void:
	var slot: Dictionary = InventoryManager.get_slot(index)
	if slot.is_empty():
		_tooltip.visible = false
		return
	var item_id: String = str(slot.get("item_id", ""))
	var display: String = ItemDatabase.get_display_name(item_id)
	var desc: String = ItemDatabase.get_description(item_id)
	_tooltip.text = "%s\n%s" % [display, desc]
	_tooltip.visible = true


func _on_slot_exit() -> void:
	_tooltip.visible = false
