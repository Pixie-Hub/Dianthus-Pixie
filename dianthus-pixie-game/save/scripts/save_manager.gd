extends Node

signal save_completed(success: bool, manual: bool)
signal load_completed(success: bool)

const SAVE_PATH: String = "user://savegame.json"
const SCHEMA_VERSION: int = 1
const GAME_VERSION: String = "0.1.0"

const PLANT_TYPE_TO_SCENE: Dictionary = {
	"bougainvillea": "res://plants/entities/bougainvillea.tscn",
	"rafflesia": "res://plants/entities/rafflesia.tscn",
	# TODO: PLANT-02 add "melati": ...
	# TODO: PLANT-03 add "wijaya_kusuma": ...
	# TODO: PLANT-04 add "beringin": ...
	# TODO: PLANT-05 add "kecombrang": ...
	# TODO: PLANT-06 add "kunyit": ...
}

var _pending_load_state: Dictionary = {}
var _is_saving: bool = false


func _ready() -> void:
	_connect_autosave()


func _connect_autosave() -> void:
	GameManager.night_survived.connect(_on_night_survived)


func _on_night_survived(_day: int) -> void:
	call_deferred("save_to_slot", false)


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
	if has_save():
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove("savegame.json")
			print("[SaveManager] Save file deleted.")


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
	state["player"] = {
		"position": player_pos,
		"current_hp": player_hp,
		"last_zone": current_scene_path,
	}

	# Inventory
	state["inventory"] = GameManager.player_data.get("inventory", {}).duplicate()

	# Core
	var core_hp: int = 200
	if is_instance_valid(GameManager.dianthus_core):
		core_hp = GameManager.dianthus_core.current_hp
	state["core"] = {"current_hp": core_hp}

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
			"is_destroyed": false,
		})
	state["garden"] = {"plants": plants_arr}

	# Reserved stubs — populated by their owning tasks.
	state["quests"] = {}        # TODO (QUEST-01)
	state["unlocks"] = []       # TODO (END-01, END-04)
	state["difficulty"] = {"tier": DifficultyManager.get_tier_label().to_lower()}

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

	# 2. Clear live runtime entities before restoring saved layout.
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for plant: Node in get_tree().get_nodes_in_group("plants"):
		plant.queue_free()

	# 3. Dianthus Core HP.
	if is_instance_valid(GameManager.dianthus_core):
		GameManager.dianthus_core.current_hp = int(state.get("core", {}).get("current_hp", 200))
		GameManager.dianthus_core._update_aura()
		GameManager.dianthus_core.hp_changed.emit(
			GameManager.dianthus_core.current_hp,
			GameManager.dianthus_core.MAX_HP
		)

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

	# 5. Inventory.
	GameManager.player_data["inventory"] = state.get("inventory", {}).duplicate()
	# TODO (QUEST-01): Emit inventory_changed signal here when pickup UI exists.

	# 5.5 Difficulty tier.
	var diff_tier: String = state.get("difficulty", {}).get("tier", "normal")
	match diff_tier:
		"easy":
			DifficultyManager.set_tier(DifficultyManager.Tier.EASY)
		"hard":
			DifficultyManager.set_tier(DifficultyManager.Tier.HARD)
		_:
			DifficultyManager.set_tier(DifficultyManager.Tier.NORMAL)

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
		# Set current_hp after _ready() so it is not overwritten by plant init.
		plant.current_hp = int(entry_dict.get("current_hp", plant.max_hp))

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
	# Future: if version < 2: ... add new fields with sane defaults here.
	return data
