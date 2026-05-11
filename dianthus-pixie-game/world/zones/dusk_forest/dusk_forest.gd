extends Node2D

const RESOURCE_PICKUP_SCENE: PackedScene = preload("res://inventory/pickups/resource_pickup.tscn")
const ZONE_WIDTH: int = 80
const ZONE_HEIGHT: int = 60
const TILE_SIZE: int = 16
const MAP_WIDTH: int = ZONE_WIDTH * TILE_SIZE
const MAP_HEIGHT: int = ZONE_HEIGHT * TILE_SIZE
const MIN_UNLOCK_DAY: int = 3
const RESOURCE_RNG_SEED_BASE: int = 28153
const RESOURCE_RNG_DAY_STEP: int = 6337
const DAYTIME_RESOURCE_PICKUP_GROUP: StringName = &"daytime_resource_pickups"
const RARITY_SPAWN_CHANCE: Dictionary = {
	ItemDatabase.Rarity.COMMON:   0.40,
	ItemDatabase.Rarity.UNCOMMON: 0.22,
	ItemDatabase.Rarity.RARE:     0.25,
}
const HOLLOW_SLOW_MULTIPLIER: float = 0.6
const HOLLOW_AETHER_BLOOM_PREFIX: String = "HollowAetherBloom"
const HOLLOW_SHADOW_RESIN_PREFIX: String = "HollowShadowResin"

# min_day: the zone unlocks on Day 3; all rules gate on that day.
# melati_seed and wijaya_kusuma_seed are fixed guaranteed drops per PLANT_CODEX.md.
# rafflesia_seed and moonspore placed here per WORLD-01 AC.
# kecombrang_extract node present for Harvest QTE 30% seed bonus — TODO: MINI-03.
const DAYTIME_RESOURCE_RULES: Array[Dictionary] = [
	{
		"prefix": "ForestEntranceMelatiSeed",
		"item_id": "melati_seed",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"positions": [
			Vector2(480, 864),
			Vector2(560, 832),
		],
	},
	{
		"prefix": "LandmarkWijayaKusumaSeed",
		"item_id": "wijaya_kusuma_seed",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"positions": [
			Vector2(640, 256),
		],
	},
	{
		"prefix": "ForestRafflessiaSeed",
		"item_id": "rafflesia_seed",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"positions": [
			Vector2(352, 704),
			Vector2(464, 656),
		],
	},
	{
		"prefix": "ForestMoonspore",
		"item_id": "moonspore",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"positions": [
			Vector2(400, 640),
			Vector2(520, 576),
			Vector2(720, 480),
			Vector2(600, 384),
			Vector2(680, 320),
			Vector2(560, 448),
		],
	},
	{
		"prefix": "ForestShadowResin",
		"item_id": "shadow_resin",
		"amount": 1,
		"minimum_count": 0,
		"min_day": 3,
		"positions": [
			Vector2(600, 352),
			Vector2(688, 288),
			Vector2(528, 400),
			Vector2(752, 352),
		],
	},
	{
		"prefix": "DeepForestKecombrangExtract",
		"item_id": "kecombrang_extract",
		"amount": 1,
		"minimum_count": 0,
		"min_day": 3,
		"positions": [
			Vector2(704, 224),
			Vector2(624, 304),
		],
	},
	{
		"prefix": "ForestStone",
		"item_id": "stone",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"positions": [
			Vector2(560, 512),
			Vector2(480, 576),
			Vector2(640, 448),
			Vector2(528, 448),
			Vector2(672, 384),
		],
	},
	{
		"prefix": HOLLOW_AETHER_BLOOM_PREFIX,
		"item_id": "aether_bloom",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"required_flag": "unlock_blackwater_hollow",
		"positions": [
			Vector2(160, 384),
			Vector2(192, 352),
		],
	},
	{
		"prefix": HOLLOW_SHADOW_RESIN_PREFIX,
		"item_id": "shadow_resin",
		"amount": 1,
		"minimum_count": 1,
		"min_day": 3,
		"required_flag": "unlock_blackwater_hollow",
		"positions": [
			Vector2(144, 400),
			Vector2(208, 368),
		],
	},
]

