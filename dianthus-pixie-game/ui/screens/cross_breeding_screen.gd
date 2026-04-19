extends CanvasLayer

const SLOT_EMPTY_COLOR: Color = Color(0.15, 0.15, 0.15, 1.0)
const SLOT_FILLED_COLOR: Color = Color(0.2, 0.3, 0.2, 1.0)

@onready var _slot_a_label: Label = %SlotALabel
@onready var _slot_b_label: Label = %SlotBLabel
@onready var _output_label: Label = %OutputLabel
@onready var _combo_list: VBoxContainer = %ComboList
@onready var _breed_button: Button = %BreedButton
@onready var _slot_a_panel: PanelContainer = %SlotA
@onready var _slot_b_panel: PanelContainer = %SlotB
@onready var _item_picker_panel: PanelContainer = %ItemPickerPanel
@onready var _item_picker_list: VBoxContainer = %ItemPickerList

var _slot_a_item: String = ""
var _slot_b_item: String = ""
var _picking_for_slot: String = ""


func _ready() -> void:
	layer = 92
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_breed_button.pressed.connect(_on_breed_pressed)
	BreedingManager.breed_succeeded.connect(_on_breed_succeeded)
	BreedingManager.breed_failed.connect(_on_breed_failed)
	BreedingManager.combo_discovered.connect(_on_combo_discovered)
	_item_picker_panel.visible = false
	_slot_a_panel.gui_input.connect(_on_slot_a_clicked)
	_slot_b_panel.gui_input.connect(_on_slot_b_clicked)
	var switch_btn: Button = find_child("SwitchToCraftingBtn", true, false) as Button
	if switch_btn != null:
		switch_btn.pressed.connect(_on_switch_to_crafting)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _item_picker_panel.visible:
			_item_picker_panel.visible = false
		else:
			close()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_refresh_slots()
	_refresh_combo_list()
	get_tree().paused = true


func close() -> void:
	visible = false
	_item_picker_panel.visible = false
	get_tree().paused = false


func _on_slot_a_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_picking_for_slot = "a"
		_open_item_picker()


func _on_slot_b_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_picking_for_slot = "b"
		_open_item_picker()


func _open_item_picker() -> void:
	for child in _item_picker_list.get_children():
		child.queue_free()
	var has_items: bool = false
	for i: int in range(30):
		var slot: Dictionary = InventoryManager.get_slot(i)
		if slot.is_empty():
			continue
		var item_id: String = str(slot.get("item_id", ""))
		var count: int = int(slot.get("count", 0))
		if item_id.is_empty() or count <= 0:
			continue
		has_items = true
		var btn: Button = Button.new()
		btn.text = "%s x%d" % [ItemDatabase.get_display_name(item_id), count]
		btn.add_theme_font_size_override("font_size", 8)
		var capture_id: String = item_id
		btn.pressed.connect(func() -> void: _select_item(capture_id))
		_item_picker_list.add_child(btn)
	if not has_items:
		var lbl: Label = Label.new()
		lbl.text = "(No items)"
		lbl.add_theme_font_size_override("font_size", 8)
		_item_picker_list.add_child(lbl)
	_item_picker_panel.visible = true


func _select_item(item_id: String) -> void:
	if _picking_for_slot == "a":
		_slot_a_item = item_id
	else:
		_slot_b_item = item_id
	_item_picker_panel.visible = false
	_picking_for_slot = ""
	_refresh_slots()


func _refresh_slots() -> void:
	_slot_a_label.text = ItemDatabase.get_display_name(_slot_a_item) if not _slot_a_item.is_empty() else "?"
	_slot_b_label.text = ItemDatabase.get_display_name(_slot_b_item) if not _slot_b_item.is_empty() else "?"
	_update_slot_style(_slot_a_panel, not _slot_a_item.is_empty())
	_update_slot_style(_slot_b_panel, not _slot_b_item.is_empty())
	_refresh_output()


func _update_slot_style(panel: PanelContainer, filled: bool) -> void:
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = SLOT_FILLED_COLOR if filled else SLOT_EMPTY_COLOR


func _refresh_output() -> void:
	if _slot_a_item.is_empty() or _slot_b_item.is_empty():
		_output_label.text = "?"
		_breed_button.disabled = true
		return
	var combo_id: String = BreedingManager.find_combo(_slot_a_item, _slot_b_item)
	if not combo_id.is_empty() and BreedingManager.is_discovered(combo_id):
		_output_label.text = BreedingManager.get_display_name(combo_id)
	else:
		_output_label.text = "?"
	_breed_button.disabled = not BreedingManager.can_breed(_slot_a_item, _slot_b_item)


func _refresh_combo_list() -> void:
	for child in _combo_list.get_children():
		child.queue_free()
	for combo_id: String in BreedingManager.get_all_combo_ids():
		var combo: Dictionary = BreedingManager.get_combo(combo_id)
		var discovered: bool = BreedingManager.is_discovered(combo_id)
		var lbl: Label = Label.new()
		lbl.add_theme_font_size_override("font_size", 8)
		if discovered:
			var ia: String = ItemDatabase.get_display_name(str(combo.get("input_a", "")))
			var ib: String = ItemDatabase.get_display_name(str(combo.get("input_b", "")))
			lbl.text = "%s + %s -> %s" % [ia, ib, str(combo.get("display_name", combo_id))]
			lbl.modulate = Color.WHITE
		else:
			lbl.text = "??? + ??? -> ???"
			lbl.modulate = Color(0.5, 0.5, 0.5, 1.0)
		_combo_list.add_child(lbl)


func _on_breed_pressed() -> void:
	if _slot_a_item.is_empty() or _slot_b_item.is_empty():
		return
	BreedingManager.breed(_slot_a_item, _slot_b_item)


func _on_breed_succeeded(_combo_id: String, result_item_id: String) -> void:
	_output_label.text = ItemDatabase.get_display_name(result_item_id)
	_show_breed_feedback("Success!")
	_slot_a_item = ""
	_slot_b_item = ""
	_refresh_slots()
	_refresh_combo_list()


func _on_breed_failed(_reason: String) -> void:
	_show_breed_feedback("Failed!")
	_output_label.modulate = Color(0.9, 0.3, 0.3, 1.0)
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void: _output_label.modulate = Color.WHITE)
	_slot_a_item = ""
	_slot_b_item = ""
	_refresh_slots()


func _on_combo_discovered(_combo_id: String) -> void:
	_refresh_combo_list()


func _show_breed_feedback(msg: String) -> void:
	_breed_button.text = msg
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void: _breed_button.text = "BREED")


func _on_switch_to_crafting() -> void:
	close()
	var screen: Node = get_tree().current_scene.find_child("CraftingScreen", true, false)
	if screen != null and screen.has_method("open"):
		screen.open()
