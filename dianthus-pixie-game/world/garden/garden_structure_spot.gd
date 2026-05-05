class_name GardenStructureSpot
extends Area2D

const BUILD_TIME: float = 4.0
const INTERACTION_PROMPT_SCENE: PackedScene = preload("res://ui/components/interaction_prompt.tscn")
const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const PROMPT_STATUS_SUCCESS: int = 3

@export var structure_id: StringName = &"storage_shed"

var _player_in_range: bool = false
var _build_progress: float = 0.0
var _is_building: bool = false
var _struct_mgr: GardenStructureManager = null

@onready var _prompt_label: Label = %PromptLabel
@onready var _progress_bg: ColorRect = %ProgressBg
@onready var _progress_bar: ColorRect = %ProgressBar
@onready var _visual: ColorRect = $Visual

var _interaction_prompt = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_find_struct_mgr()
	SaveManager.load_completed.connect(_on_load_completed)
	_setup_interaction_prompt()
	_hide_prompt()


func _find_struct_mgr() -> void:
	_struct_mgr = get_tree().current_scene.find_child("GardenStructureManager", true, false) as GardenStructureManager


func _on_load_completed(_ok: bool) -> void:
	_find_struct_mgr()
	_refresh_visual()
	_refresh_prompt()


func _process(delta: float) -> void:
	if not _player_in_range or not _is_building:
		return
	if not _can_build_now():
		_is_building = false
		_build_progress = 0.0
		_set_progress_visible(false)
		_refresh_prompt()
		return
	_build_progress += delta / BUILD_TIME
	_update_progress_bar()
	var display_name: String = "Storage Shed" if structure_id == &"storage_shed" else "Watchtower"
	_show_prompt(
		"Building %s" % display_name,
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
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		if _can_build_now():
			_is_building = true
			_build_progress = 0.0
			_set_progress_visible(true)
			get_viewport().set_input_as_handled()
	elif event.is_action_released("interact"):
		if _is_building:
			_is_building = false
			_build_progress = 0.0
			_set_progress_visible(false)


func _can_build_now() -> bool:
	if _struct_mgr == null:
		return false
	if structure_id == &"storage_shed":
		return _struct_mgr.can_build_storage()
	elif structure_id == &"watchtower":
		return _struct_mgr.can_build_watchtower()
	return false


func _is_already_built() -> bool:
	if _struct_mgr == null:
		return false
	if structure_id == &"storage_shed":
		return _struct_mgr.storage_tier >= _struct_mgr.STORAGE_TIERS.size()
	elif structure_id == &"watchtower":
		return _struct_mgr.watchtower_built
	return false


func _finish_build() -> void:
	_is_building = false
	_build_progress = 0.0
	_set_progress_visible(false)
	var success: bool = false
	if structure_id == &"storage_shed":
		success = _struct_mgr.build_storage()
	elif structure_id == &"watchtower":
		success = _struct_mgr.build_watchtower()
	if success:
		SfxManager.play("fortification_built")
		var label: String = "Storage Shed upgraded!" if structure_id == &"storage_shed" else "Watchtower built!"
		_show_popup(label)
		_refresh_visual()
	_refresh_prompt()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _struct_mgr == null:
			_find_struct_mgr()
		_player_in_range = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if _is_building:
			_is_building = false
			_build_progress = 0.0
			_set_progress_visible(false)
		_hide_prompt()


func _refresh_visual() -> void:
	if not is_instance_valid(_visual):
		return
	if _is_already_built():
		_visual.color = Color(0.6, 0.45, 0.2, 0.9)
	else:
		_visual.color = Color(0.3, 0.3, 0.55, 0.8)


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
	if _struct_mgr == null:
		_hide_prompt()
		return
	var display_name: String = "Storage Shed" if structure_id == &"storage_shed" else "Watchtower"
	if _is_already_built() and structure_id == &"watchtower":
		_show_prompt(
			"%s Ready" % display_name,
			"[Built]",
			"",
			"",
			Color(0.45, 0.95, 0.58, 1.0),
			PROMPT_STATUS_SUCCESS
		)
		return
	if structure_id == &"storage_shed" and _struct_mgr.storage_tier >= _struct_mgr.STORAGE_TIERS.size():
		_show_prompt(
			"Storage Shed",
			"[Max Level]",
			"",
			"",
			Color(0.45, 0.95, 0.58, 1.0),
			PROMPT_STATUS_SUCCESS
		)
		return
	if not DayNightCycle.is_day():
		_show_prompt(
			"%s" % display_name,
			"(DAY only)",
			"",
			"",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
		return
	var cost_stone: int = 0
	var cost_sap: int = 0
	var day_req: int = 1
	if structure_id == &"storage_shed":
		var next: Dictionary = _struct_mgr.get_storage_next_tier_data()
		if next.is_empty():
			_hide_prompt()
			return
		cost_stone = int(next.get("cost_stone", 0))
		cost_sap = int(next.get("cost_sap", 0))
		day_req = int(next.get("min_day", 1))
	else:
		cost_stone = _struct_mgr.WATCHTOWER_COST_STONE
		cost_sap = _struct_mgr.WATCHTOWER_COST_SAP
		day_req = _struct_mgr.WATCHTOWER_MIN_DAY
	if DayNightCycle.day_count < day_req:
		_show_prompt(
			"%s" % display_name,
			"Requires Day %d" % day_req,
			"",
			"",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
		return
	var stone_have: int = InventoryManager.get_total_count("stone")
	var sap_have: int = InventoryManager.get_total_count("verdant_sap")
	var cost_str: String = "Stone %d/%d  Sap %d/%d" % [stone_have, cost_stone, sap_have, cost_sap]
	if _can_build_now():
		_show_prompt(
			"Build %s" % display_name,
			"Cost: %s" % cost_str,
			"Hold E",
			"",
			Color(1.0, 0.78, 0.28, 1.0)
		)
	else:
		_show_prompt(
			"Build %s" % display_name,
			"Need: %s" % cost_str,
			"Hold E",
			"Not enough materials",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
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


func _set_progress_visible(visible_flag: bool) -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.set_progress(0.0 if visible_flag else -1.0)
		return
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = visible_flag
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = visible_flag


func _update_progress_bar() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.set_progress(_build_progress)
		return
	if not is_instance_valid(_progress_bar):
		return
	var bg_width: float = 32.0
	if is_instance_valid(_progress_bg):
		bg_width = _progress_bg.size.x
	_progress_bar.size.x = bg_width * clampf(_build_progress, 0.0, 1.0)


func _show_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	label.position = Vector2(-50, -52)
	add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)