@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _phase_label: Label = $DebugOverlay/PhaseLabel
@onready var _day_label: Label = $DebugOverlay/DayLabel
@onready var _timer_label: Label = $DebugOverlay/TimerLabel
@onready var _player: CharacterBody2D = $YSortLayer/Player
@onready var _pickup_container: Node2D = $YSortLayer/PickupContainer
@onready var _hollow_barrier: StaticBody2D = $ForestMapVisuals/BlackwaterEntranceBarrier
@onready var _hollow_barrier_collider: CollisionShape2D = $ForestMapVisuals/BlackwaterEntranceBarrier/CollisionShape2D
@onready var _hollow_slow_areas: Array[Area2D] = [
	$YSortLayer/BlackwaterAmbientSlowA,
	$YSortLayer/BlackwaterAmbientSlowB,
]
@onready var _hollow_entry_trigger: Area2D = $YSortLayer/BlackwaterEntryTrigger

var _collected_pickup_names: Array[String] = []
var _collected_day: int = -1


func _ready() -> void:
	DayNightCycle.register_canvas_modulate(_canvas_modulate)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_update_debug_labels()
	_setup_camera()
	_restore_player_position()
	if is_instance_valid(_player):
		_restore_player_loadout()
		GameManager.register_player(_player)
	_spawn_daytime_resources()
	ZoneTracker.enter_zone("dusk_forest")
	_try_play_entry_cutscene()
	_apply_hollow_unlock_state()
	_connect_hollow_slow_areas()
	if UnlockFlags.has_signal("flag_set"):
		if not UnlockFlags.flag_set.is_connected(_on_unlock_flag_set):
			UnlockFlags.flag_set.connect(_on_unlock_flag_set)


func _process(_delta: float) -> void:
	if is_instance_valid(_timer_label):
		_timer_label.text = "Time: %.1fs" % DayNightCycle.get_time_remaining()


func get_map_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(MAP_WIDTH, MAP_HEIGHT))


func get_map_display_name() -> String:
	return "Dusk Forest"


func _setup_camera() -> void:
	if is_instance_valid(_player) and _player.has_method("set_camera_limits"):
		_player.call("set_camera_limits", 0, 0, MAP_WIDTH, MAP_HEIGHT)


func _restore_player_position() -> void:
	if not is_instance_valid(_player):
		return
	var target_entry_marker: String = str(GameManager.player_data.get("target_entry_marker", ""))
	if not target_entry_marker.is_empty():
		var marker: Marker2D = _find_entry_marker(target_entry_marker)
		if marker != null:
			_player.global_position = marker.global_position
			GameManager.player_data["position"] = marker.global_position
			GameManager.player_data["target_entry_marker"] = ""
			return
		GameManager.player_data["target_entry_marker"] = ""

	var last_zone: String = str(GameManager.player_data.get("last_zone", ""))
	if last_zone != "" and last_zone != scene_file_path:
		var restored_position: Variant = GameManager.player_data.get("position", _player.global_position)
		if restored_position is Vector2:
			_player.global_position = restored_position


func _try_play_entry_cutscene() -> void:
	const FLAG_ENTRY_SEEN: String = "flag_dusk_forest_entry_seen"
	if UnlockFlags.has_flag(FLAG_ENTRY_SEEN):
		return
	UnlockFlags.set_flag(FLAG_ENTRY_SEEN)
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic == null:
		return
	await get_tree().create_timer(0.5).timeout
	dialogic.start("story_interludes", "dusk_forest_entry")


