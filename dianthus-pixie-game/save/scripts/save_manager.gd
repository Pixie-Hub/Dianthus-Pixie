extends Node

signal save_completed(success: bool, manual: bool)
signal load_completed(success: bool)

const SAVE_PATH: String = "user://savegame.json"
const SCHEMA_VERSION: int = 23
const GAME_VERSION: String = "0.1.0"

const PLANT_TYPE_TO_SCENE: Dictionary = {
	"bougainvillea": "res://plants/entities/bougainvillea.tscn",
	"rafflesia": "res://plants/entities/rafflesia.tscn",
	"bunga_api": "res://plants/entities/bunga_api.tscn",
	"bunga_bayang": "res://plants/entities/bunga_bayang.tscn",
	"melati_emas": "res://plants/entities/melati_emas.tscn",
	"baja_kuning": "res://plants/entities/baja_kuning.tscn",
	"melati": "res://plants/entities/melati.tscn",
	"wijaya_kusuma": "res://plants/entities/wijaya_kusuma.tscn",
	"beringin": "res://plants/entities/beringin.tscn",
	"kecombrang": "res://plants/entities/kecombrang.tscn",
	"kunyit": "res://plants/entities/kunyit.tscn",
}

var _pending_load_state: Dictionary = {}
var _is_saving: bool = false
var _runtime_garden_expansion: Dictionary = {"tier": 0}
var _runtime_fortification_spots: Dictionary = {}



