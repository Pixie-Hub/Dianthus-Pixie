extends CanvasLayer

const CATEGORY_PLANTS: String = "plants"
const CATEGORY_ENEMIES: String = "enemies"
const DISCOVERED_COLOR: Color = Color(0.95, 0.9, 0.8, 1.0)
const UNDISCOVERED_COLOR: Color = Color(0.45, 0.4, 0.34, 1.0)
const GREY_SWATCH: Color = Color(0.25, 0.23, 0.2, 1.0)
const EnemyCatalog = preload("res://ui/codex/enemy_registry.gd")

@onready var _plant_tab_button: Button = %PlantsTabButton
@onready var _enemy_tab_button: Button = %EnemiesTabButton
@onready var _title_label: Label = %TitleLabel
@onready var _entry_list: VBoxContainer = %EntryList
@onready var _entry_row_template: PanelContainer = %EntryRowTemplate
@onready var _entry_row_selected_template: PanelContainer = %EntryRowSelectedTemplate
@onready var _section_divider_template: Label = %SectionDividerTemplate

@onready var _plant_detail_panel: VBoxContainer = %PlantDetailPanel
@onready var _plant_name_label: Label = %PlantNameLabel
@onready var _plant_role_label: Label = %PlantRoleLabel
@onready var _plant_effect_label: Label = %PlantEffectLabel
@onready var _plant_radius_label: Label = %PlantRadiusLabel
@onready var _plant_recipe_label: Label = %PlantRecipeLabel
@onready var _plant_hint_label: Label = %PlantHintLabel
@onready var _plant_sprite_rect: TextureRect = %PlantSprite

@onready var _enemy_detail_panel: VBoxContainer = %EnemyDetailPanel
@onready var _enemy_name_label: Label = %EnemyNameLabel
@onready var _enemy_role_label: Label = %EnemyRoleLabel
@onready var _enemy_hp_value: Label = %EnemyHPValue
@onready var _enemy_damage_value: Label = %EnemyDamageValue
@onready var _enemy_speed_value: Label = %EnemySpeedValue
@onready var _enemy_drops_label: Label = %EnemyDropsLabel
@onready var _enemy_lore_label: Label = %EnemyLoreLabel
@onready var _enemy_hint_label: Label = %EnemyHintLabel
@onready var _enemy_sprite_rect: TextureRect = %EnemySprite

var _active_category: String = CATEGORY_PLANTS
var _selected_entry_id: String = ""
var _row_panels: Dictionary = {}


func _ready() -> void:
	layer = 93
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_plant_tab_button.pressed.connect(_switch_category.bind(CATEGORY_PLANTS))
	_enemy_tab_button.pressed.connect(_switch_category.bind(CATEGORY_ENEMIES))
	CodexManager.plant_discovered.connect(_on_codex_entry_discovered)
	CodexManager.enemy_discovered.connect(_on_codex_entry_discovered)


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
	_build_current_list()
	PauseManager.request_pause(self)


func close() -> void:
	SfxManager.play("screen_close")
	visible = false
	PauseManager.release_pause(self)
	_selected_entry_id = ""


func _switch_category(category: String) -> void:
	if _active_category == category and visible:
		return
	SfxManager.play("ui_button_click")
	_active_category = category
	_selected_entry_id = ""
	if visible:
		_build_current_list()


func _build_current_list() -> void:
	for child: Node in _entry_list.get_children():
		child.queue_free()
	_row_panels.clear()
	_update_tabs()
	_update_title()
	if _active_category == CATEGORY_PLANTS:
		_build_plant_list()
		_update_plant_detail("")
	else:
		_build_enemy_list()
		_update_enemy_detail("")


func _build_plant_list() -> void:
	for plant_id: String in PlantRegistry.get_base_plant_ids():
		_add_plant_row(plant_id)
	_add_section_divider("HYBRIDS")
	for plant_id: String in PlantRegistry.get_hybrid_plant_ids():
		_add_plant_row(plant_id)


func _build_enemy_list() -> void:
	for enemy_id: String in EnemyCatalog.get_enemy_ids():
		_add_enemy_row(enemy_id)


