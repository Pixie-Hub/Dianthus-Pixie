extends Node2D

const RESOURCE_PICKUP_SCENE: PackedScene = preload("res://inventory/pickups/resource_pickup.tscn")
const ZONE_WIDTH: int = 96
const ZONE_HEIGHT: int = 72
const TILE_SIZE: int = 16
const MAP_WIDTH: int = ZONE_WIDTH * TILE_SIZE
const MAP_HEIGHT: int = ZONE_HEIGHT * TILE_SIZE
const RESOURCE_RNG_SEED_BASE: int = 17041
const RESOURCE_RNG_DAY_STEP: int = 7919
const DAYTIME_RESOURCE_PICKUP_GROUP: StringName = &"daytime_resource_pickups"
const RARITY_SPAWN_CHANCE: Dictionary = {
	ItemDatabase.Rarity.COMMON:   0.80,
	ItemDatabase.Rarity.UNCOMMON: 0.45,
	ItemDatabase.Rarity.RARE:     0.20,
}
const DAYTIME_RESOURCE_RULES: Array[Dictionary] = [
	{
		"prefix": "PetalFieldPetalShard",
		"item_id": "petal_shard",
		"amount": 1,
		"day_one_count": 3,
		"minimum_count": 2,
		"positions": [
			Vector2(704, 864),
			Vector2(592, 800),
			Vector2(456, 704),
			Vector2(336, 600),
			Vector2(520, 520),
			Vector2(624, 928),
			Vector2(480, 848),
			Vector2(560, 768),
			Vector2(400, 656),
			Vector2(664, 720),
		],
	},
	{
		"prefix": "SapGroveVerdantSap",
		"item_id": "verdant_sap",
		"amount": 1,
		"day_one_count": 2,
		"minimum_count": 1,
		"positions": [
			Vector2(1008, 712),
			Vector2(1176, 592),
			Vector2(1304, 472),
			Vector2(1096, 624),
			Vector2(1152, 680),
			Vector2(1240, 544),
			Vector2(1360, 504),
			Vector2(1064, 560),
		],
	},
	{
		"prefix": "OldRootMoonspore",
		"item_id": "moonspore",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(680, 300),
			Vector2(760, 380),
			Vector2(840, 310),
			Vector2(720, 260),
			Vector2(800, 352),
			Vector2(744, 416),
		],
	},
	{
		"prefix": "RuinGlimmerShadowResin",
		"item_id": "shadow_resin",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(700, 192),
			Vector2(820, 192),
			Vector2(752, 208),
			Vector2(780, 176),
		],
	},
	{
		"prefix": "PetalFieldBougainvilleaExtract",
		"item_id": "bougainvillea_extract",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(300, 548),
			Vector2(380, 480),
			Vector2(350, 520),
			Vector2(296, 448),
		],
	},
	{
		"prefix": "SapGroveRafflesiaExtract",
		"item_id": "rafflesia_extract",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(1360, 432),
			Vector2(1312, 520),
			Vector2(1400, 464),
			Vector2(1344, 488),
		],
	},
	{
		"prefix": "OldRootBeringinRoot",
		"item_id": "beringin_root",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(720, 344),
			Vector2(800, 328),
			Vector2(760, 316),
			Vector2(680, 360),
		],
	},
	{
		"prefix": "RuinGlimmerAetherBloom",
		"item_id": "aether_bloom",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(736, 208),
			Vector2(672, 232),
			Vector2(700, 196),
			Vector2(752, 240),
		],
	},
	{
		"prefix": "GardenGateDianthusPollen",
		"item_id": "dianthus_pollen",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(800, 880),
			Vector2(720, 912),
		],
	},
	{
		"prefix": "SapGroveKecombrangExtract",
		"item_id": "kecombrang_extract",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(1280, 440),
			Vector2(1320, 456),
		],
	},
	{
		"prefix": "OldRootKunyitExtract",
		"item_id": "kunyit_extract",
		"amount": 1,
		"minimum_count": 0,
		"positions": [
			Vector2(640, 280),
			Vector2(600, 296),
		],
	},
]

@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _phase_label: Label = $DebugOverlay/PhaseLabel
@onready var _day_label: Label = $DebugOverlay/DayLabel
@onready var _timer_label: Label = $DebugOverlay/TimerLabel
@onready var _player: CharacterBody2D = $YSortLayer/Player
@onready var _pickup_container: Node2D = $YSortLayer/PickupContainer

var _wave_spawner: WaveSpawner = null

func _ready() -> void:
	DayNightCycle.register_canvas_modulate(_canvas_modulate)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_update_debug_labels()
	_setup_camera()
	_restore_player_position()
	var core: Node = $YSortLayer/DianthusCore
	if is_instance_valid(core) and core.has_method("get_hp_ratio"):
		GameManager.register_core(core)
	if is_instance_valid(_player):
		GameManager.register_player(_player)
	_refresh_placement_bounds()
	_spawn_daytime_resources()
	TutorialManager.notify_scene_ready()
	_wave_spawner = get_node_or_null("WaveSpawner") as WaveSpawner
	if is_instance_valid(_wave_spawner):
		_setup_wave_spawn_points()
		_wave_spawner.wave_started.connect(_on_wave_started)
		_wave_spawner.wave_cleared.connect(_on_wave_cleared)

