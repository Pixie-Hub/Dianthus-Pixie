extends Node

signal weapon_crafted(weapon_id: String)
signal craft_failed(reason: String)

const WEAPON_DATA_PATHS: Dictionary = {
	"thorn_sword":       "res://combat/weapons/thorn_sword/thorn_sword_data.tres",
	"spore_bomb":        "res://combat/weapons/spore_bomb/spore_bomb_data.tres",
	"vine_whip":         "res://combat/weapons/vine_whip/vine_whip_data.tres",
	"petal_shield":      "res://combat/weapons/petal_shield/petal_shield_data.tres",
	"blazeblade":        "res://combat/weapons/thorn_sword/blazeblade_data.tres",
	"void_grenade":      "res://combat/weapons/spore_bomb/void_grenade_data.tres",
	"crystal_lash":      "res://combat/weapons/vine_whip/crystal_lash_data.tres",
	"iron_bloom_shield": "res://combat/weapons/petal_shield/iron_bloom_shield_data.tres",
}

var owned_weapons: Dictionary = {"thorn_sword": true}


# --- Public API ---

func can_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var result_id: String = str(recipe.get("result_id", ""))
	if owned_weapons.get(result_id, false):
		return false
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	for item_id: String in materials:
		if not InventoryManager.has_item(item_id, int(materials[item_id])):
			return false
	var base: String = RecipeDatabase.get_upgrade_base(recipe_id)
	if not base.is_empty() and not owned_weapons.get(base, false):
		return false
	return true


func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		var reason: String = _craft_fail_reason(recipe_id)
		craft_failed.emit(reason)
		return false
	var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	for item_id: String in materials:
		InventoryManager.remove_item(item_id, int(materials[item_id]))
	var base: String = RecipeDatabase.get_upgrade_base(recipe_id)
	if not base.is_empty():
		owned_weapons.erase(base)
	var result_id: String = str(recipe.get("result_id", ""))
	owned_weapons[result_id] = true
	print("[CraftingManager] Crafted: %s" % result_id)
	weapon_crafted.emit(result_id)
	return true


func owns_weapon(weapon_id: String) -> bool:
	return owned_weapons.get(weapon_id, false)


func get_owned_weapon_ids() -> Array:
	var ids: Array = []
	for wid: String in owned_weapons:
		if owned_weapons[wid]:
			ids.append(wid)
	return ids


func get_weapon_data(weapon_id: String) -> WeaponData:
	var path: String = WEAPON_DATA_PATHS.get(weapon_id, "")
	if path.is_empty():
		push_warning("[CraftingManager] Unknown weapon_id: %s" % weapon_id)
		return null
	return load(path) as WeaponData


# --- Serialization ---

func serialize() -> Dictionary:
	return owned_weapons.duplicate()


func deserialize(data: Dictionary) -> void:
	owned_weapons = {"thorn_sword": true}
	for wid: String in data:
		if data[wid]:
			owned_weapons[wid] = true


# --- Private ---

func _craft_fail_reason(recipe_id: String) -> String:
	var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return "Unknown recipe."
	var result_id: String = str(recipe.get("result_id", ""))
	if owned_weapons.get(result_id, false):
		return "Already owned."
	var base: String = RecipeDatabase.get_upgrade_base(recipe_id)
	if not base.is_empty() and not owned_weapons.get(base, false):
		return "Requires %s first." % base
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	for item_id: String in materials:
		var needed: int = int(materials[item_id])
		if not InventoryManager.has_item(item_id, needed):
			var have: int = InventoryManager.get_total_count(item_id)
			return "Need %dx %s (have %d)." % [needed, ItemDatabase.get_display_name(item_id), have]
	return "Cannot craft."
