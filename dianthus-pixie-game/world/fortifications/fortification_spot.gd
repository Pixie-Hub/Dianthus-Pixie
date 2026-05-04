class_name FortificationSpot
extends Area2D

const INTERACT_RADIUS: float = 28.0
const BARRICADE_BUILD_TIME: float = 4.0
const TRAP_BUILD_TIME: float = 3.0

const BARRICADE_COST: Dictionary = {"petal_shard": 3, "verdant_sap": 2}
const TRAP_COST: Dictionary = {"verdant_sap": 2, "moonspore": 1}

const BARRICADE_SCENE: String = "res://world/fortifications/thorn_barricade.tscn"
const TRAP_SCENE: String = "res://world/fortifications/spore_trap.tscn"
const INTERACTION_PROMPT_SCENE: PackedScene = preload("res://ui/components/interaction_prompt.tscn")
const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const PROMPT_STATUS_SUCCESS: int = 3

enum StructureType { BARRICADE, TRAP }

@export var spot_label: String = "Fortification Spot"
@export var barricade_sideways: bool = false

var _player_in_range: bool = false
var _is_built: bool = false
var _built_structure: Node = null
var _selected_type: StructureType = StructureType.BARRICADE
var _is_building: bool = false
var _build_timer: float = 0.0

@onready var _visual: ColorRect = $Visual
@onready var _prompt_label: Label = %PromptLabel
@onready var _progress_bg: ColorRect = %ProgressBg
@onready var _progress_bar: ColorRect = %ProgressBar

var _interaction_prompt = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_setup_interaction_prompt()
	_update_visual()
	_hide_prompt()


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

	if not _player_in_range or not Input.is_action_pressed("interact"):
		_cancel_build()
		return

	if not _can_afford():
		_cancel_build()
		_refresh_prompt()
		return

	_build_timer += delta
	var build_time: float = BARRICADE_BUILD_TIME if _selected_type == StructureType.BARRICADE else TRAP_BUILD_TIME
	_update_progress_bar(_build_timer / build_time)
	var type_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
	_show_prompt(
		"Building %s" % type_name,
		"Progress: %.0f%%" % ((_build_timer / build_time) * 100.0),
		"Hold E",
		"Release E to cancel",
		Color(1.0, 0.78, 0.28, 1.0),
		PROMPT_STATUS_NORMAL,
		_build_timer / build_time
	)

	if _build_timer >= build_time:
		_finish_build()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _is_built or DayNightCycle.is_night():
		return

	if event.is_action_pressed("interact") and not _is_building:
		_is_building = true
		_build_timer = 0.0
		_update_progress_bar(0.0)
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


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_cancel_build()
		_hide_prompt()


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


func _finish_build() -> void:
	_is_building = false
	_build_timer = 0.0
	_update_progress_bar(0.0)

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
	_build_timer = 0.0
	_update_progress_bar(0.0)
	if _player_in_range and not _is_built and not DayNightCycle.is_night():
		_refresh_prompt()


func _cleanup_structure() -> void:
	if is_instance_valid(_built_structure):
		_built_structure.queue_free()
	_built_structure = null
	_is_built = false
	_update_visual()
	if _player_in_range:
		_refresh_prompt()


func _update_visual() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.modulate = Color(0.5, 0.5, 0.5, 0.5) if _is_built else Color.WHITE


func _setup_interaction_prompt() -> void:
	if is_instance_valid(_prompt_label):
		_prompt_label.visible = false
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = false
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = false

	_interaction_prompt = get_node_or_null("%InteractionPrompt")
	if _interaction_prompt == null:
		_interaction_prompt = INTERACTION_PROMPT_SCENE.instantiate()
		_interaction_prompt.name = "InteractionPrompt"
		add_child(_interaction_prompt)


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
	if not _can_afford():
		_show_prompt(
			"Build %s" % type_name,
			"Need: %s" % cost_str,
			"Hold E",
			"Not enough materials",
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


func _show_prompt(title: String, body: String = "", key_text: String = "", hint: String = "", accent: Color = Color(1.0, 0.78, 0.28, 1.0), status: int = PROMPT_STATUS_NORMAL, progress: float = -1.0) -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.show_interaction(title, body, key_text, hint, accent, status, progress)
		return
	if is_instance_valid(_prompt_label):
		var lines: PackedStringArray = PackedStringArray([title])
		if not body.is_empty():
			lines.append(body)
		if not hint.is_empty():
			lines.append(hint)
		_prompt_label.text = "\n".join(lines)
		_prompt_label.visible = true


func _hide_prompt() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.hide_prompt()
	if is_instance_valid(_prompt_label):
		_prompt_label.text = ""
		_prompt_label.visible = false
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = false
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = false


func _get_cost_string() -> String:
	var cost: Dictionary = BARRICADE_COST if _selected_type == StructureType.BARRICADE else TRAP_COST
	var parts: PackedStringArray = PackedStringArray()
	for item_id: String in cost:
		parts.append("%dx %s" % [cost[item_id], ItemDatabase.get_display_name(item_id)])
	return ", ".join(parts)


func _cycle_type(direction: int) -> void:
	var count: int = StructureType.size()
	_selected_type = StructureType.values()[(_selected_type + direction + count) % count]
	if _player_in_range:
		_refresh_prompt()


func _update_progress_bar(ratio: float) -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.set_progress(ratio)
		return
	if not is_instance_valid(_progress_bar) or not is_instance_valid(_progress_bg):
		return
	_progress_bar.size.x = _progress_bg.size.x * clampf(ratio, 0.0, 1.0)
	_progress_bar.visible = ratio > 0.0
	_progress_bg.visible = ratio > 0.0


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
