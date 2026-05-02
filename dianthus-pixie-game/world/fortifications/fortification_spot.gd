class_name FortificationSpot
extends Area2D

const INTERACT_RADIUS: float = 28.0
const BARRICADE_BUILD_TIME: float = 4.0
const TRAP_BUILD_TIME: float = 3.0

const BARRICADE_COST: Dictionary = {"petal_shard": 3, "verdant_sap": 2}
const TRAP_COST: Dictionary = {"verdant_sap": 2, "moonspore": 1}

const BARRICADE_SCENE: String = "res://world/fortifications/thorn_barricade.tscn"
const TRAP_SCENE: String = "res://world/fortifications/spore_trap.tscn"

enum StructureType { BARRICADE, TRAP }

@export var spot_label: String = "Fortification Spot"

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


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
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
	_set_prompt_text("Building %s... %.0f%%" % [type_name, (_build_timer / build_time) * 100.0])

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


func _refresh_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	if _is_built:
		_prompt_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		_set_prompt_text("[Fortified — %s]" % spot_label)
		return
	var type_name: String = "Thorn Barricade" if _selected_type == StructureType.BARRICADE else "Spore Trap"
	var cost_str: String = _get_cost_string()
	if not _can_afford():
		_prompt_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4, 1.0))
		_set_prompt_text("[E] Build %s (%s)\nNot enough resources" % [type_name, cost_str])
	else:
		_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1.0))
		_set_prompt_text("[Hold E] Build %s (%s)\n[,/.] or [Scroll] Switch type" % [type_name, cost_str])


func _set_prompt_text(text: String) -> void:
	if not is_instance_valid(_prompt_label):
		return
	_prompt_label.text = text
	_prompt_label.visible = true


func _hide_prompt() -> void:
	if is_instance_valid(_prompt_label):
		_prompt_label.text = ""
		_prompt_label.visible = false


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
