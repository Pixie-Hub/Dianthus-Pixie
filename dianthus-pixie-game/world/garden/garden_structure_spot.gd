class_name GardenStructureSpot
extends BaseBuildSpot

const BUILD_TIME: float = 4.0

@export var structure_id: StringName = &"storage_shed"

var _struct_mgr = null

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	super._ready()
	_find_struct_mgr()
	SaveManager.load_completed.connect(_on_load_completed)


func _find_struct_mgr() -> void:
	_struct_mgr = get_tree().current_scene.find_child("GardenStructureManager", true, false)


func _on_load_completed(_ok: bool) -> void:
	_find_struct_mgr()
	_refresh_visual()
	_refresh_prompt()


func _can_interact() -> bool:
	return _can_build_now()


func _get_build_time() -> float:
	return BUILD_TIME


func _get_build_display_name() -> String:
	return "Storage Shed" if structure_id == &"storage_shed" else "Watchtower"


func _get_build_accent_color() -> Color:
	return Color(1.0, 0.78, 0.28, 1.0)


func _on_player_entered() -> void:
	if _struct_mgr == null:
		_find_struct_mgr()


func _on_interact_completed() -> void:
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


func _refresh_visual() -> void:
	if not is_instance_valid(_visual):
		return
	if _is_already_built():
		_visual.color = Color(0.6, 0.45, 0.2, 0.9)
	else:
		_visual.color = Color(0.3, 0.3, 0.55, 0.8)


func _refresh_prompt() -> void:
	if not _player_in_range:
		_hide_prompt()
		return
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