func _restore_player_loadout() -> void:
	if not is_instance_valid(_player):
		return
	var slots: Variant = GameManager.player_data.get("weapon_slots", null)
	if slots is Array and (slots as Array).size() == _player.get("weapon_slots").size():
		for i: int in range((slots as Array).size()):
			_player.get("weapon_slots")[i] = str((slots as Array)[i])
		var sel: int = int(GameManager.player_data.get("selected_weapon_slot", 0))
		_player.set("selected_weapon_slot", sel)
		var first_slot: String = str(_player.get("weapon_slots")[0])
		if not first_slot.is_empty():
			var weapon_data: WeaponData = CraftingManager.get_weapon_data(first_slot)
			_player.set("_current_weapon", weapon_data)
		else:
			_player.set("_current_weapon", null)
	var skill_id: Variant = GameManager.player_data.get("active_skill_id", null)
	if skill_id is String and not (skill_id as String).is_empty():
		if _player.has_method("set_active_skill"):
			_player.call("set_active_skill", skill_id as String)


func _find_entry_marker(marker_name: String) -> Marker2D:
	var marker: Node = find_child(marker_name, true, false)
	return marker as Marker2D


func _on_phase_changed(_phase: String) -> void:
	_update_debug_labels()
	if _phase == "DAY":
		_spawn_daytime_resources()


func _update_debug_labels() -> void:
	if is_instance_valid(_phase_label):
		_phase_label.text = "Phase: %s" % DayNightCycle.get_phase_name()
	if is_instance_valid(_day_label):
		_day_label.text = "Day: %d" % DayNightCycle.day_count


func _spawn_daytime_resources() -> void:
	if not is_instance_valid(_pickup_container):
		return
	if DayNightCycle.day_count != _collected_day:
		_collected_pickup_names.clear()
		_collected_day = DayNightCycle.day_count
	_clear_daytime_resources()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = RESOURCE_RNG_SEED_BASE + (DayNightCycle.day_count * RESOURCE_RNG_DAY_STEP)
	for rule: Dictionary in DAYTIME_RESOURCE_RULES:
		_spawn_resource_rule(rule, rng)


func _clear_daytime_resources() -> void:
	for child: Node in _pickup_container.get_children():
		if child.is_in_group(DAYTIME_RESOURCE_PICKUP_GROUP):
			child.free()


func _spawn_resource_rule(rule: Dictionary, rng: RandomNumberGenerator) -> void:
	var day: int = DayNightCycle.day_count
	var min_day: int = int(rule.get("min_day", 1))
	if day < min_day:
		return
	var required_flag: String = str(rule.get("required_flag", ""))
	if not required_flag.is_empty() and not UnlockFlags.has_flag(required_flag):
		return
	var positions: Array[Vector2] = _get_shuffled_positions(rule.get("positions", []), rng)
	if positions.is_empty():
		return
	var required_count: int = clampi(int(rule.get("minimum_count", 0)), 0, positions.size())
	var item_rarity: ItemDatabase.Rarity = ItemDatabase.get_rarity(str(rule.get("item_id", "petal_shard")))
	var base_chance: float = float(RARITY_SPAWN_CHANCE.get(item_rarity, 0.80))
	var effective_chance: float = base_chance
	if item_rarity != ItemDatabase.Rarity.COMMON:
		effective_chance = base_chance * pow(0.92, floor(float(day - min_day) / 5.0))
	var spawned_count: int = 0
	for index: int in range(positions.size()):
		var should_spawn: bool = spawned_count < required_count
		if not should_spawn:
			should_spawn = rng.randf() <= effective_chance
		if should_spawn:
			var candidate: Vector2 = positions[index]
			if not _is_spawn_point_clear(candidate):
				var found_clear: bool = false
				for offset: Vector2 in [Vector2(16, 0), Vector2(-16, 0), Vector2(0, 16), Vector2(0, -16), Vector2(16, 16), Vector2(-16, 16), Vector2(16, -16), Vector2(-16, -16)]:
					var alt: Vector2 = candidate + offset
					if _is_spawn_point_clear(alt):
						candidate = alt
						found_clear = true
						break
				if not found_clear:
					continue
			_spawn_resource_pickup(rule, candidate, spawned_count + 1)
			spawned_count += 1


