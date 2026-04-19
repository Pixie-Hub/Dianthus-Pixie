class_name ItemDatabase

enum Rarity { COMMON, UNCOMMON, RARE }

const ITEMS: Dictionary = {
	"petal_shard":    { "display_name": "Petal Shard",    "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Common flower petal used for basic crafting.", "icon": "res://assets/aseprite/icons/Petal Shard.png" },
	"verdant_sap":    { "display_name": "Verdant Sap",    "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Sticky sap extracted from trees and shrubs.", "icon": "res://assets/aseprite/icons/Verdant Sap.png" },
	"moonspore":      { "display_name": "Moonspore",      "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Nocturnal spore that appears only at night.", "icon": "res://assets/aseprite/icons/Moonspore.png" },
	"shadow_resin":   { "display_name": "Shadow Resin",   "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Dark residue dropped by elite enemies.", "icon": "res://assets/aseprite/icons/Shadow Resin.png" },
	"aether_bloom":   { "display_name": "Aether Bloom",   "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Precious bloom found in hidden chests and quest rewards.", "icon": "res://assets/aseprite/icons/Aether Bloom.png" },
	"dianthus_pollen":     { "display_name": "Dianthus Pollen",     "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Sacred pollen harvested from the Dianthus Core once per day.", "icon": "res://assets/aseprite/icons/Dianthus Pollen.png" },
	"bougainvillea_extract": { "display_name": "Bougainvillea Extract", "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Thorny extract from Bougainvillea petals.", "icon": "res://assets/aseprite/icons/Bougainvillea Extract.png" },
	"rafflesia_extract":   { "display_name": "Rafflesia Extract",   "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Pungent extract from Rafflesia bloom.", "icon": "res://assets/aseprite/icons/Rafflesia Extract.png" },
	"beringin_root":       { "display_name": "Beringin Root",       "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Sturdy root harvested from Beringin tree.", "icon": "res://assets/aseprite/icons/Beringin Root.png" },
	"kecombrang_extract":  { "display_name": "Kecombrang Extract",  "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Fiery essence of the Kecombrang flower.", "icon": "res://assets/aseprite/icons/Kecombrang Extract.png" },
	"kunyit_extract":      { "display_name": "Kunyit Extract",      "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Golden extract from Kunyit rhizome.", "icon": "res://assets/aseprite/icons/Kunyit Extract.png" },
	"bunga_api_seed":      { "display_name": "Bunga Api Seed",      "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Hybrid seed: Bougainvillea x Kecombrang. Thorns + fire AoE.", "icon": "res://assets/aseprite/icons/Bunga Api Seed.png" },
	"bunga_bayang_seed":   { "display_name": "Bunga Bayang Seed",   "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Hybrid seed: Rafflesia x Shadow Resin. Slow + night auto-attack.", "icon": "res://assets/aseprite/icons/Bunga Bayang Seed.png" },
	"melati_emas_seed":    { "display_name": "Melati Emas Seed",    "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Hybrid seed: Melati x Dianthus Pollen. HP + Energy regen.", "icon": "res://assets/aseprite/icons/Melati Emas Seed.png" },
	"baja_kuning_seed":    { "display_name": "Baja Kuning Seed",    "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Hybrid seed: Kunyit x Shadow Resin. Armor + counter-attack.", "icon": "res://assets/aseprite/icons/Baja Kuning Seed.png" },
	"bougainvillea_seed":  { "display_name": "Bougainvillea Seed",  "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Thorny plant seed. Deals damage to nearby enemies.", "icon": "res://assets/aseprite/icons/Bougainvillea Seed.png" },
	"rafflesia_seed":      { "display_name": "Rafflesia Seed",      "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Pungent bloom seed. Slows enemies in radius.", "icon": "res://assets/aseprite/icons/Rafflesia Seed.png" },
}

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func get_max_stack(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("max_stack", 99)

static func get_rarity(item_id: String) -> Rarity:
	return ITEMS.get(item_id, {}).get("rarity", Rarity.COMMON)

static func get_display_name(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("display_name", item_id)

static func get_description(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("description", "")

static func get_icon_path(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("icon", "")


static func get_rarity_color(item_id: String) -> Color:
	var rarity: Rarity = get_rarity(item_id)
	match rarity:
		Rarity.UNCOMMON:
			return Color(0.4, 0.6, 1.0, 1.0)
		Rarity.RARE:
			return Color(1.0, 0.8, 0.2, 1.0)
		_:
			return Color(0.9, 0.9, 0.9, 1.0)
