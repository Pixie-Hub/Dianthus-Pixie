class_name GardenExpansionSpot
extends Area2D

const INTERACT_RADIUS: float = 32.0
const BUILD_TIME: float = 3.0

var _player_in_range: bool = false
var _build_progress: float = 0.0
var _is_building: bool = false
var _placement_manager: Node = null

@onready var _prompt_label: Label = %PromptLabel
@onready var _progress_bg: ColorRect = %ProgressBg
@onready var _progress_bar: ColorRect = %ProgressBar


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_find_placement_manager()
	SaveManager.load_completed.connect(_on_load_completed)
	_refresh_prompt()


func _find_placement_manager() -> void:
	_placement_manager = get_tree().current_scene.find_child("PlantPlacementManager", true, false)


func _on_load_completed(_ok: bool) -> void:
	_find_placement_manager()
	_refresh_prompt()


func _process(delta: float) -> void:
	if not _player_in_range or not _is_building:
		return
	if _placement_manager == null or not _placement_manager.has_method("can_expand"):
		_is_building = false
		_set_progress_visible(false)
		return
	if not _placement_manager.call("can_expand"):
		_is_building = false
		_build_progress = 0.0
		_set_progress_visible(false)
		_refresh_prompt()
		return
	_build_progress += delta / BUILD_TIME
	_update_progress_bar()
	if _build_progress >= 1.0:
		_finish_expand()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		if _placement_manager == null or not _placement_manager.has_method("can_expand"):
			return
		if not _placement_manager.call("can_expand"):
			return
		_is_building = true
		_build_progress = 0.0
		_set_progress_visible(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_released("interact"):
		if _is_building:
			_is_building = false
			_build_progress = 0.0
			_set_progress_visible(false)


func _finish_expand() -> void:
	_is_building = false
	_build_progress = 0.0
	_set_progress_visible(false)
	if _placement_manager != null and _placement_manager.has_method("expand_garden"):
		_placement_manager.call("expand_garden")
	SfxManager.play("fortification_built")
	_show_popup("+1 Garden Tier!")
	_refresh_prompt()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _placement_manager == null:
			_find_placement_manager()
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


func _refresh_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	if _placement_manager == null:
		_prompt_label.text = ""
		_prompt_label.visible = false
		return
	var tier: int = int(_placement_manager.get("expansion_tier"))
	var max_tiers: int = _placement_manager.get("EXPANSION_TIERS").size() if _placement_manager.get("EXPANSION_TIERS") != null else 4
	if tier >= max_tiers:
		_prompt_label.text = "Garden fully expanded"
		_prompt_label.visible = _player_in_range
		return
	var next_data: Dictionary = _placement_manager.call("get_next_tier_data")
	if next_data.is_empty():
		_prompt_label.text = "Garden fully expanded"
		_prompt_label.visible = _player_in_range
		return
	var day_req: int = int(next_data.get("min_day", 1))
	var sap_cost: int = int(next_data.get("cost_verdant_sap", 0))
	var stone_cost: int = int(next_data.get("cost_stone", 0))
	var sap_have: int = InventoryManager.get_total_count("verdant_sap")
	var stone_have: int = InventoryManager.get_total_count("stone")
	if not DayNightCycle.is_day():
		_prompt_label.text = "Expand Garden\n(DAY only)"
		_prompt_label.visible = _player_in_range
		return
	if DayNightCycle.day_count < day_req:
		_prompt_label.text = "Expand Garden\n(requires Day %d)" % day_req
		_prompt_label.visible = _player_in_range
		return
	var sap_ok: String = "%d/%d" % [sap_have, sap_cost]
	var stone_ok: String = "%d/%d" % [stone_have, stone_cost]
	if _placement_manager.call("can_expand"):
		_prompt_label.text = "Hold E: Expand Garden\nSap %s  Stone %s" % [sap_ok, stone_ok]
	else:
		_prompt_label.text = "Expand Garden\nNeed Sap %s  Stone %s" % [sap_ok, stone_ok]
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
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	label.position = Vector2(-40, -48)
	add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 20.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
