extends Node

signal plant_discovered(plant_id: String)
signal enemy_discovered(enemy_id: String)

const EnemyCatalog = preload("res://ui/codex/enemy_registry.gd")

var discovered_plants: Dictionary = {}
var discovered_enemies: Dictionary = {}


func _ready() -> void:
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


func discover_enemy(enemy_id: String, play_sfx: bool = true) -> void:
	if enemy_id.is_empty() or discovered_enemies.has(enemy_id) or not EnemyCatalog.has_enemy(enemy_id):
		return
	discovered_enemies[enemy_id] = true
	if play_sfx:
		SfxManager.play("codex_unlocked")
	enemy_discovered.emit(enemy_id)
	print("[CodexManager] Enemy discovered: %s" % enemy_id)


func is_plant_discovered(plant_id: String) -> bool:
	return discovered_plants.get(plant_id, false)


func is_enemy_discovered(enemy_id: String) -> bool:
	return discovered_enemies.get(enemy_id, false)


func get_discovered_count() -> int:
	return discovered_plants.size()


func get_total_count() -> int:
	return PlantRegistry.get_all_plant_ids().size()


func get_enemy_discovered_count() -> int:
	return discovered_enemies.size()


func get_enemy_total_count() -> int:
	return EnemyCatalog.get_enemy_ids().size()


func reset_state() -> void:
	discovered_plants = {}
	discovered_enemies = {}
	print("[CodexManager] State reset.")


func serialize() -> Dictionary:
	return {
		"discovered_plants": discovered_plants.duplicate(),
		"discovered_enemies": discovered_enemies.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	discovered_plants = {}
	discovered_enemies = {}
	var disc: Variant = data.get("discovered_plants", {})
	if disc is Dictionary:
		for pid: String in (disc as Dictionary):
			if (disc as Dictionary)[pid]:
				discovered_plants[pid] = true
	var enemy_disc: Variant = data.get("discovered_enemies", {})
	if enemy_disc is Dictionary:
		for enemy_id: String in (enemy_disc as Dictionary):
			if (enemy_disc as Dictionary)[enemy_id] and EnemyCatalog.has_enemy(enemy_id):
				discovered_enemies[enemy_id] = true


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
