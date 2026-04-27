extends Node

signal breed_succeeded(combo_id: String, result_item_id: String)
signal breed_failed(reason: String)
signal combo_discovered(combo_id: String)
signal combo_attempted(combo_id: String, success: bool)

const COMBOS: Dictionary = {
	"bunga_api": {
		"input_a": "bougainvillea_extract",
		"input_b": "kecombrang_extract",
		"result_item": "bunga_api_seed",
		"result_plant_scene": "res://plants/entities/bunga_api.tscn",
		"display_name": "Bunga Api",
		"description": "Fire Flower — thorns + fire AoE (7 DMG/tick + 3 burn DMG over 2s).",
	},
	"bunga_bayang": {
		"input_a": "rafflesia_extract",
		"input_b": "shadow_resin",
		"result_item": "bunga_bayang_seed",
		"result_plant_scene": "res://plants/entities/bunga_bayang.tscn",
		"display_name": "Bunga Bayang",
		"description": "Shadow Bloom — slow + night auto-attack zone (4 DMG, 0.7x slow).",
	},
	"melati_emas": {
		"input_a": "verdant_sap",
		"input_b": "dianthus_pollen",
		"result_item": "melati_emas_seed",
		"result_plant_scene": "res://plants/entities/melati_emas.tscn",
		"display_name": "Melati Emas",
		"description": "Golden Jasmine — regen HP (+2/s) and energy (+4/s) in radius.",
	},
	"baja_kuning": {
		"input_a": "kunyit_extract",
		"input_b": "shadow_resin",
		"result_item": "baja_kuning_seed",
		"result_plant_scene": "res://plants/entities/baja_kuning.tscn",
		"display_name": "Baja Kuning",
		"description": "Yellow Iron — armor buff (+30% DR) + counter-attack (25% reflect).",
	},
	# TODO: PLANT-12 — remaining 20 combos
}

var discovered_combos: Dictionary = {}


# --- Public API ---

func find_combo(item_a: String, item_b: String) -> String:
	for combo_id: String in COMBOS:
		var combo: Dictionary = COMBOS[combo_id]
		var ia: String = str(combo.get("input_a", ""))
		var ib: String = str(combo.get("input_b", ""))
		if (item_a == ia and item_b == ib) or (item_a == ib and item_b == ia):
			return combo_id
	return ""


func can_breed(item_a: String, item_b: String) -> bool:
	if item_a == item_b:
		return InventoryManager.has_item(item_a, 2)
	return InventoryManager.has_item(item_a, 1) and InventoryManager.has_item(item_b, 1)


func breed(item_a: String, item_b: String) -> bool:
	if not can_breed(item_a, item_b):
		SfxManager.play("breeding_fail")
		combo_attempted.emit("", false)
		breed_failed.emit("Not enough materials.")
		return false
	SfxManager.play("breeding_start")
	# Consume inputs
	InventoryManager.remove_item(item_a, 1)
	InventoryManager.remove_item(item_b, 1)
	var combo_id: String = find_combo(item_a, item_b)
	if combo_id.is_empty():
		print("[BreedingManager] Unknown combination — resources lost.")
		SfxManager.play("breeding_critical_fail")
		combo_attempted.emit("", false)
		breed_failed.emit("Unknown combination — resources lost.")
		return true  # Resources still consumed per GDD §7.2
	# TODO: MINI-01 — minigame score determines quality tier; always Biasa for now
	var result_item: String = str(COMBOS[combo_id].get("result_item", ""))
	InventoryManager.add_item(result_item, 1)
	var first_discovery: bool = not discovered_combos.has(combo_id)
	discovered_combos[combo_id] = true
	if first_discovery:
		SfxManager.play("combo_discovered")
		combo_discovered.emit(combo_id)
	SfxManager.play("breeding_success")
	combo_attempted.emit(combo_id, true)
	breed_succeeded.emit(combo_id, result_item)
	print("[BreedingManager] Bred: %s → %s" % [combo_id, result_item])
	return true


func is_discovered(combo_id: String) -> bool:
	return discovered_combos.get(combo_id, false)


func get_combo(combo_id: String) -> Dictionary:
	return COMBOS.get(combo_id, {})


func get_all_combo_ids() -> Array:
	return COMBOS.keys()


func get_display_name(combo_id: String) -> String:
	if not is_discovered(combo_id):
		return "???"
	return str(COMBOS.get(combo_id, {}).get("display_name", combo_id))


# --- Serialization ---

func serialize() -> Dictionary:
	return {"discovered": discovered_combos.duplicate()}


func deserialize(data: Dictionary) -> void:
	discovered_combos = {}
	var disc: Variant = data.get("discovered", {})
	if disc is Dictionary:
		for cid: String in (disc as Dictionary):
			if (disc as Dictionary)[cid]:
				discovered_combos[cid] = true