func _process(_delta: float) -> void:
	if is_instance_valid(_timer_label):
		_timer_label.text = "Time: %.1fs" % DayNightCycle.get_time_remaining()


func get_map_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(MAP_WIDTH, MAP_HEIGHT))


func get_map_display_name() -> String:
	return "Meadow Edge"

func _setup_camera() -> void:
	if is_instance_valid(_player) and _player.has_method("set_camera_limits"):
		_player.set_camera_limits(0, 0, MAP_WIDTH, MAP_HEIGHT)

func _restore_player_position() -> void:
	var last_zone: String = GameManager.player_data["last_zone"]
	if last_zone != "" and last_zone != scene_file_path:
		if is_instance_valid(_player):
			_player.global_position = GameManager.player_data["position"]

func _on_phase_changed(_phase: String) -> void:
	_update_debug_labels()
	if _phase == "DAY":
		_spawn_daytime_resources()

func _update_debug_labels() -> void:
	if is_instance_valid(_phase_label):
		_phase_label.text = "Phase: %s" % DayNightCycle.get_phase_name()
	if is_instance_valid(_day_label):
		_day_label.text = "Day: %d" % DayNightCycle.day_count


func _on_wave_started() -> void:
	print("[MeadowEdge] Wave started.")


func _on_wave_cleared() -> void:
	GameManager.trigger_night_survived()
	print("[MeadowEdge] Wave cleared — night survived!")

func _setup_wave_spawn_points() -> void:
	if not is_instance_valid(_wave_spawner):
		return
	var spawn_positions: Dictionary = {
		"SpawnNorth": Vector2(MAP_WIDTH * 0.5, -32.0),
		"SpawnSouth": Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT + 32.0),
		"SpawnEast": Vector2(MAP_WIDTH + 32.0, 832.0),
		"SpawnWest": Vector2(-32.0, 832.0),
	}
	for marker_name: String in spawn_positions:
		var marker: Marker2D = _wave_spawner.get_node_or_null(marker_name) as Marker2D
		if marker != null:
			marker.position = spawn_positions[marker_name]

func _refresh_placement_bounds() -> void:
	var manager: Node = get_node_or_null("PlantPlacementManager")
	if manager == null:
		return
	if manager.has_method("_update_garden_origin"):
		manager.call("_update_garden_origin")
	if manager.has_method("_rebuild_occupied_tiles"):
		manager.call("_rebuild_occupied_tiles")
	if manager.has_method("queue_redraw"):
		manager.queue_redraw()

func _spawn_daytime_resources() -> void:
	if not is_instance_valid(_pickup_container):
		return
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
	var has_day_one_count: bool = rule.has("day_one_count")
	if day == 1 and not has_day_one_count:
		return
	var positions: Array[Vector2] = _get_shuffled_positions(rule.get("positions", []), rng)
	if positions.is_empty():
		return
	var required_count: int = int(rule.get("minimum_count", 0))
	if day == 1 and has_day_one_count:
		required_count = int(rule["day_one_count"])
	required_count = clampi(required_count, 0, positions.size())

	var item_rarity: ItemDatabase.Rarity = ItemDatabase.get_rarity(str(rule.get("item_id", "petal_shard")))
	var base_chance: float = float(RARITY_SPAWN_CHANCE.get(item_rarity, 0.80))
	var effective_chance: float = base_chance
	if item_rarity != ItemDatabase.Rarity.COMMON:
		effective_chance = base_chance * pow(0.92, floor(float(day - 1) / 5.0))

	var spawned_count: int = 0
	var can_roll_extra: bool = not (day == 1 and has_day_one_count)
	for index: int in range(positions.size()):
		var should_spawn: bool = spawned_count < required_count
		if not should_spawn and can_roll_extra:
			should_spawn = rng.randf() <= effective_chance
		if should_spawn:
			_spawn_resource_pickup(rule, positions[index], spawned_count + 1)
			spawned_count += 1

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

func _spawn_resource_pickup(rule: Dictionary, pickup_position: Vector2, spawn_number: int) -> void:
	var pickup: Node2D = RESOURCE_PICKUP_SCENE.instantiate() as Node2D
	if pickup == null:
		return
	pickup.name = "%s%d" % [str(rule.get("prefix", "DaytimeResource")), spawn_number]
	pickup.position = pickup_position
	pickup.set("item_id", str(rule.get("item_id", "petal_shard")))
	pickup.set("amount", int(rule.get("amount", 1)))
	pickup.add_to_group(DAYTIME_RESOURCE_PICKUP_GROUP)
	_pickup_container.add_child(pickup)
