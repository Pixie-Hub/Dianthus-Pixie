class_name FortificationSpot
extends BaseBuildSpot

const INTERACT_RADIUS: float = 28.0
const BARRICADE_BUILD_TIME: float = 4.0
const TRAP_BUILD_TIME: float = 3.0

const BARRICADE_MIN_DAY: int = 3
const TRAP_MIN_DAY: int = 5

const BARRICADE_COST: Dictionary = {"petal_shard": 3, "verdant_sap": 2}
const TRAP_COST: Dictionary = {"verdant_sap": 2, "moonspore": 1}

const BARRICADE_SCENE: String = "res://world/fortifications/thorn_barricade.tscn"
const TRAP_SCENE: String = "res://world/fortifications/spore_trap.tscn"

enum StructureType { BARRICADE, TRAP }

@export var spot_id: StringName = &""
@export var spot_label: String = "Fortification Spot"
@export var barricade_sideways: bool = false
@export var buildable_texture: Texture2D
@export var unbuildable_texture: Texture2D

var _is_built: bool = false
var _built_structure: Node = null
var _selected_type: StructureType = StructureType.BARRICADE

@onready var _visual: Sprite2D = $Visual


func _ready() -> void:
	super._ready()
	add_to_group(&"fortification_spots")
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	SaveManager.load_completed.connect(_on_load_completed)
	_apply_runtime_state()
	_update_visual()


