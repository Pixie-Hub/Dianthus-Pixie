class_name GardenStructureManager
extends Node

signal storage_upgraded(new_tier: int)
signal watchtower_constructed

# Storage Shed: tier 0=none, 1=30→45 slots, 2=45→60 slots
# Costs per tier: { min_day, cost_stone, cost_sap, slots }
const STORAGE_TIERS: Array[Dictionary] = [
	{ "min_day": 3,  "cost_stone": 10, "cost_sap": 4,  "slots": 45 },
	{ "min_day": 8,  "cost_stone": 16, "cost_sap": 8,  "slots": 60 },
]
# Watchtower cost
const WATCHTOWER_MIN_DAY: int = 5
const WATCHTOWER_COST_STONE: int = 14
const WATCHTOWER_COST_SAP: int = 6

var storage_tier: int = 0
var watchtower_built: bool = false


func _ready() -> void:
	_apply_inventory_slots()


func _apply_inventory_slots() -> void:
	if InventoryManager.has_method("set_max_slots"):
		var target_slots: int = 30
		if storage_tier >= 1 and storage_tier <= STORAGE_TIERS.size():
			target_slots = int(STORAGE_TIERS[storage_tier - 1]["slots"])
		InventoryManager.set_max_slots(target_slots)


func can_build_storage() -> bool:
	if storage_tier >= STORAGE_TIERS.size():
		return false
	var tier: Dictionary = STORAGE_TIERS[storage_tier]
	if not DayNightCycle.is_day():
		return false
	if DayNightCycle.day_count < int(tier["min_day"]):
		return false
	if InventoryManager.get_total_count("stone") < int(tier["cost_stone"]):
		return false
	if InventoryManager.get_total_count("verdant_sap") < int(tier["cost_sap"]):
		return false
	return true


func build_storage() -> bool:
	if not can_build_storage():
		return false
	var tier: Dictionary = STORAGE_TIERS[storage_tier]
	InventoryManager.remove_item("stone", int(tier["cost_stone"]))
	InventoryManager.remove_item("verdant_sap", int(tier["cost_sap"]))
	storage_tier += 1
	_apply_inventory_slots()
	storage_upgraded.emit(storage_tier)
	print("[GardenStructureMgr] Storage upgraded to tier %d (%d slots)" % [
		storage_tier, int(STORAGE_TIERS[storage_tier - 1]["slots"])])
	return true


func can_build_watchtower() -> bool:
	if watchtower_built:
		return false
	if not DayNightCycle.is_day():
		return false
	if DayNightCycle.day_count < WATCHTOWER_MIN_DAY:
		return false
	if InventoryManager.get_total_count("stone") < WATCHTOWER_COST_STONE:
		return false
	if InventoryManager.get_total_count("verdant_sap") < WATCHTOWER_COST_SAP:
		return false
	return true


func build_watchtower() -> bool:
	if not can_build_watchtower():
		return false
	InventoryManager.remove_item("stone", WATCHTOWER_COST_STONE)
	InventoryManager.remove_item("verdant_sap", WATCHTOWER_COST_SAP)
	watchtower_built = true
	watchtower_constructed.emit()
	_notify_map_view_watchtower()
	print("[GardenStructureMgr] Watchtower built!")
	return true


func _notify_map_view_watchtower() -> void:
	if not watchtower_built:
		return
	var map_view: Node = get_tree().current_scene.find_child("Minimap", true, false)
	if map_view != null and map_view.has_method("set_watchtower_active"):
		map_view.set_watchtower_active(true)


func get_storage_next_tier_data() -> Dictionary:
	if storage_tier >= STORAGE_TIERS.size():
		return {}
	return STORAGE_TIERS[storage_tier]


func serialize() -> Dictionary:
	return {
		"storage_tier": storage_tier,
		"watchtower_built": watchtower_built,
	}


func deserialize(data: Dictionary) -> void:
	storage_tier = int(data.get("storage_tier", 0))
	watchtower_built = bool(data.get("watchtower_built", false))
	_apply_inventory_slots()
	if watchtower_built:
		call_deferred("_notify_map_view_watchtower")