func _add_plant_row(plant_id: String) -> void:
	var discovered: bool = CodexManager.is_plant_discovered(plant_id)
	var data: Dictionary = PlantRegistry.get_plant(plant_id)
	var display_name: String = PlantRegistry.get_display_name(plant_id) if discovered else "???"
	var swatch_color: Color = data.get("color", GREY_SWATCH) if discovered else GREY_SWATCH
	_add_entry_row(plant_id, display_name, swatch_color, discovered)


func _add_enemy_row(enemy_id: String) -> void:
	var discovered: bool = CodexManager.is_enemy_discovered(enemy_id)
	var display_name: String = EnemyCatalog.get_display_name(enemy_id) if discovered else "Unknown"
	var swatch_color: Color = Color(0.75, 0.12, 0.12, 1.0) if discovered else GREY_SWATCH
	_add_entry_row(enemy_id, display_name, swatch_color, discovered)


func _add_entry_row(entry_id: String, display_name: String, swatch_color: Color, discovered: bool) -> void:
	var row: PanelContainer = _entry_row_template.duplicate() as PanelContainer
	row.unique_name_in_owner = false
	row.visible = true
	row.name = "%sRow" % entry_id.capitalize()
	var swatch: ColorRect = row.find_child("EntrySwatch", true, false) as ColorRect
	if swatch != null:
		swatch.color = swatch_color
	var name_label: Label = row.find_child("EntryNameLabel", true, false) as Label
	if name_label != null:
		name_label.text = display_name
		name_label.modulate = DISCOVERED_COLOR if discovered else UNDISCOVERED_COLOR
	row.gui_input.connect(_on_entry_row_input.bind(entry_id))
	_entry_list.add_child(row)
	_row_panels[entry_id] = row


func _add_section_divider(text: String) -> void:
	var divider: Label = _section_divider_template.duplicate() as Label
	divider.unique_name_in_owner = false
	divider.visible = true
	divider.text = text
	_entry_list.add_child(divider)


func _on_entry_row_input(event: InputEvent, entry_id: String) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		SfxManager.play("ui_button_click")
		_selected_entry_id = entry_id
		_update_selection_highlight()
		if _active_category == CATEGORY_PLANTS:
			_update_plant_detail(entry_id)
		else:
			_update_enemy_detail(entry_id)


func _update_selection_highlight() -> void:
	for entry_id: String in _row_panels:
		var row: PanelContainer = _row_panels[entry_id] as PanelContainer
		var source: PanelContainer = _entry_row_selected_template if entry_id == _selected_entry_id else _entry_row_template
		var style: StyleBox = source.get_theme_stylebox("panel")
		if style != null:
			row.add_theme_stylebox_override("panel", style.duplicate())


func _update_plant_detail(plant_id: String) -> void:
	_plant_detail_panel.visible = true
	_enemy_detail_panel.visible = false
	if plant_id.is_empty():
		_show_plant_placeholder()
		return
	var discovered: bool = CodexManager.is_plant_discovered(plant_id)
	var data: Dictionary = PlantRegistry.get_plant(plant_id)
	_plant_name_label.text = PlantRegistry.get_display_name(plant_id) if discovered else "???"
	_plant_name_label.modulate = data.get("color", DISCOVERED_COLOR) if discovered else UNDISCOVERED_COLOR
	_plant_role_label.text = str(data.get("role", "Unknown")) if discovered else "Unknown plant"
	_plant_effect_label.text = str(data.get("effect", "")) if discovered else "Not yet discovered."
	_plant_radius_label.text = "Effect Radius: %.0fpx" % float(data.get("radius", 0.0)) if discovered else "Effect Radius: ???"
	_plant_hint_label.text = "" if discovered else str(data.get("unlock_hint", "Find this plant in the world."))
	_plant_recipe_label.text = _get_plant_recipe_text(plant_id, data) if discovered else ""
	_set_texture_rect(_plant_sprite_rect, PlantRegistry.get_sprite_path(plant_id), discovered)


