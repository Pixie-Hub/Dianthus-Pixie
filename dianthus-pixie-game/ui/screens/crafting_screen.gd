extends CanvasLayer
class_name CraftingScreen

const ACCENT_COLOR: Color = Color(1.0, 0.80, 0.25, 1.0)
const CRAFTABLE_COLOR: Color = Color(0.95, 0.90, 0.80, 1.0)
const UNCRAFTABLE_COLOR: Color = Color(0.50, 0.45, 0.38, 1.0)
const HAVE_COLOR: Color = Color(0.40, 0.75, 0.35, 1.0)
const NEED_COLOR: Color = Color(0.85, 0.30, 0.25, 1.0)
const ROW_BG_COLOR: Color = Color(0.14, 0.09, 0.05, 1.0)
const ROW_BORDER_COLOR: Color = Color(0.38, 0.28, 0.12, 1.0)
const ROW_SELECTED_BORDER: Color = Color(1.0, 0.80, 0.25, 1.0)
const UPGRADE_COLOR: Color = Color(0.75, 0.55, 1.0, 1.0)
const OWNED_COLOR: Color = Color(0.50, 0.45, 0.38, 1.0)
const CRAFT_DELAY: float = 4.0
const SKIP_CRAFT_DELAY: float = 1.5
const MAX_BENCH_DISTANCE: float = 48.0
const MINIGAME_SCENE: String = "res://minigames/crafting_assembly/crafting_assembly_screen.tscn"

static var skip_crafting_minigame: bool = false

@onready var _recipe_list: VBoxContainer = %RecipeList
@onready var _description_label: Label = %DescriptionLabel
@onready var _craft_button: Button = %CraftButton

var _selected_recipe_id: String = ""
var _row_panels: Dictionary = {}
var _is_crafting: bool = false
var _minigame_active: bool = false
var _craft_timer: float = 0.0
var _craft_delay_current: float = CRAFT_DELAY
var _bench_pos: Vector2 = Vector2(-99999.0, -99999.0)
var _craft_progress: ProgressBar = null
var _active_minigame: Node = null


func _ready() -> void:
	layer = 91
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_craft_button.pressed.connect(_on_craft_pressed)
	CraftingManager.weapon_crafted.connect(_on_weapon_crafted)
	CraftingManager.ability_crafted.connect(_on_weapon_crafted)
	InventoryManager.inventory_changed.connect(_refresh_availability)
	var switch_btn: Button = find_child("SwitchToBreedingBtn", true, false) as Button
	if switch_btn != null:
		switch_btn.pressed.connect(_on_switch_to_breeding)
	_craft_progress = ProgressBar.new()
	_craft_progress.min_value = 0.0
	_craft_progress.max_value = CRAFT_DELAY
	_craft_progress.value = 0.0
	_craft_progress.custom_minimum_size = Vector2(0, 8)
	_craft_progress.visible = false
	call_deferred("_insert_craft_progress")


func _insert_craft_progress() -> void:
	if not is_instance_valid(_craft_button) or not is_instance_valid(_craft_progress):
		return
	var parent: Control = _craft_button.get_parent() as Control
	if parent == null:
		return
	parent.add_child(_craft_progress)
	parent.move_child(_craft_progress, _craft_button.get_index() + 1)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if (not _is_crafting and not _minigame_active) or not visible:
		return
	if _bench_pos.x > -99998.0 and is_instance_valid(GameManager.player):
		var dist: float = GameManager.player.global_position.distance_to(_bench_pos)
		if dist > MAX_BENCH_DISTANCE:
			if _minigame_active and is_instance_valid(_active_minigame) and _active_minigame.has_method("cancel"):
				_active_minigame.call("cancel")
			else:
				_cancel_crafting()
			_show_feedback("Too far!")
			return
	if _minigame_active:
		return
	_craft_timer += delta
	if is_instance_valid(_craft_progress):
		_craft_progress.value = _craft_timer
	if _craft_timer >= _craft_delay_current:
		_finish_crafting()