func _is_spawn_point_clear(pos: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space_state == null:
		return true
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = CollisionLayers.TERRAIN
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var results: Array[Dictionary] = space_state.intersect_point(params, 1)
	return results.is_empty()


func mark_pickup_collected(pickup_name: String) -> void:
	if not pickup_name in _collected_pickup_names:
		_collected_pickup_names.append(pickup_name)


func serialize_pickup_state() -> Dictionary:
	return {
		"collected_day": _collected_day,
		"collected_names": _collected_pickup_names.duplicate(),
	}


func apply_collected_pickups(data: Dictionary) -> void:
	_collected_day = int(data.get("collected_day", -1))
	_collected_pickup_names.clear()
	for n: Variant in data.get("collected_names", []):
		_collected_pickup_names.append(str(n))
	if not is_instance_valid(_pickup_container):
		return
	for child: Node in _pickup_container.get_children():
		if child.name in _collected_pickup_names:
			child.free()


func _get_shuffled_positions(source_positions: Array, rng: RandomNumberGenerator) -> Array[Vector2]:
	var shuffled: Array[Vector2] = []
	for source_position: Variant in source_positions:
		var vector_position: Vector2 = source_position
		shuffled.append(vector_position)
	for i: int in range(shuffled.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, i)
		var current_position: Vector2 = shuffled[i]
		shuffled[i] = shuffled[swap_index]
		shuffled[swap_index] = current_position
	return shuffled


func _apply_hollow_unlock_state() -> void:
	var unlocked: bool = UnlockFlags.has_flag(StoryEndingFlags.unlock_blackwater_hollow)
	if is_instance_valid(_hollow_barrier):
		_hollow_barrier.visible = not unlocked
	if is_instance_valid(_hollow_barrier_collider):
		_hollow_barrier_collider.set_deferred("disabled", unlocked)
	for area: Area2D in _hollow_slow_areas:
		if is_instance_valid(area):
			area.monitoring = unlocked


func _on_unlock_flag_set(flag_name: String) -> void:
	if flag_name != StoryEndingFlags.unlock_blackwater_hollow:
		return
	print("[DuskForest] Blackwater Hollow unlocked")
	_apply_hollow_unlock_state()
	_spawn_daytime_resources()


func _connect_hollow_slow_areas() -> void:
	for area: Area2D in _hollow_slow_areas:
		if not is_instance_valid(area):
			continue
		if not area.body_entered.is_connected(_on_hollow_slow_entered):
			area.body_entered.connect(_on_hollow_slow_entered)
		if not area.body_exited.is_connected(_on_hollow_slow_exited):
			area.body_exited.connect(_on_hollow_slow_exited)
	if is_instance_valid(_hollow_entry_trigger):
		if not _hollow_entry_trigger.body_entered.is_connected(_on_hollow_entry_trigger_body_entered):
			_hollow_entry_trigger.body_entered.connect(_on_hollow_entry_trigger_body_entered)


func _on_hollow_slow_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.set("environment_speed_modifier", HOLLOW_SLOW_MULTIPLIER)


func _on_hollow_slow_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.set("environment_speed_modifier", 1.0)


func _on_hollow_entry_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not UnlockFlags.has_flag(StoryEndingFlags.unlock_blackwater_hollow):
		return
	if UnlockFlags.has_flag(StoryEndingFlags.flag_blackwater_hollow_entry_seen):
		return
	UnlockFlags.set_flag(StoryEndingFlags.flag_blackwater_hollow_entry_seen)
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic == null:
		return
	await get_tree().create_timer(0.4).timeout
	dialogic.start("story_interludes", "blackwater_hollow_entry")


func _spawn_resource_pickup(rule: Dictionary, pickup_position: Vector2, spawn_number: int) -> void:
	var pickup_name: String = "%s%d" % [str(rule.get("prefix", "DaytimeResource")), spawn_number]
	if pickup_name in _collected_pickup_names:
		return
	var pickup: Node2D = RESOURCE_PICKUP_SCENE.instantiate() as Node2D
	if pickup == null:
		return
	pickup.name = pickup_name
	pickup.position = pickup_position
	pickup.set("item_id", str(rule.get("item_id", "petal_shard")))
	pickup.set("amount", int(rule.get("amount", 1)))
	pickup.add_to_group(DAYTIME_RESOURCE_PICKUP_GROUP)
	_pickup_container.add_child(pickup)
