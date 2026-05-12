class_name ItemDatabase

enum Rarity { COMMON, UNCOMMON, RARE }
enum Quality { COMMON, SUPERIOR, MASTERWORK }

const QUALITY_NAMES: Array[String] = ["Common", "Superior", "Masterwork"]
const QUALITY_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5]
const QUALITY_MARKERS: Array[String] = ["I", "II", "III"]
const QUALITY_COLORS: Array[Color] = [
	Color(0.78, 0.70, 0.56, 1.0),
	Color(0.42, 0.78, 0.52, 1.0),
	Color(1.0, 0.78, 0.24, 1.0),
]

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
	"stone":               { "display_name": "Stone",               "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Rough stone gathered from the garden ruins. Used for structural upgrades.", "icon": "res://assets/aseprite/icons/Stone.png" },
	"bougainvillea_seed":  { "display_name": "Bougainvillea Seed",  "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Thorny plant seed. Deals damage to nearby enemies.", "icon": "res://assets/aseprite/icons/Bougainvillea Seed.png" },
	"rafflesia_seed":      { "display_name": "Rafflesia Seed",      "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Pungent bloom seed. Slows enemies in radius.", "icon": "res://assets/aseprite/icons/Rafflesia Seed.png" },
	"melati_seed":         { "display_name": "Melati Seed",         "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Sacred jasmine seed. Regenerates player energy nearby.", "icon": "res://assets/aseprite/icons/Melati Seed.png" },
	"wijaya_kusuma_seed":  { "display_name": "Wijaya Kusuma Seed",  "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Nocturnal bloom seed. Auto-attacks enemies at night.", "icon": "res://assets/aseprite/icons/Wijaya Kusuma Seed.png" },
	"beringin_seed":       { "display_name": "Beringin Seed",       "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Banyan sapling seed. Spawns root walls to block enemies.", "icon": "res://assets/aseprite/icons/Beringin Seed.png" },
	"kecombrang_seed":     { "display_name": "Kecombrang Seed",     "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Torch ginger seed. Boosts player attack speed nearby.", "icon": "res://assets/aseprite/icons/Kecombrang Seed.png" },
	"kunyit_seed":         { "display_name": "Kunyit Seed",         "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Turmeric seed. Boosts player melee damage nearby.", "icon": "res://assets/aseprite/icons/Kunyit Seed.png" },
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


static func is_plant_seed(item_id: String) -> bool:
	return item_id.ends_with("_seed")


static func normalize_quality(quality: int) -> int:
	return clampi(quality, Quality.COMMON, Quality.MASTERWORK)


static func get_quality_name(quality: int) -> String:
	return QUALITY_NAMES[normalize_quality(quality)]


static func get_quality_marker(quality: int) -> String:
	return QUALITY_MARKERS[normalize_quality(quality)]


static func get_quality_multiplier(quality: int) -> float:
	return QUALITY_MULTIPLIERS[normalize_quality(quality)]


static func get_quality_color(quality: int) -> Color:
	return QUALITY_COLORS[normalize_quality(quality)]


static func get_display_name_with_quality(item_id: String, quality: int = 0) -> String:
	var display_name: String = get_display_name(item_id)
	if not is_plant_seed(item_id):
		return display_name
	return "%s (%s)" % [display_name, get_quality_name(quality)]


static func get_quality_description(item_id: String, quality: int = 0) -> String:
	if not is_plant_seed(item_id):
		return ""
	var tier: int = normalize_quality(quality)
	return "Tier: %s | Effect power: %.0f%%" % [
		get_quality_name(tier),
		get_quality_multiplier(tier) * 100.0,
	]


static func get_rarity_color(item_id: String) -> Color:
	var rarity: Rarity = get_rarity(item_id)
	match rarity:
		Rarity.UNCOMMON:
			return Color(0.4, 0.6, 1.0, 1.0)
		Rarity.RARE:
			return Color(1.0, 0.8, 0.2, 1.0)
		_:
			return Color(0.9, 0.9, 0.9, 1.0)