func _process(delta: float) -> void:
	if _is_built:
		if not is_instance_valid(_built_structure):
			_is_built = false
			_built_structure = null
			_update_visual()
			SaveManager.register_fortification_spot_state(serialize_build_state())
			if _player_in_range:
				_refresh_prompt()
		return

	if not _is_building:
		return

	if not _player_in_range or not _has_interaction_focus() or not Input.is_action_pressed("interact"):
		_cancel_build()
		return

	if not _can_build_selected_type():
		_cancel_build()
		_refresh_prompt()
		return

	var build_time: float = BARRICADE_BUILD_TIME if _selected_type == StructureType.BARRICADE else TRAP_BUILD_TIME
	_build_progress += delta / build_time
	_update_progress_bar()
	var type_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
	_show_prompt(
		"Building %s" % type_name,
		"Progress: %.0f%%" % (_build_progress * 100.0),
		"Hold E",
		"Release E to cancel",
		Color(1.0, 0.78, 0.28, 1.0),
		PROMPT_STATUS_NORMAL,
		_build_progress
	)

	if _build_progress >= 1.0:
		_finish_build()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or not _has_interaction_focus() or _is_built or DayNightCycle.is_night():
		return

	if event.is_action_pressed("interact") and not _is_building:
		if not _can_build_selected_type():
			_refresh_prompt()
			get_viewport().set_input_as_handled()
			return
		_is_building = true
		_build_progress = 0.0
		_set_progress_visible(true)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("interact") and _is_building:
		_cancel_build()
		get_viewport().set_input_as_handled()
		return

	if not _is_building:
		if event.is_action_pressed("fort_type_next"):
			_cycle_type(1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("fort_type_prev"):
			_cycle_type(-1)
			get_viewport().set_input_as_handled()
			return


func _on_phase_changed(phase: String) -> void:
	if phase == "DAY":
		_cleanup_structure()
	elif phase == "NIGHT":
		_cancel_build()
		_update_visual()
		_hide_prompt()


func _on_inventory_changed() -> void:
	_update_visual()
	if _player_in_range and _has_interaction_focus():
		_refresh_prompt()


func _on_load_completed(_ok: bool) -> void:
	_apply_runtime_state()


func _can_afford() -> bool:
	var cost: Dictionary = BARRICADE_COST if _selected_type == StructureType.BARRICADE else TRAP_COST
	for item_id: String in cost:
		if not InventoryManager.has_item(item_id, cost[item_id]):
			return false
	return true


func _can_build_selected_type() -> bool:
	return DayNightCycle.is_day() and _is_selected_type_unlocked() and _can_afford()


func _is_selected_type_unlocked() -> bool:
	return DayNightCycle.day_count >= _get_selected_min_day()


func _get_selected_min_day() -> int:
	return BARRICADE_MIN_DAY if _selected_type == StructureType.BARRICADE else TRAP_MIN_DAY


func _finish_build() -> void:
	_is_building = false
	_build_progress = 0.0
	_set_progress_visible(false)

	var cost: Dictionary = BARRICADE_COST if _selected_type == StructureType.BARRICADE else TRAP_COST
	for item_id: String in cost:
		InventoryManager.remove_item(item_id, cost[item_id] as int)

	var structure: Node2D = _spawn_structure(_selected_type)
	if structure == null:
		return

	_built_structure = structure
	_is_built = true
	_update_visual()
	_refresh_prompt()
	SaveManager.register_fortification_spot_state(serialize_build_state())

	var type_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
	SfxManager.play_at("plant_placed", global_position)
	_show_build_popup("%s built!" % type_name)
	print("[FortificationSpot] Built %s at %s (%s)" % [type_name, spot_label, global_position])


func _spawn_structure(type: StructureType) -> Node2D:
	var scene_path: String = BARRICADE_SCENE if type == StructureType.BARRICADE else TRAP_SCENE
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("[FortificationSpot] Could not load scene: %s" % scene_path)
		return null

	var structure: Node2D = scene.instantiate() as Node2D
	structure.global_position = global_position
	if barricade_sideways and type == StructureType.BARRICADE:
		structure.rotation = PI / 2.0
	var ysort: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	if ysort != null:
		ysort.add_child(structure)
	else:
		get_tree().current_scene.add_child(structure)
	return structure


func serialize_build_state() -> Dictionary:
	var built_item_id: String = _get_selected_item_id() if _is_built else ""
	var current_hp: int = 0
	if is_instance_valid(_built_structure) and _built_structure.get("_current_hp") != null:
		current_hp = int(_built_structure.get("_current_hp"))
	return {
		"spot_id": _get_spot_id(),
		"spot_type": "fortification",
		"is_built": _is_built,
		"built_item_id": built_item_id,
		"current_hp": current_hp,
	}


func apply_build_state(state: Dictionary) -> void:
	_cleanup_structure(false)
	var built_item_id: String = str(state.get("built_item_id", ""))
	if not bool(state.get("is_built", false)) or built_item_id.is_empty():
		_update_visual()
		if _player_in_range and _has_interaction_focus():
			_refresh_prompt()
		return

	var type: StructureType = _item_id_to_type(built_item_id)
	_selected_type = type
	var structure: Node2D = _spawn_structure(type)
	if structure == null:
		return
	var saved_hp: int = int(state.get("current_hp", 0))
	if saved_hp > 0 and structure.get("_current_hp") != null:
		structure.set("_current_hp", saved_hp)
		if structure.has_method("_update_hp_bar"):
			structure.call("_update_hp_bar")
	_built_structure = structure
	_is_built = true
	_update_visual()
	if _player_in_range and _has_interaction_focus():
		_refresh_prompt()


func _cancel_build() -> void:
	_is_building = false
	_build_progress = 0.0
	_set_progress_visible(false)
	if _player_in_range and _has_interaction_focus() and not _is_built and not DayNightCycle.is_night():
		_refresh_prompt()


func _cleanup_structure(update_saved_state: bool = true) -> void:
	if is_instance_valid(_built_structure):
		_built_structure.queue_free()
	_built_structure = null
	_is_built = false
	_update_visual()
	if _player_in_range and _has_interaction_focus():
		_refresh_prompt()
	if update_saved_state:
		SaveManager.register_fortification_spot_state(serialize_build_state())


func _apply_runtime_state() -> void:
	apply_build_state(SaveManager.get_fortification_spot_state(_get_spot_id()))


func _get_spot_id() -> String:
	if not String(spot_id).is_empty():
		return String(spot_id)
	return name


func _get_selected_item_id() -> String:
	return "thorn_barricade" if _selected_type == StructureType.BARRICADE else "spore_trap"


func _item_id_to_type(item_id: String) -> StructureType:
	if item_id == "spore_trap":
		return StructureType.TRAP
	return StructureType.BARRICADE


func _update_visual() -> void:
	if not is_instance_valid(_visual):
		return
	if _is_built:
		_visual.texture = buildable_texture
		_visual.modulate = Color(0.5, 0.5, 0.5, 0.5)
		return
	_visual.texture = buildable_texture if _can_build_selected_type() else unbuildable_texture
	_visual.modulate = Color.WHITE


func _refresh_prompt() -> void:
	_update_visual()
	if _is_built:
		var built_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
		_show_prompt(
			"%s Ready" % built_name,
			spot_label,
			"",
			"Clears at dawn",
			Color(0.45, 0.95, 0.58, 1.0),
			PROMPT_STATUS_SUCCESS
		)
		return
	var type_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
	var cost_str: String = _get_cost_string()
	var day_req: int = _get_selected_min_day()
	if DayNightCycle.day_count < day_req:
		_show_prompt(
			"Build %s" % type_name,
			"Requires Day %d" % day_req,
			"",
			"< / >  or  Scroll  \u00b7  Switch type",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
		return
	if not _can_afford():
		_show_prompt(
			"Build %s" % type_name,
			"Need: %s" % cost_str,
			"Hold E",
			"< / >  or  Scroll  \u00b7  Switch type  \u00b7  Not enough materials",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
	else:
		_show_prompt(
			"Build %s" % type_name,
			"Cost: %s" % cost_str,
			"Hold E",
			"< / >  or  Scroll  \u00b7  Switch type",
			Color(1.0, 0.78, 0.28, 1.0)
		)


func _get_cost_string() -> String:
	var cost: Dictionary = BARRICADE_COST if _selected_type == StructureType.BARRICADE else TRAP_COST
	var parts: PackedStringArray = PackedStringArray()
	for item_id: String in cost:
		parts.append("%dx %s" % [cost[item_id], ItemDatabase.get_display_name(item_id)])
	return ", ".join(parts)


func _cycle_type(direction: int) -> void:
	var count: int = StructureType.size()
	_selected_type = StructureType.values()[(_selected_type + direction + count) % count]
	_update_visual()
	if _player_in_range and _has_interaction_focus():
		_refresh_prompt()


func _show_build_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-48.0, -32.0)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(label.queue_free)
