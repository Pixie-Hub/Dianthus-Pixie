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

@export var spot_label: String = "Fortification Spot"
@export var barricade_sideways: bool = false

var _is_built: bool = false
var _built_structure: Node = null
var _selected_type: StructureType = StructureType.BARRICADE

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	super._ready()
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_update_visual()


func _process(delta: float) -> void:
	if _is_built:
		if not is_instance_valid(_built_structure):
			_is_built = false
			_built_structure = null
			_update_visual()
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
		_hide_prompt()


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

	var scene_path: String = BARRICADE_SCENE if _selected_type == StructureType.BARRICADE else TRAP_SCENE
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("[FortificationSpot] Could not load scene: %s" % scene_path)
		return

	var structure: Node2D = scene.instantiate() as Node2D
	structure.global_position = global_position
	if barricade_sideways and _selected_type == StructureType.BARRICADE:
		structure.rotation = PI / 2.0
	var ysort: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	if ysort != null:
		ysort.add_child(structure)
	else:
		get_tree().current_scene.add_child(structure)

	_built_structure = structure
	_is_built = true
	_update_visual()
	_refresh_prompt()

	var type_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
	SfxManager.play_at("plant_placed", global_position)
	_show_build_popup("%s built!" % type_name)
	print("[FortificationSpot] Built %s at %s (%s)" % [type_name, spot_label, global_position])


func _cancel_build() -> void:
	_is_building = false
	_build_progress = 0.0
	_set_progress_visible(false)
	if _player_in_range and _has_interaction_focus() and not _is_built and not DayNightCycle.is_night():
		_refresh_prompt()


func _cleanup_structure() -> void:
	if is_instance_valid(_built_structure):
		_built_structure.queue_free()
	_built_structure = null
	_is_built = false
	_update_visual()
	if _player_in_range and _has_interaction_focus():
		_refresh_prompt()


func _update_visual() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.modulate = Color(0.5, 0.5, 0.5, 0.5) if _is_built else Color.WHITE


func _refresh_prompt() -> void:
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