# --- Public API ---

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_to_slot(manual: bool) -> bool:
	if _is_saving:
		push_warning("[SaveManager] Save already in progress. Skipping.")
		return false
	if manual and GameManager.current_state != GameManager.GameState.EXPLORATION:
		push_warning("[SaveManager] Manual save blocked: not in EXPLORATION state.")
		save_completed.emit(false, true)
		return false
	_is_saving = true
	var state: Dictionary = _gather_state(manual)
	var json_text: String = JSON.stringify(state, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to open save file for writing. Error: %d" % FileAccess.get_open_error())
		_is_saving = false
		save_completed.emit(false, manual)
		return false
	file.store_string(json_text)
	file.close()
	_is_saving = false
	var day: int = state.get("day_night", {}).get("day_count", 0)
	print("[SaveManager] %s (day=%d)" % ["Manual save OK" if manual else "Autosaved", day])
	save_completed.emit(true, manual)
	return true


func load_from_slot() -> bool:
	if not has_save():
		push_warning("[SaveManager] No save file found at %s" % SAVE_PATH)
		load_completed.emit(false)
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Failed to open save file for reading. Error: %d" % FileAccess.get_open_error())
		load_completed.emit(false)
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("[SaveManager] Save file is corrupted or malformed.")
		load_completed.emit(false)
		return false
	var state: Dictionary = _migrate(parsed as Dictionary)
	var last_zone: String = state.get("player", {}).get("last_zone", "")
	if last_zone.is_empty():
		last_zone = "res://world/zones/meadow_edge/meadow_edge.tscn"
	_pending_load_state = state
	get_tree().change_scene_to_file(last_zone)
	get_tree().process_frame.connect(_on_scene_loaded, CONNECT_ONE_SHOT)
	return true


func delete_save() -> void:
	reset_runtime_build_state()
	if GardenStructureManager.has_method("reset_state"):
		GardenStructureManager.reset_state()
	if has_save():
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove("savegame.json")
			print("[SaveManager] Save file deleted.")


func reset_runtime_build_state() -> void:
	_runtime_garden_expansion = {"tier": 0}
	_runtime_fortification_spots = {}


func set_runtime_garden_expansion_tier(tier: int) -> void:
	_runtime_garden_expansion = {"tier": max(0, tier)}


func get_runtime_garden_expansion_tier() -> int:
	return int(_runtime_garden_expansion.get("tier", 0))


func register_fortification_spot_state(state: Dictionary) -> void:
	var spot_id: String = str(state.get("spot_id", ""))
	if spot_id.is_empty():
		return
	_runtime_fortification_spots[spot_id] = state.duplicate(true)


func get_fortification_spot_state(spot_id: String) -> Dictionary:
	if _runtime_fortification_spots.has(spot_id):
		return (_runtime_fortification_spots[spot_id] as Dictionary).duplicate(true)
	return {
		"spot_id": spot_id,
		"spot_type": "fortification",
		"is_built": false,
		"built_item_id": "",
		"current_hp": 0,
	}


func get_save_metadata() -> Dictionary:
	if not has_save():
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed as Dictionary
	return {
		"schema_version": data.get("schema_version", 0),
		"meta": data.get("meta", {}),
		"day_count": data.get("day_night", {}).get("day_count", 1),
	}


# --- Private helpers ---

func _gather_state(manual: bool) -> Dictionary:
	# Start from existing save to preserve unknown keys (forward-compat per §3).
	var state: Dictionary = {}
	if has_save():
		var prev_file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if prev_file != null:
			var prev_parsed: Variant = JSON.parse_string(prev_file.get_as_text())
			prev_file.close()
			if prev_parsed is Dictionary:
				state = prev_parsed as Dictionary

	state["schema_version"] = SCHEMA_VERSION
	state["meta"] = {
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"game_version": GAME_VERSION,
		"manual": manual,
	}

	# Day/Night
	state["day_night"] = {
		"day_count": DayNightCycle.day_count,
		"current_phase": DayNightCycle.get_phase_name(),
		"phase_timer": DayNightCycle.get_time_remaining(),
	}

	# Player
	var player_pos: Dictionary = {"x": 0.0, "y": 0.0}
	var player_hp: int = 100
	if is_instance_valid(GameManager.player):
		player_pos = {
			"x": GameManager.player.global_position.x,
			"y": GameManager.player.global_position.y,
		}
		player_hp = GameManager.player.current_hp
	elif GameManager.player_data.has("position"):
		var pos: Vector2 = GameManager.player_data["position"]
		player_pos = {"x": pos.x, "y": pos.y}
	var current_scene_path: String = ""
	if is_instance_valid(get_tree().current_scene):
		current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path.is_empty():
		current_scene_path = GameManager.player_data.get("last_zone", "")
	var player_energy: int = 0
	var player_max_energy: int = 100
	if is_instance_valid(GameManager.player):
		player_energy = GameManager.player.current_energy
		player_max_energy = GameManager.player.max_energy
	state["player"] = {
		"position": player_pos,
		"current_hp": player_hp,
		"current_energy": player_energy,
		"max_energy": player_max_energy,
		"last_zone": current_scene_path,
	}

	# Inventory
	state["inventory"] = InventoryManager.serialize()

	# Crafting
	state["crafting"] = CraftingManager.serialize()

	# Breeding
	state["breeding"] = BreedingManager.serialize()
	var equipped_id: String = ""
	if is_instance_valid(GameManager.player) and GameManager.player._current_weapon != null:
		equipped_id = GameManager.player._current_weapon.weapon_id
	state["player"]["equipped_weapon"] = equipped_id
	var active_skill: String = ""
	if is_instance_valid(GameManager.player):
		active_skill = str(GameManager.player.active_skill_id)
	state["player"]["active_skill_id"] = active_skill

	# Core
	var core_hp: int = GameManager.core_current_hp if GameManager.core_current_hp >= 0 else GameManager.core_max_hp
	var core_max_hp: int = GameManager.core_max_hp
	var core_harvested_today: bool = false
	var core_last_harvest_day: int = -1
	if is_instance_valid(GameManager.dianthus_core):
		core_hp = GameManager.dianthus_core.current_hp
		core_max_hp = int(GameManager.dianthus_core.max_hp)
		core_harvested_today = GameManager.dianthus_core._harvested_today
		core_last_harvest_day = GameManager.dianthus_core._last_harvest_day
	state["core"] = {
		"current_hp": core_hp,
		"max_hp": core_max_hp,
		"sacred_bloom": {
			"harvested_today": core_harvested_today,
			"last_harvest_day": core_last_harvest_day,
		},
	}

	if has_node("/root/NightDefenseManager"):
		state["night_defense"] = NightDefenseManager.serialize()

	# Garden expansion tier
	var ppm: Node = null
	if is_instance_valid(get_tree().current_scene):
		ppm = get_tree().current_scene.find_child("PlantPlacementManager", true, false)
	if ppm != null:
		set_runtime_garden_expansion_tier(int(ppm.get("expansion_tier")))
	state["garden_expansion"] = _runtime_garden_expansion.duplicate(true)

	# Garden structures
	if GardenStructureManager.has_method("serialize"):
		state["garden_structures"] = GardenStructureManager.serialize()
	else:
		state["garden_structures"] = {"storage_tier": 0, "watchtower_built": false}

	# Fortification spots
	if is_instance_valid(get_tree().current_scene):
		for spot: Node in get_tree().get_nodes_in_group(&"fortification_spots"):
			if spot.has_method("serialize_build_state"):
				register_fortification_spot_state(spot.call("serialize_build_state"))
	state["fortification_spots"] = _serialize_fortification_spots()

	# Garden
	var plants_arr: Array = []
	for plant: Node in get_tree().get_nodes_in_group("plants"):
		if not plant is PlantBase:
			continue
		var pb: PlantBase = plant as PlantBase
		if pb.is_destroyed:
			continue
		var plant_type: String = _resolve_plant_type(pb)
		if plant_type.is_empty():
			continue
		plants_arr.append({
			"type": plant_type,
			"position": {"x": pb.global_position.x, "y": pb.global_position.y},
			"current_hp": pb.current_hp,
			"vitality": pb.vitality,
			"quality_tier": pb.quality_tier,
			"is_destroyed": false,
		})
	state["garden"] = {"plants": plants_arr}

	# Quest system.
	state["quests"] = QuestManager.serialize()
	state["quest_daily"] = DailyQuestRoller.serialize()
	state["unlock_flags"] = UnlockFlags.serialize()
	state["codex"] = CodexManager.serialize()
	state["endless_mode"] = GameManager.endless_mode
	state["difficulty"] = {"tier": DifficultyManager.get_tier_label().to_lower()}

	# Daytime expedition state
	var event_spawner: Node = null
	if is_instance_valid(get_tree().current_scene):
		event_spawner = get_tree().current_scene.find_child("DaytimeEventSpawner", true, false)
	if event_spawner != null and event_spawner.has_method("serialize"):
		state["daytime_event"] = event_spawner.call("serialize")
	else:
		state["daytime_event"] = {"last_event_id": "", "completed_day": -1}

	# Pickup collection state
	var current_scene: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else null
	if current_scene != null and current_scene.has_method("serialize_pickup_state"):
		state["pickups"] = current_scene.call("serialize_pickup_state")
	else:
		state["pickups"] = {"collected_day": -1, "collected_names": []}

	# Bramble cleared state
	var bramble_scene: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else null
	if bramble_scene != null and bramble_scene.has_method("serialize_bramble_state"):
		state["brambles"] = bramble_scene.call("serialize_bramble_state")
	else:
		state["brambles"] = []

	return state


func _resolve_plant_type(plant: PlantBase) -> String:
	var scene_path: String = plant.scene_file_path
	for plant_type: String in PLANT_TYPE_TO_SCENE:
		if PLANT_TYPE_TO_SCENE[plant_type] == scene_path:
			return plant_type
	return ""


func _apply_state(state: Dictionary) -> void:
	# 1. DayNightCycle first — write day, phase, timer, apply tint.
	var dn: Dictionary = state.get("day_night", {})
	DayNightCycle.apply_loaded_state(
		int(dn.get("day_count", 1)),
		str(dn.get("current_phase", "DAY")),
		float(dn.get("phase_timer", 180.0))
	)
	if str(dn.get("current_phase", "DAY")) == "DAY":
		GameManager.set_state(GameManager.GameState.EXPLORATION)
	else:
		GameManager.set_state(GameManager.GameState.DEFENSE)
	if has_node("/root/NightDefenseManager"):
		NightDefenseManager.deserialize(state.get("night_defense", {}))

	# Build-state caches must match the loaded file before scene spots refresh.
	set_runtime_garden_expansion_tier(int(state.get("garden_expansion", {}).get("tier", 0)))
	_deserialize_fortification_spots(state.get("fortification_spots", []))

	# 2. Clear live runtime entities before restoring saved layout.
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for plant: Node in get_tree().get_nodes_in_group("plants"):
		plant.queue_free()

	# 3. Dianthus Core HP.
	var core_data: Dictionary = state.get("core", {})
	var saved_core_hp: int = int(core_data.get("current_hp", GameManager.core_max_hp))
	var saved_core_max_hp: int = int(core_data.get("max_hp", max(saved_core_hp, GameManager.core_max_hp)))
	if is_instance_valid(GameManager.dianthus_core):
		GameManager.set_core_hp_from_save(saved_core_hp, saved_core_max_hp)
		GameManager.dianthus_core._update_aura()
		GameManager.dianthus_core.hp_changed.emit(
			GameManager.dianthus_core.current_hp,
			GameManager.dianthus_core.max_hp
		)
		var bloom_data: Dictionary = core_data.get("sacred_bloom", {})
		GameManager.dianthus_core._harvested_today = bool(bloom_data.get("harvested_today", false))
		GameManager.dianthus_core._last_harvest_day = int(bloom_data.get("last_harvest_day", -1))
		GameManager.dianthus_core.call_deferred("_refresh_prompt")
	elif state.has("core"):
		GameManager.set_core_hp_from_save(saved_core_hp, saved_core_max_hp)

	# 4. Player position and HP.
	if is_instance_valid(GameManager.player):
		var pd: Dictionary = state.get("player", {})
		var pos: Dictionary = pd.get("position", {"x": 0.0, "y": 0.0})
		GameManager.player.global_position = Vector2(
			float(pos.get("x", 0.0)),
			float(pos.get("y", 0.0))
		)
		GameManager.player.current_hp = int(pd.get("current_hp", 100))
		GameManager.player.hp_changed.emit(
			GameManager.player.current_hp,
			GameManager.player.MAX_HP
		)
		GameManager.player.max_energy = int(pd.get("max_energy", 100))
		GameManager.player.current_energy = int(pd.get("current_energy", 0))
		GameManager.player.energy_changed.emit(
			GameManager.player.current_energy,
			GameManager.player.max_energy
		)

	# 5. Inventory.
	InventoryManager.deserialize(state.get("inventory", []))

	# 5.6 Crafting.
	CraftingManager.deserialize(state.get("crafting", {}))

	# 5.7 Breeding.
	BreedingManager.deserialize(state.get("breeding", {}))

	# 5.8 Quests.
	QuestManager.deserialize(state.get("quests", {}))
	var equipped_id: String = state.get("player", {}).get("equipped_weapon", "")
	if is_instance_valid(GameManager.player):
		if not equipped_id.is_empty():
			var weapon_data: WeaponData = CraftingManager.get_weapon_data(equipped_id)
			if weapon_data != null:
				GameManager.player.weapon_slots[0] = equipped_id
				GameManager.player.selected_weapon_slot = 0
				GameManager.player._current_weapon = weapon_data
		else:
			GameManager.player.weapon_slots[0] = ""
			GameManager.player.selected_weapon_slot = 0
			GameManager.player._current_weapon = null
		var saved_skill: String = str(state.get("player", {}).get("active_skill_id", ""))
		if not saved_skill.is_empty() and GameManager.player.has_method("set_active_skill"):
			GameManager.player.set_active_skill(saved_skill)
		GameManager.player.loadout_changed.emit(
			GameManager.player.weapon_slots,
			GameManager.player.active_skill_id,
			GameManager.player.selected_weapon_slot
		)

	# 5.9 Codex, daily quest roller, unlock flags.
	CodexManager.deserialize(state.get("codex", {}))
	DailyQuestRoller.deserialize(state.get("quest_daily", {}))
	UnlockFlags.deserialize(state.get("unlock_flags", {}))

	# 5.10 Endless mode.
	GameManager.endless_mode = bool(state.get("endless_mode", false))

	# 5.11 Daytime expedition state.
	var event_spawner: Node = null
	if is_instance_valid(get_tree().current_scene):
		event_spawner = get_tree().current_scene.find_child("DaytimeEventSpawner", true, false)
	if event_spawner != null and event_spawner.has_method("deserialize"):
		event_spawner.call("deserialize", state.get("daytime_event", {}))

	# 5.12 Pickup collection state — removes already-collected pickups from the scene.
	var pickup_scene: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else null
	if pickup_scene != null and pickup_scene.has_method("apply_collected_pickups"):
		pickup_scene.call("apply_collected_pickups", state.get("pickups", {}))

	# 5.13 Bramble cleared state — removes destroyed brambles from the scene.
	var bramble_scene: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else null
	if bramble_scene != null and bramble_scene.has_method("apply_cleared_brambles"):
		bramble_scene.call("apply_cleared_brambles", state.get("brambles", []))

	# 5.5 Difficulty tier.
	var diff_tier: String = state.get("difficulty", {}).get("tier", "normal")
	match diff_tier:
		"easy":
			DifficultyManager.set_tier(DifficultyManager.Tier.EASY)
		"hard":
			DifficultyManager.set_tier(DifficultyManager.Tier.HARD)
		_:
			DifficultyManager.set_tier(DifficultyManager.Tier.NORMAL)

	# 5.14 Garden expansion tier — restore before plants so grid is correctly sized.
	var ppm_restore: Node = null
	if is_instance_valid(get_tree().current_scene):
		ppm_restore = get_tree().current_scene.find_child("PlantPlacementManager", true, false)
	if ppm_restore != null:
		var saved_tier: int = get_runtime_garden_expansion_tier()
		ppm_restore.set("expansion_tier", saved_tier)
		if ppm_restore.has_method("_update_garden_origin"):
			ppm_restore.call("_update_garden_origin")
		if ppm_restore.has_method("_rebuild_occupied_tiles"):
			ppm_restore.call("_rebuild_occupied_tiles")

	# 5.15 Garden structures.
	GardenStructureManager.deserialize(state.get("garden_structures", {}))

	# 5.16 Fortification spots.
	for spot: Node in get_tree().get_nodes_in_group(&"fortification_spots"):
		if not spot.has_method("apply_build_state"):
			continue
		var spot_id: String = spot.name
		if spot.has_method("_get_spot_id"):
			spot_id = str(spot.call("_get_spot_id"))
		spot.call("apply_build_state", get_fortification_spot_state(spot_id))

	# 6. Garden plants — instantiate each saved entry into the current scene.
	var scene_root: Node = get_tree().current_scene
	var plants_arr: Array = state.get("garden", {}).get("plants", [])
	for entry: Variant in plants_arr:
		if not entry is Dictionary:
			continue
		var entry_dict: Dictionary = entry as Dictionary
		var entry_type: String = str(entry_dict.get("type", ""))
		if not PLANT_TYPE_TO_SCENE.has(entry_type):
			push_warning("[SaveManager] Unknown plant type '%s'. Skipping." % entry_type)
			continue
		var packed: PackedScene = load(PLANT_TYPE_TO_SCENE[entry_type]) as PackedScene
		if packed == null:
			push_warning("[SaveManager] Could not load plant scene for type '%s'." % entry_type)
			continue
		var plant: PlantBase = packed.instantiate() as PlantBase
		var entry_pos: Dictionary = entry_dict.get("position", {"x": 0.0, "y": 0.0})
		plant.global_position = Vector2(
			float(entry_pos.get("x", 0.0)),
			float(entry_pos.get("y", 0.0))
		)
		scene_root.add_child(plant)
		# Set current_hp, vitality, and quality_tier after _ready() so they are not overwritten.
		plant.current_hp = int(entry_dict.get("current_hp", plant.max_hp))
		plant.vitality = float(entry_dict.get("vitality", 100.0))
		var saved_quality: int = int(entry_dict.get("quality_tier", 0))
		if plant.has_method("set_quality") and saved_quality > 0:
			plant.set_quality(saved_quality)
		plant._update_vitality_visual()

	# 7. Done.
	print("[SaveManager] State applied. Day %d, Phase %s, Plants restored: %d" % [
		DayNightCycle.day_count,
		DayNightCycle.get_phase_name(),
		plants_arr.size(),
	])
	load_completed.emit(true)


func _on_scene_loaded() -> void:
	# Wait an extra frame so the new scene is fully set as current_scene.
	await get_tree().process_frame
	_apply_state(_pending_load_state)
	_pending_load_state = {}


func _migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		push_warning("[SaveManager] Save version %d is newer than engine %d. Loading anyway." \
			% [version, SCHEMA_VERSION])
		return data
	# v0 → v1: theoretical legacy path, never shipped. Kept as skeleton.
	if version < 1:
		print("[SaveManager] Migrating save from v%d to v1." % version)
		data["schema_version"] = 1
		data["quests"] = {}
		data["unlocks"] = []
		data["difficulty"] = {"tier": "normal"}
	# v1 → v2: inventory migrated from flat Dictionary to slot Array.
	if version < 2:
		print("[SaveManager] Migrating save from v%d to v2." % version)
		var old_inv: Variant = data.get("inventory", {})
		if old_inv is Dictionary:
			var slot_array: Array = []
			for item_id: String in (old_inv as Dictionary):
				var count: int = int((old_inv as Dictionary)[item_id])
				if count > 0:
					slot_array.append({"item_id": item_id, "count": count})
			data["inventory"] = slot_array
		data["schema_version"] = 2
	# v2 → v3: crafting ownership added.
	if version < 3:
		print("[SaveManager] Migrating save from v%d to v3." % version)
		if not data.has("crafting"):
			data["crafting"] = {"weapons": {"thorn_sword": true}, "abilities": {}}
		if not data.get("player", {}).has("equipped_weapon"):
			data["player"]["equipped_weapon"] = "thorn_sword"
		data["schema_version"] = 3
	# v3 → v4: energy fields added.
	if version < 4:
		print("[SaveManager] Migrating save from v%d to v4." % version)
		var pd: Dictionary = data.get("player", {})
		if not pd.has("current_energy"):
			pd["current_energy"] = 0
		if not pd.has("max_energy"):
			pd["max_energy"] = 100
		data["player"] = pd
		data["schema_version"] = 4
	# v4 → v5: breeding discovery tracking added.
	if version < 5:
		print("[SaveManager] Migrating save from v%d to v5." % version)
		if not data.has("breeding"):
			data["breeding"] = {"discovered": {}}
		data["schema_version"] = 5
	# v5 → v6: quest system added.
	if version < 6:
		print("[SaveManager] Migrating save from v%d to v6." % version)
		if not data.has("quests"):
			data["quests"] = {"active": {}, "completed": {}, "failed": {}}
		data["schema_version"] = 6
	# v6 → v7: codex discovery tracking added.
	if version < 7:
		print("[SaveManager] Migrating save from v%d to v7." % version)
		if not data.has("codex"):
			data["codex"] = {"discovered_plants": {}}
		data["schema_version"] = 7
	# v7 → v8: daily quest roller and unlock flags added.
	if version < 8:
		print("[SaveManager] Migrating save from v%d to v8." % version)
		if not data.has("quest_daily"):
			data["quest_daily"] = {"last_rolled_day": 0, "current_daily_ids": []}
		if not data.has("unlock_flags"):
			data["unlock_flags"] = {}
		data["schema_version"] = 8
	# v8 → v9: endings system added (flags travel via unlock_flags — no data change).
	if version < 9:
		print("[SaveManager] Migrated v8 → v9 (endings)")
		data["schema_version"] = 9
	# v9 → v10: endless mode flag added.
	if version < 10:
		print("[SaveManager] Migrating save from v%d to v10." % version)
		data["endless_mode"] = false
		data["schema_version"] = 10
	# v10 → v11: plant vitality added (defaults to 100.0 on load, no data change required).
	if version < 11:
		print("[SaveManager] Migrated v10 → v11 (plant vitality)")
		data["schema_version"] = 11
	# v11 → v12: daytime expedition completed_day tracking added.
	if version < 12:
		print("[SaveManager] Migrated v11 → v12 (daytime_event)")
		if not data.has("daytime_event"):
			data["daytime_event"] = {"last_event_id": "", "completed_day": -1}
		data["schema_version"] = 12
	# v12 → v13: pickup collection tracking added.
	if version < 13:
		print("[SaveManager] Migrated v12 → v13 (pickup state)")
		if not data.has("pickups"):
			data["pickups"] = {"collected_day": -1, "collected_names": []}
		data["schema_version"] = 13
	# v13 → v14: active daytime event serialization added.
	if version < 14:
		print("[SaveManager] Migrated v13 → v14 (active daytime event)")
		var ev: Dictionary = data.get("daytime_event", {})
		if not ev.has("active_event_id"):
			ev["active_event_id"] = ""
			ev["active_event_pos_x"] = 0.0
			ev["active_event_pos_y"] = 0.0
			data["daytime_event"] = ev
		data["schema_version"] = 14
	# v14 → v15: bramble cleared state added.
	if version < 15:
		print("[SaveManager] Migrated v14 → v15 (brambles)")
		if not data.has("brambles"):
			data["brambles"] = []
		data["schema_version"] = 15
	# v15 → v16: ability ownership and active_skill_id added.
	if version < 16:
		print("[SaveManager] Migrated v15 → v16 (ability ownership)")
		var crafting: Variant = data.get("crafting", null)
		if crafting is Dictionary:
			var cd: Dictionary = crafting as Dictionary
			if not cd.has("weapons"):
				data["crafting"] = {"weapons": cd.duplicate(), "abilities": {}}
			elif not cd.has("abilities"):
				cd["abilities"] = {}
		else:
			data["crafting"] = {"weapons": {"thorn_sword": true}, "abilities": {}}
		if not data.get("player", {}).has("active_skill_id"):
			data["player"]["active_skill_id"] = ""
		data["schema_version"] = 16
	# v16 -> v17: garden expansion tier and structures added.
	if version < 17:
		print("[SaveManager] Migrated v16 -> v17 (garden expansion + structures)")
		if not data.has("garden_expansion"):
			data["garden_expansion"] = {"tier": 0}
		if not data.has("garden_structures"):
			data["garden_structures"] = {"storage_tier": 0, "watchtower_built": false}
		data["schema_version"] = 17
	# v17 -> v18: core sacred bloom harvest state added.
	if version < 18:
		print("[SaveManager] Migrated v17 -> v18 (core sacred bloom)")
		var existing_core: Variant = data.get("core", {})
		if existing_core is Dictionary:
			var cd: Dictionary = existing_core as Dictionary
			if not cd.has("sacred_bloom"):
				cd["sacred_bloom"] = {"harvested_today": false, "last_harvest_day": -1}
				data["core"] = cd
		data["schema_version"] = 18
	# v18 -> v19: inventory slot quality field + breeding discovered bool→int.
	if version < 19:
		print("[SaveManager] Migrating save from v%d to v19." % version)
		var inv: Variant = data.get("inventory", [])
		if inv is Array:
			for slot: Variant in (inv as Array):
				if slot is Dictionary and not (slot as Dictionary).has("quality"):
					(slot as Dictionary)["quality"] = 0
		var br: Dictionary = data.get("breeding", {})
		var disc: Variant = br.get("discovered", {})
		if disc is Dictionary:
			var upgraded: Dictionary = {}
			for cid: String in (disc as Dictionary):
				var v_existing: Variant = (disc as Dictionary)[cid]
				if v_existing is int or v_existing is float:
					upgraded[cid] = int(v_existing)
				else:
					upgraded[cid] = 0  # bool=true → Biasa
			br["discovered"] = upgraded
			data["breeding"] = br
		data["schema_version"] = 19
	# v19 -> v20: crafted weapon/ability quality dictionaries added.
	if version < 20:
		print("[SaveManager] Migrating save from v%d to v20." % version)
		var crafting: Variant = data.get("crafting", {})
		if crafting is Dictionary:
			var cd: Dictionary = crafting as Dictionary
			if not cd.has("weapon_quality"):
				var wq: Dictionary = {}
				var weapons: Dictionary = cd.get("weapons", {}) as Dictionary
				for wid: String in weapons:
					if bool(weapons[wid]):
						wq[wid] = 0
				cd["weapon_quality"] = wq
			if not cd.has("ability_quality"):
				var aq: Dictionary = {}
				var abilities: Dictionary = cd.get("abilities", {}) as Dictionary
				for aid: String in abilities:
					if bool(abilities[aid]):
						aq[aid] = 0
				cd["ability_quality"] = aq
			data["crafting"] = cd
		else:
			data["crafting"] = {
				"weapons": {},
				"abilities": {},
				"weapon_quality": {},
				"ability_quality": {},
			}
		data["schema_version"] = 20
	# v20 -> v21: fortification build spot state added.
	if version < 21:
		print("[SaveManager] Migrating save from v%d to v21." % version)
		if not data.has("fortification_spots"):
			data["fortification_spots"] = []
		data["schema_version"] = 21
	# v21 -> v22: active night defense state added.
	if version < 22:
		print("[SaveManager] Migrating save from v%d to v22." % version)
		if not data.has("night_defense"):
			data["night_defense"] = {"active": false}
		data["schema_version"] = 22
	# v22 -> v23: Dianthus Core max HP is persisted separately from scene defaults.
	if version < 23:
		print("[SaveManager] Migrating save from v%d to v23." % version)
		var core_data: Dictionary = data.get("core", {}) if data.get("core", {}) is Dictionary else {}
		var saved_core_hp: int = int(core_data.get("current_hp", 0))
		var diff_tier: String = str(data.get("difficulty", {}).get("tier", "normal"))
		var default_core_max_hp: int = 350
		match diff_tier:
			"easy":
				default_core_max_hp = DifficultyManager.get_core_max_hp(DifficultyManager.Tier.EASY)
			"hard":
				default_core_max_hp = DifficultyManager.get_core_max_hp(DifficultyManager.Tier.HARD)
			_:
				default_core_max_hp = DifficultyManager.get_core_max_hp(DifficultyManager.Tier.NORMAL)
		core_data["max_hp"] = max(saved_core_hp, default_core_max_hp)
		data["core"] = core_data
		data["schema_version"] = 23
	return data


func _serialize_fortification_spots() -> Array:
	var result: Array = []
	var spot_ids: Array = _runtime_fortification_spots.keys()
	spot_ids.sort()
	for spot_id: String in spot_ids:
		var state: Dictionary = (_runtime_fortification_spots[spot_id] as Dictionary).duplicate(true)
		if not state.has("spot_type"):
			state["spot_type"] = "fortification"
		result.append(state)
	return result


func _deserialize_fortification_spots(data: Variant) -> void:
	_runtime_fortification_spots = {}
	if not data is Array:
		return
	for entry: Variant in data as Array:
		if not entry is Dictionary:
			continue
		var state: Dictionary = (entry as Dictionary).duplicate(true)
		var spot_id: String = str(state.get("spot_id", ""))
		if spot_id.is_empty():
			continue
		if not state.has("spot_type"):
			state["spot_type"] = "fortification"
		if not state.has("is_built"):
			state["is_built"] = not str(state.get("built_item_id", "")).is_empty()
		if not state.has("current_hp"):
			state["current_hp"] = 0
		_runtime_fortification_spots[spot_id] = state
