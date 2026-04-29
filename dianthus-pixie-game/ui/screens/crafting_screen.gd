extends CanvasLayer

const ACCENT_COLOR: Color = Color(0.9, 0.75, 0.2, 1.0)
const CRAFTABLE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const UNCRAFTABLE_COLOR: Color = Color(0.5, 0.5, 0.5, 1.0)
const HAVE_COLOR: Color = Color(0.4, 0.9, 0.4, 1.0)
const NEED_COLOR: Color = Color(0.9, 0.3, 0.3, 1.0)

@onready var _recipe_list: VBoxContainer = %RecipeList
@onready var _description_label: Label = %DescriptionLabel
@onready var _craft_button: Button = %CraftButton

var _selected_recipe_id: String = ""
var _row_panels: Dictionary = {}


func _ready() -> void:
	layer = 91
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_craft_button.pressed.connect(_on_craft_pressed)
	CraftingManager.weapon_crafted.connect(_on_weapon_crafted)
	InventoryManager.inventory_changed.connect(_refresh_availability)
	var switch_btn: Button = find_child("SwitchToBreedingBtn", true, false) as Button
	if switch_btn != null:
		switch_btn.pressed.connect(_on_switch_to_breeding)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	SfxManager.play("screen_open")
	visible = true
	_build_recipe_list()
	get_tree().paused = true


func close() -> void:
	SfxManager.play("screen_close")
	visible = false
	get_tree().paused = false
	_selected_recipe_id = ""


# --- Private ---

func _build_recipe_list() -> void:
	for child: Node in _recipe_list.get_children():
		child.queue_free()
	_row_panels.clear()
	_selected_recipe_id = ""
	_description_label.text = "Select a recipe."
	_craft_button.disabled = true

	for recipe_id: String in RecipeDatabase.get_all_recipe_ids():
		var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
		var result_id: String = str(recipe.get("result_id", ""))
		var owned: bool = CraftingManager.owns_weapon(result_id)
		var craftable: bool = CraftingManager.can_craft(recipe_id)

		var row: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 24)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)

		var name_label: Label = Label.new()
		name_label.text = RecipeDatabase.get_display_name(recipe_id)
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.modulate = CRAFTABLE_COLOR if craftable else UNCRAFTABLE_COLOR

		var mat_label: Label = Label.new()
		mat_label.text = _build_material_summary(recipe_id)
		mat_label.add_theme_font_size_override("font_size", 8)
		mat_label.modulate = UNCRAFTABLE_COLOR

		var tag_label: Label = Label.new()
		tag_label.add_theme_font_size_override("font_size", 8)
		if owned:
			tag_label.text = "[Owned]"
			tag_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		elif RecipeDatabase.is_upgrade(recipe_id):
			tag_label.text = "[Upgrade]"
			tag_label.modulate = Color(0.8, 0.6, 1.0, 1.0)

		hbox.add_child(name_label)
		hbox.add_child(mat_label)
		hbox.add_child(tag_label)
		row.add_child(hbox)

		var final_id: String = recipe_id
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
				_select_recipe(final_id)
		)

		_recipe_list.add_child(row)
		_row_panels[recipe_id] = row


func _select_recipe(recipe_id: String) -> void:
	SfxManager.play("ui_button_click")
	_selected_recipe_id = recipe_id
	_update_selection_highlight()
	_update_description()
	_craft_button.disabled = not CraftingManager.can_craft(recipe_id)


func _update_selection_highlight() -> void:
	for rid: String in _row_panels:
		var row: PanelContainer = _row_panels[rid] as PanelContainer
		var style: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
		if rid == _selected_recipe_id:
			style.border_color = ACCENT_COLOR
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		else:
			style.border_color = Color(0.3, 0.3, 0.3, 1.0)
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1


func _update_description() -> void:
	if _selected_recipe_id.is_empty():
		_description_label.text = "Select a recipe."
		return
	var recipe: Dictionary = RecipeDatabase.get_recipe(_selected_recipe_id)
	var desc: String = str(recipe.get("description", ""))
	var materials: Dictionary = RecipeDatabase.get_materials(_selected_recipe_id)
	var mat_lines: PackedStringArray = PackedStringArray()
	for item_id: String in materials:
		var needed: int = int(materials[item_id])
		var have: int = InventoryManager.get_total_count(item_id)
		var display: String = ItemDatabase.get_display_name(item_id)
		var suffix: String = " (%d/%d)" % [have, needed]
		mat_lines.append("%dx %s%s" % [needed, display, suffix])
	_description_label.text = desc + "\n" + "\n".join(mat_lines)


func _refresh_availability() -> void:
	if not visible:
		return
	for recipe_id: String in _row_panels:
		var row: PanelContainer = _row_panels[recipe_id] as PanelContainer
		var hbox: HBoxContainer = row.get_child(0) as HBoxContainer
		var name_label: Label = hbox.get_child(0) as Label
		var craftable: bool = CraftingManager.can_craft(recipe_id)
		name_label.modulate = CRAFTABLE_COLOR if craftable else UNCRAFTABLE_COLOR
	if not _selected_recipe_id.is_empty():
		_update_description()
		_craft_button.disabled = not CraftingManager.can_craft(_selected_recipe_id)


func _build_material_summary(recipe_id: String) -> String:
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	var parts: PackedStringArray = PackedStringArray()
	for item_id: String in materials:
		parts.append("%dx %s" % [int(materials[item_id]), ItemDatabase.get_display_name(item_id)])
	return ", ".join(parts)


func _on_craft_pressed() -> void:
	if _selected_recipe_id.is_empty():
		return
	var ok: bool = CraftingManager.craft(_selected_recipe_id)
	if ok:
		_show_feedback("Crafted!")
	_build_recipe_list()
	if not _selected_recipe_id.is_empty():
		_select_recipe(_selected_recipe_id)


func _on_weapon_crafted(_weapon_id: String) -> void:
	if visible:
		_build_recipe_list()


func _show_feedback(msg: String) -> void:
	_craft_button.text = msg
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void: _craft_button.text = "CRAFT")


func _on_switch_to_breeding() -> void:
	close()
	var screen: Node = get_tree().current_scene.find_child("CrossBreedingScreen", true, false)
	if screen != null and screen.has_method("open"):
		screen.open()