func open() -> void:
	SfxManager.play("screen_open")
	visible = true
	var bench: Node = get_tree().current_scene.find_child("BreedingBench", true, false)
	if bench is Node2D:
		_bench_pos = (bench as Node2D).global_position
	else:
		_bench_pos = Vector2(-99999.0, -99999.0)
	_build_recipe_list()


func close() -> void:
	SfxManager.play("screen_close")
	_cancel_crafting()
	visible = false
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
		var result_type: String = str(recipe.get("result_type", "weapon"))
		var result_id: String = str(recipe.get("result_id", ""))
		var owned: bool = (result_type == "ability" and CraftingManager.owns_ability(result_id)) or \
				(result_type != "ability" and CraftingManager.owns_weapon(result_id))
		var craftable: bool = CraftingManager.can_craft(recipe_id)

		var row: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = ROW_BG_COLOR
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_right = 3
		style.corner_radius_bottom_left = 3
		style.border_color = ACCENT_COLOR if _is_tutorial_target_recipe(recipe_id) else ROW_BORDER_COLOR
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 26)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)

		var name_label: Label = Label.new()
		name_label.text = RecipeDatabase.get_display_name(recipe_id)
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _is_tutorial_target_recipe(recipe_id):
			name_label.add_theme_color_override("font_color", ACCENT_COLOR)
		else:
			name_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80, 1.0) if craftable else Color(0.50, 0.45, 0.38, 1.0))

		var mat_label: Label = Label.new()
		mat_label.text = _build_material_summary(recipe_id)
		mat_label.add_theme_font_size_override("font_size", 8)
		mat_label.add_theme_color_override("font_color", Color(0.50, 0.45, 0.38, 1.0))

		var tag_label: Label = Label.new()
		tag_label.add_theme_font_size_override("font_size", 8)
		if owned:
			var quality_tier: int = CraftingManager.get_ability_quality(result_id) if result_type == "ability" else CraftingManager.get_weapon_quality(result_id)
			tag_label.text = "[Perfect *]" if quality_tier >= 1 else "[Standard]"
			tag_label.add_theme_color_override("font_color", ACCENT_COLOR if quality_tier >= 1 else OWNED_COLOR)
		elif RecipeDatabase.is_upgrade(recipe_id):
			tag_label.text = "[Upgrade]"
			tag_label.add_theme_color_override("font_color", UPGRADE_COLOR)

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
	TutorialManager.report_recipe_selected(recipe_id)
	_update_selection_highlight()
	_update_description()
	_craft_button.disabled = not CraftingManager.can_craft(recipe_id)


func _update_selection_highlight() -> void:
	for rid: String in _row_panels:
		var row: PanelContainer = _row_panels[rid] as PanelContainer
		var style: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
		if rid == _selected_recipe_id:
			style.bg_color = Color(0.22, 0.15, 0.07, 1.0)
			style.border_color = ROW_SELECTED_BORDER
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		elif _is_tutorial_target_recipe(rid):
			style.bg_color = ROW_BG_COLOR
			style.border_color = ACCENT_COLOR
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
		else:
			style.bg_color = ROW_BG_COLOR
			style.border_color = ROW_BORDER_COLOR
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
		if _is_tutorial_target_recipe(recipe_id):
			name_label.add_theme_color_override("font_color", ACCENT_COLOR)
		else:
			name_label.add_theme_color_override("font_color", CRAFTABLE_COLOR if craftable else UNCRAFTABLE_COLOR)
	if not _selected_recipe_id.is_empty():
		_update_description()
		_craft_button.disabled = not CraftingManager.can_craft(_selected_recipe_id)


func _build_material_summary(recipe_id: String) -> String:
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	var parts: PackedStringArray = PackedStringArray()
	for item_id: String in materials:
		parts.append("%dx %s" % [int(materials[item_id]), ItemDatabase.get_display_name(item_id)])
	return ", ".join(parts)


func _is_tutorial_target_recipe(recipe_id: String) -> bool:
	return recipe_id == "thorn_sword" and TutorialManager.is_phase_2_active()


