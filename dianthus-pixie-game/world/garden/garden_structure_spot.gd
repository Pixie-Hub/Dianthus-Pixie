class_name GardenStructureSpot
extends Area2D

const BUILD_TIME: float = 4.0

@export var structure_id: StringName = &"storage_shed"

var _player_in_range: bool = false
var _build_progress: float = 0.0
var _is_building: bool = false
var _struct_mgr: GardenStructureManager = null

@onready var _prompt_label: Label = %PromptLabel
@onready var _progress_bg: ColorRect = %ProgressBg
@onready var _progress_bar: ColorRect = %ProgressBar
@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_find_struct_mgr()
	SaveManager.load_completed.connect(_on_load_completed)
	_refresh_prompt()


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
		_refresh_prompt()


func _refresh_visual() -> void:
	if not is_instance_valid(_visual):
		return
	if _is_already_built():
		_visual.color = Color(0.6, 0.45, 0.2, 0.9)
	else:
		_visual.color = Color(0.3, 0.3, 0.55, 0.8)


func _refresh_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	if _struct_mgr == null:
		_prompt_label.visible = false
		return
	var display_name: String = "Storage Shed" if structure_id == &"storage_shed" else "Watchtower"
	if _is_already_built() and structure_id == &"watchtower":
		_prompt_label.text = "%s\n[Built]" % display_name
		_prompt_label.visible = _player_in_range
		return
	if structure_id == &"storage_shed" and _struct_mgr.storage_tier >= _struct_mgr.STORAGE_TIERS.size():
		_prompt_label.text = "Storage Shed\n[Max Level]"
		_prompt_label.visible = _player_in_range
		return
	if not DayNightCycle.is_day():
		_prompt_label.text = "%s\n(DAY only)" % display_name
		_prompt_label.visible = _player_in_range
		return
	var cost_stone: int = 0
	var cost_sap: int = 0
	var day_req: int = 1
	if structure_id == &"storage_shed":
		var next: Dictionary = _struct_mgr.get_storage_next_tier_data()
		if next.is_empty():
			_prompt_label.visible = false
			return
		cost_stone = int(next.get("cost_stone", 0))
		cost_sap = int(next.get("cost_sap", 0))
		day_req = int(next.get("min_day", 1))
	else:
		cost_stone = _struct_mgr.WATCHTOWER_COST_STONE
		cost_sap = _struct_mgr.WATCHTOWER_COST_SAP
		day_req = _struct_mgr.WATCHTOWER_MIN_DAY
	if DayNightCycle.day_count < day_req:
		_prompt_label.text = "%s\n(requires Day %d)" % [display_name, day_req]
		_prompt_label.visible = _player_in_range
		return
	var stone_have: int = InventoryManager.get_total_count("stone")
	var sap_have: int = InventoryManager.get_total_count("verdant_sap")
	if _can_build_now():
		_prompt_label.text = "Hold E: Build %s\nStone %d/%d  Sap %d/%d" % [
			display_name, stone_have, cost_stone, sap_have, cost_sap]
	else:
		_prompt_label.text = "Build %s\nNeed Stone %d/%d  Sap %d/%d" % [
			display_name, stone_have, cost_stone, sap_have, cost_sap]
	_prompt_label.visible = _player_in_range


func _set_progress_visible(visible_flag: bool) -> void:
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = visible_flag
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = visible_flag


func _update_progress_bar() -> void:
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
