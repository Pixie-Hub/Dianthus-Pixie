extends Node

signal weapon_crafted(weapon_id: String, quality_tier: int)
signal ability_crafted(ability_id: String, quality_tier: int)
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

var owned_weapons: Dictionary = {}
var owned_abilities: Dictionary = {}
var weapon_quality: Dictionary = {}
var ability_quality: Dictionary = {}
var _force_next_quality: int = -1


# --- Public API ---

func can_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var required_flag: String = RecipeDatabase.get_required_flag(recipe_id)
	if not required_flag.is_empty() and not UnlockFlags.has_flag(required_flag):
		return false
	var result_type: String = str(recipe.get("result_type", "weapon"))
	var result_id: String = str(recipe.get("result_id", ""))
	if result_type == "ability":
		if owned_abilities.get(result_id, false):
			return false
	elif owned_weapons.get(result_id, false):
		return false
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	for item_id: String in materials:
		if not InventoryManager.has_item(item_id, int(materials[item_id])):
			return false
	var base: String = RecipeDatabase.get_upgrade_base(recipe_id)
	if not base.is_empty() and not owned_weapons.get(base, false):
		return false
	return true



func craft(recipe_id: String, quality_tier: int = 0) -> bool:
	if not can_craft(recipe_id):
		var reason: String = _craft_fail_reason(recipe_id)
		SfxManager.play("crafting_fail")
		craft_failed.emit(reason)
		return false
	var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
	_consume_recipe_materials(recipe_id)
	var result_type: String = str(recipe.get("result_type", "weapon"))
	var base: String = RecipeDatabase.get_upgrade_base(recipe_id)
	if not base.is_empty():
		owned_weapons.erase(base)
		weapon_quality.erase(base)
	var result_id: String = str(recipe.get("result_id", ""))
	var tier: int = clampi(_force_next_quality if _force_next_quality >= 0 else quality_tier, 0, 1)
	_force_next_quality = -1
	if result_type == "ability":
		owned_abilities[result_id] = true
		ability_quality[result_id] = tier
		SfxManager.play("crafting_success")
		print("[CraftingManager] Crafted ability: %s (quality=%d)" % [result_id, tier])
		ability_crafted.emit(result_id, tier)
	else:
		owned_weapons[result_id] = true
		weapon_quality[result_id] = tier
		SfxManager.play("crafting_success")
		print("[CraftingManager] Crafted: %s (quality=%d)" % [result_id, tier])
		weapon_crafted.emit(result_id, tier)
	return true


func consume_materials_only(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		var reason: String = _craft_fail_reason(recipe_id)
		SfxManager.play("crafting_fail")
		craft_failed.emit(reason)
		return false
	_consume_recipe_materials(recipe_id)
	SfxManager.play("crafting_fail")
	craft_failed.emit("Assembly failed")
	return true


func owns_weapon(weapon_id: String) -> bool:
	return owned_weapons.get(weapon_id, false)


func get_owned_weapon_ids() -> Array:
	var ids: Array = []
	for wid: String in owned_weapons:
		if owned_weapons[wid]:
			ids.append(wid)
	return ids


func owns_ability(ability_id: String) -> bool:
	return owned_abilities.get(ability_id, false)


func get_owned_ability_ids() -> Array:
	var ids: Array = []
	for aid: String in owned_abilities:
		if owned_abilities[aid]:
			ids.append(aid)
	return ids


func get_weapon_data(weapon_id: String) -> WeaponData:
	var path: String = WEAPON_DATA_PATHS.get(weapon_id, "")
	if path.is_empty():
		push_warning("[CraftingManager] Unknown weapon_id: %s" % weapon_id)
		return null
	return load(path) as WeaponData


func get_weapon_quality(weapon_id: String) -> int:
	return int(weapon_quality.get(weapon_id, 0))


func get_weapon_damage_multiplier(weapon_id: String) -> float:
	return 1.10 if get_weapon_quality(weapon_id) >= 1 else 1.0


func get_ability_quality(ability_id: String) -> int:
	return int(ability_quality.get(ability_id, 0))


func get_ability_effect_multiplier(ability_id: String) -> float:
	return 1.10 if get_ability_quality(ability_id) >= 1 else 1.0


# --- Serialization ---

func serialize() -> Dictionary:
	return {
		"weapons": owned_weapons.duplicate(),
		"abilities": owned_abilities.duplicate(),
		"weapon_quality": weapon_quality.duplicate(),
		"ability_quality": ability_quality.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	owned_weapons = {}
	owned_abilities = {}
	weapon_quality = {}
	ability_quality = {}
	# Support legacy flat format (pre-ability schema) and new nested format.
	var weapons_data: Variant = data.get("weapons", null)
	if weapons_data == null:
		weapons_data = data
	var weapon_quality_data: Dictionary = data.get("weapon_quality", {}) as Dictionary
	for wid: String in (weapons_data as Dictionary):
		if (weapons_data as Dictionary)[wid]:
			owned_weapons[wid] = true
			weapon_quality[wid] = clampi(int(weapon_quality_data.get(wid, 0)), 0, 1)
	var abilities_data: Dictionary = data.get("abilities", {}) as Dictionary
	var ability_quality_data: Dictionary = data.get("ability_quality", {}) as Dictionary
	for aid: String in abilities_data:
		if abilities_data[aid]:
			owned_abilities[aid] = true
			ability_quality[aid] = clampi(int(ability_quality_data.get(aid, 0)), 0, 1)


# --- Private ---

func _craft_fail_reason(recipe_id: String) -> String:
	var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return "Unknown recipe."
	var required_flag: String = RecipeDatabase.get_required_flag(recipe_id)
	if not required_flag.is_empty() and not UnlockFlags.has_flag(required_flag):
		return "Locked. Complete a discovery quest to unlock."
	var result_type: String = str(recipe.get("result_type", "weapon"))
	var result_id: String = str(recipe.get("result_id", ""))
	if result_type == "ability" and owned_abilities.get(result_id, false):
		return "Already owned."
	elif result_type != "ability" and owned_weapons.get(result_id, false):
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


func _consume_recipe_materials(recipe_id: String) -> void:
	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	for item_id: String in materials:
		InventoryManager.remove_item(item_id, int(materials[item_id]))
