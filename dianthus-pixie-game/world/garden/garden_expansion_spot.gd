class_name GardenExpansionSpot
extends BaseBuildSpot

const BUILD_TIME: float = 3.0

@export var buildable_texture: Texture2D
@export var unbuildable_texture: Texture2D

var _placement_manager: Node = null

@onready var _visual: Sprite2D = $Visual


func _ready() -> void:
	super._ready()
	_find_placement_manager()
	SaveManager.load_completed.connect(_on_load_completed)
	_refresh_visual()


func _find_placement_manager() -> void:
	_placement_manager = get_tree().current_scene.find_child("PlantPlacementManager", true, false)


func _on_load_completed(_ok: bool) -> void:
	_find_placement_manager()
	_refresh_visual()
	_refresh_prompt()


func _can_interact() -> bool:
	return _placement_manager != null \
		and _placement_manager.has_method("can_expand") \
		and _placement_manager.call("can_expand")


func _get_build_time() -> float:
	return BUILD_TIME


func _get_build_display_name() -> String:
	return "Garden"


func _get_build_accent_color() -> Color:
	return Color(0.3, 1.0, 0.4, 1.0)


func _on_player_entered() -> void:
	if _placement_manager == null:
		_find_placement_manager()


func _on_interact_completed() -> void:
	if _placement_manager != null and _placement_manager.has_method("expand_garden"):
		_placement_manager.call("expand_garden")
	SfxManager.play("fortification_built")
	_show_popup("+1 Garden Tier!", Color(0.3, 1.0, 0.4))
	_refresh_visual()
	_refresh_prompt()


func _refresh_visual() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.texture = buildable_texture if _can_interact() else unbuildable_texture
	_visual.modulate = Color.WHITE


func _refresh_prompt() -> void:
	_refresh_visual()
	if not _player_in_range:
		_hide_prompt()
		return
	if _placement_manager == null:
		_hide_prompt()
		return
	var tier: int = int(_placement_manager.get("expansion_tier"))
	var max_tiers: int = _placement_manager.get("EXPANSION_TIERS").size() if _placement_manager.get("EXPANSION_TIERS") != null else 4
	if tier >= max_tiers:
		_show_prompt(
			"Garden Fully Expanded",
			"",
			"",
			"",
			Color(0.45, 0.95, 0.58, 1.0),
			PROMPT_STATUS_SUCCESS
		)
		return
	var next_data: Dictionary = _placement_manager.call("get_next_tier_data")
	if next_data.is_empty():
		_show_prompt(
			"Garden Fully Expanded",
			"",
			"",
			"",
			Color(0.45, 0.95, 0.58, 1.0),
			PROMPT_STATUS_SUCCESS
		)
		return
	var day_req: int = int(next_data.get("min_day", 1))
	var sap_cost: int = int(next_data.get("cost_verdant_sap", 0))
	var stone_cost: int = int(next_data.get("cost_stone", 0))
	var sap_have: int = InventoryManager.get_total_count("verdant_sap")
	var stone_have: int = InventoryManager.get_total_count("stone")
	if not DayNightCycle.is_day():
		_show_prompt(
			"Expand Garden",
			"(DAY only)",
			"",
			"",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
		return
	if DayNightCycle.day_count < day_req:
		_show_prompt(
			"Expand Garden",
			"Requires Day %d" % day_req,
			"",
			"",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
		return
	var cost_str: String = "Sap %d/%d  Stone %d/%d" % [sap_have, sap_cost, stone_have, stone_cost]
	if _placement_manager.call("can_expand"):
		_show_prompt(
			"Expand Garden",
			"Cost: %s" % cost_str,
			"Hold E",
			"",
			Color(0.3, 1.0, 0.4, 1.0)
		)
	else:
		_show_prompt(
			"Expand Garden",
			"Need: %s" % cost_str,
			"Hold E",
			"Not enough materials",
			Color(1.0, 0.45, 0.25, 1.0),
			PROMPT_STATUS_DISABLED
		)
