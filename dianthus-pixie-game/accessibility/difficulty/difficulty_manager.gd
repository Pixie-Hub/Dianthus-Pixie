extends Node

signal difficulty_changed(tier_id: int)

enum Tier { EASY = 0, NORMAL = 1, HARD = 2 }

const TIER_DATA: Dictionary = {
	Tier.EASY:   { "label": "Easy",   "hp_mult": 0.80, "dmg_mult": 0.80, "speed_mult": 0.80 },
	Tier.NORMAL: { "label": "Normal", "hp_mult": 1.00, "dmg_mult": 1.00, "speed_mult": 1.00 },
	Tier.HARD:   { "label": "Hard",   "hp_mult": 1.30, "dmg_mult": 1.30, "speed_mult": 1.30 },
}
const CORE_MAX_HP_BY_TIER: Dictionary = {
	Tier.EASY: 500,
	Tier.NORMAL: 350,
	Tier.HARD: 200,
}

var current_tier: Tier = Tier.NORMAL


func set_tier(tier_id: int) -> void:
	var new_tier: Tier = tier_id as Tier
	if new_tier == current_tier:
		return
	current_tier = new_tier
	difficulty_changed.emit(int(current_tier))
	print("[DifficultyManager] Tier changed to %s" % get_tier_label())


func get_tier_label() -> String:
	return TIER_DATA[current_tier]["label"]


func get_hp_multiplier() -> float:
	return TIER_DATA[current_tier]["hp_mult"]


func get_dmg_multiplier() -> float:
	return TIER_DATA[current_tier]["dmg_mult"]


func get_speed_multiplier() -> float:
	return TIER_DATA[current_tier]["speed_mult"]


func get_tier_id() -> int:
	return int(current_tier)


func get_core_max_hp(tier_id: int = -1) -> int:
	var resolved_tier: int = int(current_tier) if tier_id < 0 else tier_id
	return int(CORE_MAX_HP_BY_TIER.get(resolved_tier, CORE_MAX_HP_BY_TIER[Tier.NORMAL]))
