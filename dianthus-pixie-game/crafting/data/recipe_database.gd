class_name RecipeDatabase

const RECIPES: Dictionary = {
	"thorn_sword": {
		"display_name": "Thorn Sword",
		"materials": {"petal_shard": 3, "verdant_sap": 2},
		"result_type": "weapon",
		"result_id": "thorn_sword",
		"upgrade_of": "",
		"description": "A blade forged from thorny petals and sap. Basic melee weapon.",
	},
	"spore_bomb": {
		"display_name": "Spore Bomb",
		"materials": {"moonspore": 2, "rafflesia_extract": 1},
		"result_type": "weapon",
		"result_id": "spore_bomb",
		"upgrade_of": "",
		"description": "Throws an explosive spore that deals area damage.",
	},
	"vine_whip": {
		"display_name": "Vine Whip",
		"materials": {"verdant_sap": 4, "bougainvillea_extract": 1},
		"result_type": "weapon",
		"result_id": "vine_whip",
		"upgrade_of": "",
		"description": "A lashing whip of living vines. Long reach, narrow arc.",
	},
	"petal_shield": {
		"display_name": "Petal Shield",
		"materials": {"petal_shard": 5, "beringin_root": 2},
		"result_type": "weapon",
		"result_id": "petal_shield",
		"upgrade_of": "",
		"description": "A sturdy shield woven from petals and roots. Blocks incoming hits.",
	},
	"blazeblade": {
		"display_name": "Blazeblade",
		"materials": {"kecombrang_extract": 1},
		"result_type": "weapon",
		"result_id": "blazeblade",
		"upgrade_of": "thorn_sword",
		"description": "Thorn Sword infused with fiery Kecombrang essence. Higher damage.",
	},
	"void_grenade": {
		"display_name": "Void Grenade",
		"materials": {"shadow_resin": 1},
		"result_type": "weapon",
		"result_id": "void_grenade",
		"upgrade_of": "spore_bomb",
		"description": "Spore Bomb enhanced with shadow resin. Wider blast radius.",
	},
	"crystal_lash": {
		"display_name": "Crystal Lash",
		"materials": {"kunyit_extract": 1},
		"result_type": "weapon",
		"result_id": "crystal_lash",
		"upgrade_of": "vine_whip",
		"description": "Vine Whip crystallised with Kunyit. Greater reach and damage.",
		"required_flag": "recipe_crystal_lash",
	},
	"iron_bloom_shield": {
		"display_name": "Iron Bloom Shield",
		"materials": {"shadow_resin": 1},
		"result_type": "weapon",
		"result_id": "iron_bloom_shield",
		"upgrade_of": "petal_shield",
		"description": "Petal Shield reinforced with shadow resin. Enhanced defence.",
	},
	"ability_dash": {
		"display_name": "Dash",
		"materials": {"verdant_sap": 3, "moonspore": 1},
		"result_type": "ability",
		"result_id": "dash",
		"upgrade_of": "",
		"description": "Dash in the facing direction, granting brief invincibility. Costs 20 energy.",
	},
	"ability_heal_pulse": {
		"display_name": "Heal Pulse",
		"materials": {"dianthus_pollen": 1, "aether_bloom": 1},
		"result_type": "ability",
		"result_id": "heal_pulse",
		"upgrade_of": "",
		"description": "Release a burst of Dianthus energy to restore 25 HP. Costs 40 energy.",
	},
	"ability_thorn_burst": {
		"display_name": "Thorn Burst",
		"materials": {"bougainvillea_extract": 2, "kecombrang_extract": 1},
		"result_type": "ability",
		"result_id": "thorn_burst",
		"upgrade_of": "",
		"description": "Unleash a ring of thorns that damages and stuns nearby enemies. Costs 35 energy.",
	},
}


static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})


static func get_all_recipe_ids() -> Array:
	return RECIPES.keys()


static func get_materials(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {}).get("materials", {})


static func get_display_name(recipe_id: String) -> String:
	return RECIPES.get(recipe_id, {}).get("display_name", recipe_id)


static func is_upgrade(recipe_id: String) -> bool:
	return not RECIPES.get(recipe_id, {}).get("upgrade_of", "").is_empty()


static func get_upgrade_base(recipe_id: String) -> String:
	return RECIPES.get(recipe_id, {}).get("upgrade_of", "")


static func get_required_flag(recipe_id: String) -> String:
	return RECIPES.get(recipe_id, {}).get("required_flag", "")
