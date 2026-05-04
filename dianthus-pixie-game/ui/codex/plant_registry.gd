class_name PlantRegistry

const PLANTS: Dictionary = {
	"bougainvillea": {
		"display_name": "Bougainvillea",
		"role": "Offensive",
		"effect": "Thorns deal 5 DMG/tick to enemies in radius.",
		"radius": 24.0,
		"color": Color(0.85, 0.15, 0.45, 1),
		"seed_id": "bougainvillea_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Bougainvillea seed in the world.",
		"sprite_path": "res://plants/sprites/Bougainvillea.png",
	},
	"rafflesia": {
		"display_name": "Rafflesia",
		"role": "Defensive",
		"effect": "Slows enemies 0.6x in radius.",
		"radius": 40.0,
		"color": Color(0.65, 0.12, 0.15, 1),
		"seed_id": "rafflesia_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Rafflesia Seeds in the world.",
		"sprite_path": "res://plants/sprites/Rafflesia.png",
	},
	"melati": {
		"display_name": "Melati",
		"role": "Support",
		"effect": "Restores +3 energy/sec to player in radius.",
		"radius": 32.0,
		"color": Color(0.9, 0.95, 1.0, 1),
		"seed_id": "melati_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Melati Seeds in the world.",
		"sprite_path": "res://plants/sprites/Melati.png",
	},
	"wijaya_kusuma": {
		"display_name": "Wijaya Kusuma",
		"role": "Offensive",
		"effect": "At night, fires 8 DMG projectiles at nearby enemies.",
		"radius": 48.0,
		"color": Color(0.94, 0.91, 1.0, 1),
		"seed_id": "wijaya_kusuma_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Wijaya Kusuma Seeds in the world.",
		"sprite_path": "res://plants/sprites/Wijaya Kusuma.png",
	},
	"beringin": {
		"display_name": "Beringin",
		"role": "Defensive",
		"effect": "Spawns a root wall (HP:60) that blocks enemies for 20s.",
		"radius": 32.0,
		"color": Color(0.24, 0.48, 0.13, 1),
		"seed_id": "beringin_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Beringin Seeds in the world.",
		"sprite_path": "res://plants/sprites/Beringin.png",
	},
	"kecombrang": {
		"display_name": "Kecombrang",
		"role": "Support",
		"effect": "Grants +20% attack speed to player in radius.",
		"radius": 28.0,
		"color": Color(1.0, 0.22, 0.38, 1),
		"seed_id": "kecombrang_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Kecombrang Seeds in the world.",
		"sprite_path": "res://plants/sprites/Kecombrang.png",
	},
	"kunyit": {
		"display_name": "Kunyit",
		"role": "Support",
		"effect": "Grants +3 melee damage to player in radius.",
		"radius": 24.0,
		"color": Color(0.83, 0.72, 0.13, 1),
		"seed_id": "kunyit_seed",
		"is_hybrid": false,
		"unlock_hint": "Find Kunyit Seeds in the world.",
		"sprite_path": "res://plants/sprites/Kunyit.png",
	},
	"bunga_api": {
		"display_name": "Bunga Api",
		"role": "Hybrid — Offensive",
		"effect": "Fire thorns deal 7 DMG/tick + 3 burn DMG over 2s.",
		"radius": 28.0,
		"color": Color(1.0, 0.4, 0.1, 1),
		"seed_id": "bunga_api_seed",
		"is_hybrid": true,
		"combo_id": "bunga_api",
		"unlock_hint": "Discover this hybrid by cross-breeding two plant extracts at the Breeding Bench.",
		"sprite_path": "res://plants/sprites/Bunga Api.png",
	},
	"bunga_bayang": {
		"display_name": "Bunga Bayang",
		"role": "Hybrid — Defensive",
		"effect": "Slows enemies 0.7x. At night, fires 4 DMG auto-attacks.",
		"radius": 36.0,
		"color": Color(0.3, 0.1, 0.4, 1),
		"seed_id": "bunga_bayang_seed",
		"is_hybrid": true,
		"combo_id": "bunga_bayang",
		"unlock_hint": "Discover this hybrid by cross-breeding two plant extracts at the Breeding Bench.",
		"sprite_path": "res://plants/sprites/Bunga Bayang.png",
	},
	"melati_emas": {
		"display_name": "Melati Emas",
		"role": "Hybrid — Support",
		"effect": "Regenerates HP (+2/s) and energy (+4/s) for player in radius.",
		"radius": 32.0,
		"color": Color(1.0, 0.85, 0.3, 1),
		"seed_id": "melati_emas_seed",
		"is_hybrid": true,
		"combo_id": "melati_emas",
		"unlock_hint": "Discover this hybrid by cross-breeding two plant extracts at the Breeding Bench.",
		"sprite_path": "res://plants/sprites/Melati Emas.png",
	},
	"baja_kuning": {
		"display_name": "Baja Kuning",
		"role": "Hybrid — Defensive",
		"effect": "Grants +30% damage reduction to player in radius.",
		"radius": 28.0,
		"color": Color(0.85, 0.7, 0.15, 1),
		"seed_id": "baja_kuning_seed",
		"is_hybrid": true,
		"combo_id": "baja_kuning",
		"unlock_hint": "Discover this hybrid by cross-breeding two plant extracts at the Breeding Bench.",
		"sprite_path": "res://plants/sprites/Baja Kuning.png",
	},
}


static func get_plant(plant_id: String) -> Dictionary:
	return PLANTS.get(plant_id, {})


static func get_all_plant_ids() -> Array:
	return PLANTS.keys()


static func get_display_name(plant_id: String) -> String:
	return str(PLANTS.get(plant_id, {}).get("display_name", plant_id))


static func get_base_plant_ids() -> Array:
	var result: Array = []
	for pid: String in PLANTS:
		if not bool(PLANTS[pid].get("is_hybrid", false)):
			result.append(pid)
	return result


static func get_sprite_path(plant_id: String) -> String:
	return str(PLANTS.get(plant_id, {}).get("sprite_path", ""))


static func get_hybrid_plant_ids() -> Array:
	var result: Array = []
	for pid: String in PLANTS:
		if bool(PLANTS[pid].get("is_hybrid", false)):
			result.append(pid)
	return result