func _show_plant_placeholder() -> void:
	_plant_name_label.text = "Select a plant."
	_plant_name_label.modulate = UNDISCOVERED_COLOR
	_plant_role_label.text = ""
	_plant_effect_label.text = ""
	_plant_radius_label.text = ""
	_plant_recipe_label.text = ""
	_plant_hint_label.text = ""
	_plant_sprite_rect.texture = null


func _get_plant_recipe_text(plant_id: String, data: Dictionary) -> String:
	if not bool(data.get("is_hybrid", false)):
		return ""
	var combo_id: String = str(data.get("combo_id", ""))
	var combo: Dictionary = BreedingManager.get_combo(combo_id)
	if combo.is_empty():
		return ""
	var input_a: String = ItemDatabase.get_display_name(str(combo.get("input_a", "")))
	var input_b: String = ItemDatabase.get_display_name(str(combo.get("input_b", "")))
	if BreedingManager.is_discovered(combo_id) or CodexManager.is_plant_discovered(plant_id):
		return "Recipe: %s + %s" % [input_a, input_b]
	return "Recipe: ??? + ???"


func _update_enemy_detail(enemy_id: String) -> void:
	_plant_detail_panel.visible = false
	_enemy_detail_panel.visible = true
	if enemy_id.is_empty():
		_show_enemy_placeholder()
		return
	var discovered: bool = CodexManager.is_enemy_discovered(enemy_id)
	var data: Dictionary = EnemyCatalog.get_enemy(enemy_id)
	var stats: Dictionary = EnemyCatalog.get_stats(enemy_id)
	_enemy_name_label.text = EnemyCatalog.get_display_name(enemy_id) if discovered else "Unknown Enemy"
	_enemy_name_label.modulate = DISCOVERED_COLOR if discovered else UNDISCOVERED_COLOR
	_enemy_role_label.text = str(data.get("role", "Unknown threat")) if discovered else "Unseen threat"
	_enemy_hp_value.text = str(stats.get("hp", 0)) if discovered else "???"
	_enemy_damage_value.text = str(stats.get("damage", 0)) if discovered else "???"
	_enemy_speed_value.text = "%.0f" % float(stats.get("speed", 0.0)) if discovered else "???"
	_enemy_drops_label.text = "Drops: %s" % EnemyCatalog.get_drop_summary(enemy_id) if discovered else "Drops: Unknown"
	_enemy_lore_label.text = str(data.get("lore", "")) if discovered else "Encounter this enemy type to reveal its records."
	_enemy_hint_label.text = "" if discovered else str(data.get("unlock_hint", "Meet this enemy in combat."))
	_enemy_sprite_rect.texture = EnemyCatalog.get_sprite_texture(enemy_id)
	_enemy_sprite_rect.modulate = Color.WHITE if discovered else Color.BLACK


func _show_enemy_placeholder() -> void:
	_enemy_name_label.text = "Select an enemy."
	_enemy_name_label.modulate = UNDISCOVERED_COLOR
	_enemy_role_label.text = ""
	_enemy_hp_value.text = "-"
	_enemy_damage_value.text = "-"
	_enemy_speed_value.text = "-"
	_enemy_drops_label.text = ""
	_enemy_lore_label.text = ""
	_enemy_hint_label.text = ""
	_enemy_sprite_rect.texture = null


func _set_texture_rect(rect: TextureRect, texture_path: String, discovered: bool) -> void:
	rect.texture = load(texture_path) if not texture_path.is_empty() else null
	rect.modulate = Color.WHITE if discovered else Color.BLACK


func _update_tabs() -> void:
	_plant_tab_button.button_pressed = _active_category == CATEGORY_PLANTS
	_enemy_tab_button.button_pressed = _active_category == CATEGORY_ENEMIES


func _update_title() -> void:
	if _active_category == CATEGORY_PLANTS:
		_title_label.text = "PLANT CODEX  (%d / %d discovered)" % [
			CodexManager.get_discovered_count(),
			CodexManager.get_total_count(),
		]
	else:
		_title_label.text = "ENEMY BESTIARY  (%d / %d discovered)" % [
			CodexManager.get_enemy_discovered_count(),
			CodexManager.get_enemy_total_count(),
		]


func _on_codex_entry_discovered(_entry_id: String) -> void:
	if visible:
		_build_current_list()
