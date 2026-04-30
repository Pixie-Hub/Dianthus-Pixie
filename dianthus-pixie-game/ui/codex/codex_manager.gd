extends Node

signal plant_discovered(plant_id: String)

var discovered_plants: Dictionary = {}


func _ready() -> void:
	discover_plant("bougainvillea", false)
	BreedingManager.breed_succeeded.connect(_on_breed_succeeded)
	InventoryManager.item_added.connect(_on_item_added)


func discover_plant(plant_id: String, play_sfx: bool = true) -> void:
	if plant_id.is_empty() or discovered_plants.has(plant_id):
		return
	discovered_plants[plant_id] = true
	if play_sfx:
		SfxManager.play("codex_unlocked")
	plant_discovered.emit(plant_id)
	print("[CodexManager] Discovered: %s" % plant_id)


func is_plant_discovered(plant_id: String) -> bool:
	return discovered_plants.get(plant_id, false)


func get_discovered_count() -> int:
	return discovered_plants.size()


func get_total_count() -> int:
	return PlantRegistry.get_all_plant_ids().size()


func serialize() -> Dictionary:
	return {"discovered_plants": discovered_plants.duplicate()}


func deserialize(data: Dictionary) -> void:
	discovered_plants = {}
	var disc: Variant = data.get("discovered_plants", {})
	if disc is Dictionary:
		for pid: String in (disc as Dictionary):
			if (disc as Dictionary)[pid]:
				discovered_plants[pid] = true
	discover_plant("bougainvillea", false)


func _on_breed_succeeded(combo_id: String, _result_item_id: String) -> void:
	for pid: String in PlantRegistry.get_all_plant_ids():
		var data: Dictionary = PlantRegistry.get_plant(pid)
		if str(data.get("combo_id", "")) == combo_id:
			discover_plant(pid)
			break


func _on_item_added(item_id: String, _amount: int) -> void:
	if not item_id.ends_with("_seed"):
		return
	var plant_id: String = item_id.trim_suffix("_seed")
	if PlantRegistry.PLANTS.has(plant_id):
		discover_plant(plant_id)
