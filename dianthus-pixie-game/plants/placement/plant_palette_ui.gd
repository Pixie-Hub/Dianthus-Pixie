extends CanvasLayer

var _manager: Node = null
var _panel: PanelContainer = null
var _scroll: ScrollContainer = null
var _hbox: HBoxContainer = null


func setup(manager: Node) -> void:
	_manager = manager
	InventoryManager.inventory_changed.connect(refresh)


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_layout()


func _build_layout() -> void:
	_panel = PanelContainer.new()
	add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "PLANT"
	title.add_theme_font_size_override("font_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_scroll)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 4)
	_scroll.add_child(_hbox)

	var hint: Label = Label.new()
	hint.text = "[P] Close  [RMB] Cancel"
	hint.add_theme_font_size_override("font_size", 6)
	hint.modulate = Color(0.7, 0.7, 0.7, 1.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func _position_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var panel_size: Vector2 = _panel.size
	if panel_size == Vector2.ZERO:
		return
	_panel.position = Vector2(
		(640.0 - panel_size.x) / 2.0,
		360.0 - panel_size.y - 4.0
	)


func refresh() -> void:
	if not is_instance_valid(_hbox):
		return
	if not is_instance_valid(_manager):
		return
	for child: Node in _hbox.get_children():
		child.queue_free()

	for seed_id: String in _manager.SEED_TO_SCENE.keys():
		var count: int = InventoryManager.get_total_count(seed_id)
		if count <= 0:
			continue

		var slot: PanelContainer = PanelContainer.new()
		slot.custom_minimum_size = Vector2(32, 32)

		if seed_id == _manager.selected_seed_id:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.border_color = Color(1.0, 0.85, 0.3)
			slot.add_theme_stylebox_override("panel", style)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)

		var seed_color: Color = _manager.SEED_RADIUS_COLORS.get(seed_id, Color(0.5, 0.5, 1.0, 1.0))
		seed_color.a = 1.0

		var color_rect: ColorRect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(16, 16)
		color_rect.color = seed_color
		vbox.add_child(color_rect)

		var count_label: Label = Label.new()
		count_label.text = str(count)
		count_label.add_theme_font_size_override("font_size", 6)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(count_label)

		slot.gui_input.connect(_on_slot_clicked.bind(seed_id))
		_hbox.add_child(slot)

	var slot_count: int = _hbox.get_child_count()
	var content_width: float = slot_count * (32 + 4) + 8.0
	_scroll.custom_minimum_size.x = min(content_width, 320.0)

	await get_tree().process_frame
	_position_panel()


func _on_slot_clicked(event: InputEvent, seed_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_instance_valid(_manager):
			_manager.select_seed(seed_id)
			refresh()


func show_palette() -> void:
	visible = true
	refresh()


func hide_palette() -> void:
	visible = false
