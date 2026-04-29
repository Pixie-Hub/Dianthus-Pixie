extends CanvasLayer

const ACCENT_COLOR: Color = Color(0.9, 0.75, 0.2, 1.0)
const DISCOVERED_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const UNDISCOVERED_COLOR: Color = Color(0.45, 0.45, 0.45, 1.0)
const GREY_SWATCH: Color = Color(0.25, 0.25, 0.25, 1.0)

@onready var _plant_list: VBoxContainer = %PlantList
@onready var _detail_panel: VBoxContainer = %DetailPanel
@onready var _title_label: Label = %TitleLabel

var _selected_plant_id: String = ""
var _row_panels: Dictionary = {}


func _ready() -> void:
	layer = 93
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	CodexManager.plant_discovered.connect(_on_plant_discovered)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("codex_toggle"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	SfxManager.play("screen_open")
	visible = true
	_build_plant_list()
	PauseManager.request_pause(self)


func close() -> void:
	SfxManager.play("screen_close")
	visible = false
	PauseManager.release_pause(self)
	_selected_plant_id = ""


# --- Private ---

func _build_plant_list() -> void:
	for child: Node in _plant_list.get_children():
		child.queue_free()
	_row_panels.clear()
	_selected_plant_id = ""
	_update_title()
	_clear_detail()

	for pid: String in PlantRegistry.get_base_plant_ids():
		_add_plant_row(pid)

	var divider: Label = Label.new()
	divider.text = "— HYBRIDS —"
	divider.add_theme_font_size_override("font_size", 7)
	divider.modulate = Color(0.55, 0.55, 0.55, 1.0)
	divider.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plant_list.add_child(divider)

	for pid: String in PlantRegistry.get_hybrid_plant_ids():
		_add_plant_row(pid)


func _add_plant_row(plant_id: String) -> void:
	var discovered: bool = CodexManager.is_plant_discovered(plant_id)
	var data: Dictionary = PlantRegistry.get_plant(plant_id)

	var row: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.28, 0.28, 0.28, 1.0)
	row.add_theme_stylebox_override("panel", style)
	row.custom_minimum_size = Vector2(0, 20)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var swatch: ColorRect = ColorRect.new()
	swatch.custom_minimum_size = Vector2(8, 8)
	swatch.color = data.get("color", Color(0.3, 0.3, 0.3, 1)) if discovered else GREY_SWATCH

	var name_label: Label = Label.new()
	name_label.text = PlantRegistry.get_display_name(plant_id) if discovered else "???"
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.modulate = DISCOVERED_COLOR if discovered else UNDISCOVERED_COLOR

	hbox.add_child(swatch)
	hbox.add_child(name_label)
	row.add_child(hbox)

	var final_id: String = plant_id
	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_select_plant(final_id)
	)

	_plant_list.add_child(row)
	_row_panels[plant_id] = row


func _select_plant(plant_id: String) -> void:
	SfxManager.play("ui_button_click")
	_selected_plant_id = plant_id
	_update_selection_highlight()
	_update_detail(plant_id)


func _update_selection_highlight() -> void:
	for pid: String in _row_panels:
		var row: PanelContainer = _row_panels[pid] as PanelContainer
		var style: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
		if pid == _selected_plant_id:
			style.border_color = ACCENT_COLOR
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		else:
			style.border_color = Color(0.28, 0.28, 0.28, 1.0)
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1


func _update_detail(plant_id: String) -> void:
	for child: Node in _detail_panel.get_children():
		child.queue_free()

	var discovered: bool = CodexManager.is_plant_discovered(plant_id)
	var data: Dictionary = PlantRegistry.get_plant(plant_id)

	var name_lbl: Label = Label.new()
	name_lbl.add_theme_font_size_override("font_size", 10)
	if discovered:
		name_lbl.text = PlantRegistry.get_display_name(plant_id)
		name_lbl.modulate = data.get("color", Color.WHITE)
	else:
		name_lbl.text = "???"
		name_lbl.modulate = UNDISCOVERED_COLOR
	_detail_panel.add_child(name_lbl)

	if discovered:
		var role_lbl: Label = Label.new()
		role_lbl.text = str(data.get("role", ""))
		role_lbl.add_theme_font_size_override("font_size", 7)
		role_lbl.modulate = Color(0.7, 0.85, 1.0, 1.0)
		_detail_panel.add_child(role_lbl)

		var sep: HSeparator = HSeparator.new()
		_detail_panel.add_child(sep)

		var effect_lbl: Label = Label.new()
		effect_lbl.text = str(data.get("effect", ""))
		effect_lbl.add_theme_font_size_override("font_size", 7)
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_detail_panel.add_child(effect_lbl)

		var radius_lbl: Label = Label.new()
		radius_lbl.text = "Effect Radius: %.0fpx" % float(data.get("radius", 0.0))
		radius_lbl.add_theme_font_size_override("font_size", 7)
		radius_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
		_detail_panel.add_child(radius_lbl)

		if bool(data.get("is_hybrid", false)):
			var combo_id: String = str(data.get("combo_id", ""))
			var combo: Dictionary = BreedingManager.get_combo(combo_id)
			var combo_lbl: Label = Label.new()
			combo_lbl.add_theme_font_size_override("font_size", 7)
			combo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var ia: String = ItemDatabase.get_display_name(str(combo.get("input_a", "")))
			var ib: String = ItemDatabase.get_display_name(str(combo.get("input_b", "")))
			combo_lbl.text = "Recipe: %s + %s" % [ia, ib]
			combo_lbl.modulate = ACCENT_COLOR
			_detail_panel.add_child(combo_lbl)
	else:
		var hint_lbl: Label = Label.new()
		hint_lbl.text = "Not yet discovered.\n" + str(data.get("unlock_hint", ""))
		hint_lbl.add_theme_font_size_override("font_size", 7)
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_lbl.modulate = UNDISCOVERED_COLOR
		_detail_panel.add_child(hint_lbl)

	var sprite_path: String = PlantRegistry.get_sprite_path(plant_id)
	if sprite_path != "":
		var spacer: Control = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_detail_panel.add_child(spacer)

		var sprite_container: HBoxContainer = HBoxContainer.new()
		sprite_container.alignment = BoxContainer.ALIGNMENT_END

		var sprite_rect: TextureRect = TextureRect.new()
		sprite_rect.texture = load(sprite_path)
		sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite_rect.custom_minimum_size = Vector2(192, 192)
		sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite_rect.modulate = Color(1, 1, 1, 1) if discovered else Color(0, 0, 0, 1)

		sprite_container.add_child(sprite_rect)
		_detail_panel.add_child(sprite_container)


func _clear_detail() -> void:
	for child: Node in _detail_panel.get_children():
		child.queue_free()
	var placeholder: Label = Label.new()
	placeholder.text = "Select a plant."
	placeholder.add_theme_font_size_override("font_size", 8)
	placeholder.modulate = UNDISCOVERED_COLOR
	_detail_panel.add_child(placeholder)


func _update_title() -> void:
	_title_label.text = "PLANT CODEX  (%d / %d discovered)" % [
		CodexManager.get_discovered_count(),
		CodexManager.get_total_count(),
	]


func _on_plant_discovered(_plant_id: String) -> void:
	if visible:
		_build_plant_list()