func _on_craft_pressed() -> void:
	if _selected_recipe_id.is_empty():
		return
	if _is_crafting or _minigame_active:
		_cancel_crafting()
		return
	if not CraftingManager.can_craft(_selected_recipe_id):
		return
	var tutorial_done: bool = UnlockFlags.has_flag("flag_tutorial_complete")
	var should_skip: bool = (tutorial_done and skip_crafting_minigame) or _is_tutorial_target_recipe(_selected_recipe_id)
	if not should_skip:
		_start_assembly_minigame()
		return
	_is_crafting = true
	_craft_timer = 0.0
	_craft_delay_current = SKIP_CRAFT_DELAY
	if is_instance_valid(_craft_progress):
		_craft_progress.max_value = _craft_delay_current
		_craft_progress.value = 0.0
		_craft_progress.visible = true
	_craft_button.text = "CANCEL"
	_craft_button.disabled = false


func _cancel_crafting() -> void:
	if _minigame_active and is_instance_valid(_active_minigame) and _active_minigame.has_method("cancel"):
		_active_minigame.call("cancel")
		return
	if not _is_crafting:
		return
	_is_crafting = false
	_minigame_active = false
	_active_minigame = null
	_craft_timer = 0.0
	_craft_delay_current = CRAFT_DELAY
	if is_instance_valid(_craft_progress):
		_craft_progress.visible = false
		_craft_progress.value = 0.0
		_craft_progress.max_value = CRAFT_DELAY
	_craft_button.text = "CRAFT"
	_craft_button.disabled = _selected_recipe_id.is_empty() or not CraftingManager.can_craft(_selected_recipe_id)


func _finish_crafting() -> void:
	_is_crafting = false
	_craft_timer = 0.0
	_craft_delay_current = CRAFT_DELAY
	if is_instance_valid(_craft_progress):
		_craft_progress.visible = false
		_craft_progress.max_value = CRAFT_DELAY
	var recipe_id: String = _selected_recipe_id
	var ok: bool = CraftingManager.craft(recipe_id, 0)
	if ok:
		_show_feedback("Crafted!")
	else:
		_craft_button.text = "CRAFT"
		_craft_button.disabled = not CraftingManager.can_craft(_selected_recipe_id)
	_build_recipe_list()
	if not recipe_id.is_empty() and _row_panels.has(recipe_id):
		_select_recipe(recipe_id)


func _start_assembly_minigame() -> void:
	var mg_scene: PackedScene = load(MINIGAME_SCENE) as PackedScene
	if mg_scene == null:
		push_warning("[Crafting] Could not load CraftingAssemblyScreen.")
		return
	var mg: Node = mg_scene.instantiate()
	_active_minigame = mg
	_minigame_active = true
	_craft_button.text = "CANCEL"
	_craft_button.disabled = false
	get_tree().root.add_child(mg)
	if mg.has_signal("finished"):
		mg.finished.connect(_on_assembly_finished, CONNECT_ONE_SHOT)
	if mg.has_method("start_assembly"):
		mg.call("start_assembly", _selected_recipe_id)


func _on_assembly_finished(quality_tier: int, success: bool) -> void:
	var recipe_id: String = _selected_recipe_id
	_minigame_active = false
	_active_minigame = null
	_craft_button.text = "CRAFT"
	if success:
		CraftingManager.craft(recipe_id, quality_tier)
		_show_feedback("Crafted!")
	else:
		CraftingManager.consume_materials_only(recipe_id)
		_show_feedback("Assembly failed!")
	_build_recipe_list()
	if not recipe_id.is_empty() and _row_panels.has(recipe_id):
		_select_recipe(recipe_id)


func _on_weapon_crafted(_weapon_id: String, _quality_tier: int = 0) -> void:
	if visible:
		_build_recipe_list()


func _show_feedback(msg: String) -> void:
	_craft_button.text = msg
	_craft_button.disabled = true
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void:
		_craft_button.text = "CRAFT"
		_craft_button.disabled = _selected_recipe_id.is_empty() or not CraftingManager.can_craft(_selected_recipe_id)
	)


func _on_switch_to_breeding() -> void:
	close()
	var screen: Node = get_tree().current_scene.find_child("CrossBreedingScreen", true, false)
	if screen != null and screen.has_method("open"):
		screen.open()
