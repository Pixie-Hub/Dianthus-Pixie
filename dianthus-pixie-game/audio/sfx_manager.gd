extends Node

const POOL_SIZE: int = 16

const SFX: Dictionary = {
	# Combat — Player Attacks
	"thorn_sword_swing":         "res://audio/sfx/combat/player_attack/Thorn Sword swing.wav",
	"thorn_sword_hit":           "res://audio/sfx/combat/player_attack/Thorn Sword hit (flesh).wav",
	"blazeblade_swing":          "res://audio/sfx/combat/player_attack/Blazeblade swing.wav",
	"blazeblade_hit":            "res://audio/sfx/combat/player_attack/Blazeblade hit.wav",
	"vine_whip_crack":           "res://audio/sfx/combat/player_attack/Vine Whip crack.wav",
	"vine_whip_pull":            "res://audio/sfx/combat/player_attack/Vine Whip pull.wav",
	"crystal_lash_crack":        "res://audio/sfx/combat/player_attack/Crystal Lash crack.wav",
	"spore_bomb_throw":          "res://audio/sfx/combat/player_attack/Spore Bomb throw.wav",
	"spore_bomb_detonate":       "res://audio/sfx/combat/player_attack/Spore Bomb detonate.wav",
	"void_grenade_detonate":     "res://audio/sfx/combat/player_attack/Void Grenade detonate.wav",
	"petal_shield_raise":        "res://audio/sfx/combat/player_attack/Petal Shield raise.wav",
	"petal_shield_block":        "res://audio/sfx/combat/player_attack/Petal Shield block.wav",
	"petal_shield_counter":      "res://audio/sfx/combat/player_attack/Petal Shield perfect counter.wav",
	"iron_bloom_shield_raise":   "res://audio/sfx/combat/player_attack/Iron Bloom Shield raise.wav",
	# Combat — Player State
	"player_take_damage":        "res://audio/sfx/combat/player_state/player_take_damage.wav",
	"player_death":              "res://audio/sfx/combat/player_state/player_death.wav",
	"player_respawn":            "res://audio/sfx/combat/player_state/player_respawn.wav",
	"player_invincibility":      "res://audio/sfx/combat/player_state/player_invincibility_active.wav",
	# Plants
	"plant_placed":              "res://audio/sfx/plants/plant_placed.wav",
	"plant_destroyed":           "res://audio/sfx/plants/Plant Destroyed (Wither).wav",
	"bougainvillea_thorn_tick":  "res://audio/sfx/plants/bougainvillea_thorn_tick.wav",
	"rafflesia_miasma_hum":      "res://audio/sfx/plants/rafflesia_miasma_hum.wav",
	"melati_energy_pulse":       "res://audio/sfx/plants/melati_energy_regen_pulse.wav",
	"wijaya_kusuma_attack":      "res://audio/sfx/plants/wijaya_kusuma_auto-attack_fire.wav",
	"beringin_wall_spawn":       "res://audio/sfx/plants/beringin_root_wall_spawn.wav",
	"beringin_wall_break":       "res://audio/sfx/plants/beringin_root_wall_break.wav",
	"kecombrang_speed_boost":    "res://audio/sfx/plants/Kecombrang Attack Speed Boost.wav",
	"kunyit_melee_buff":         "res://audio/sfx/plants/Kunyit Melee Buff Active.wav",
	"bunga_api_burn_tick":       "res://audio/sfx/plants/Bunga Api Burn Tick.wav",
	"bunga_bayang_attack":       "res://audio/sfx/plants/Bunga Bayang Auto-Attack.wav",
	"melati_emas_regen_pulse":   "res://audio/sfx/plants/Melati Emas Regen Pulse.wav",
	"baja_kuning_armor_buff":    "res://audio/sfx/plants/Baja Kuning Armor Buff.wav",
	# Enemies
	"enemy_hit":                 "res://audio/sfx/enemies/Enemy Hit (Generic).wav",
	"shadowling_footstep":       "res://audio/sfx/enemies/Shadowling Footstep.wav",
	"shadowling_attack":         "res://audio/sfx/enemies/Shadowling Attack.wav",
	"shadowling_retreat":        "res://audio/sfx/enemies/Shadowling Retreat.wav",
	"shadowling_death":          "res://audio/sfx/enemies/Shadowling Death.wav",
	"voidrunner_charge":         "res://audio/sfx/enemies/Voidrunner Charge (Spawn).wav",
	"voidrunner_death":          "res://audio/sfx/enemies/Voidrunner Death.wav",
	"stonehusk_footstep":        "res://audio/sfx/enemies/Stonehusk Footstep.wav",
	"stonehusk_attack":          "res://audio/sfx/enemies/Stonehusk Attack.wav",
	"stonehusk_death":           "res://audio/sfx/enemies/Stonehusk Death.wav",
	"phantom_weaver_teleport":   "res://audio/sfx/enemies/Phantom Weaver Teleport.wav",
	"phantom_weaver_attack":     "res://audio/sfx/enemies/Phantom Weaver Attack.wav",
	"phantom_weaver_death":      "res://audio/sfx/enemies/Phantom Weaver Death.wav",
	"swarm_larva_skitter":       "res://audio/sfx/enemies/Swarm Larva Group Skitter.wav",
	"swarm_larva_death":         "res://audio/sfx/enemies/Swarm Larva Individual Death.wav",
	# Dianthus Core
	"core_take_damage":          "res://audio/sfx/core/Core Take Damage.wav",
	"core_low_hp":               "res://audio/sfx/core/Core Low HP Warning.wav",
	"core_destroyed":            "res://audio/sfx/core/Core Destroyed (Game Over).wav",
	"core_heal":                 "res://audio/sfx/core/Core Heal.wav",
	"core_energy_tick":          "res://audio/sfx/core/Core Energy Passive Tick.wav",
	# Crafting & UI
	"crafting_success":          "res://audio/sfx/crafting_ui/Crafting Success.wav",
	"crafting_fail":             "res://audio/sfx/crafting_ui/Crafting Fail.wav",
	"weapon_equipped":           "res://audio/sfx/crafting_ui/Weapon Equipped.wav",
	"inventory_open":            "res://audio/sfx/crafting_ui/Inventory Open.wav",
	"inventory_close":           "res://audio/sfx/crafting_ui/Inventory Close.wav",
	"screen_close":              "res://audio/sfx/crafting_ui/Screen Close.wav",
	"item_pickup":               "res://audio/sfx/crafting_ui/Item Pickup.wav",
	"item_stack":                "res://audio/sfx/crafting_ui/Item Add to Inventory (Stack).wav",
	"inventory_full":            "res://audio/sfx/crafting_ui/Inventory Full.wav",
	"ui_button_click":           "res://audio/sfx/crafting_ui/UI Button Click.wav",
	"screen_open":               "res://audio/sfx/crafting_ui/Screen Open.wav",
	# Cross-Breeding
	"breeding_start":            "res://audio/sfx/crossbreeding/Breeding Start.wav",
	"breeding_success":          "res://audio/sfx/crossbreeding/Breeding Success.wav",
	"breeding_fail":             "res://audio/sfx/crossbreeding/Breeding Fail.wav",
	"breeding_critical_fail":    "res://audio/sfx/crossbreeding/Breeding Critical Fail.wav",
	"combo_discovered":          "res://audio/sfx/crossbreeding/New Combo Discovered.wav",
	# Night / Wave Events
	"night_transition":          "res://audio/sfx/night_wave_events/Night Transition.wav",
	"wave_start":                "res://audio/sfx/night_wave_events/Wave Start.wav",
	"wave_cleared":              "res://audio/sfx/night_wave_events/Wave Cleared.wav",
	"surge_night_warning":       "res://audio/sfx/night_wave_events/Surge Night Warning.wav",
	"dawn_transition":           "res://audio/sfx/night_wave_events/Dawn Transition.wav",
	"night_survived":            "res://audio/sfx/night_wave_events/Night Survived Screen Appear.wav",
	# Quest & Story
	"quest_accepted":            "res://audio/sfx/quest_story/quest_accepted.wav",
	"quest_completed":           "res://audio/sfx/quest_story/quest_completed.wav",
	"quest_failed":              "res://audio/sfx/quest_story/quest_failed.wav",
	"codex_unlocked":            "res://audio/sfx/quest_story/codex_entry_unlocked.wav",
	"ending_screen":             "res://audio/sfx/quest_story/ending_screen.wav",
	"endless_mode_activate":     "res://audio/sfx/quest_story/endless_mode_activate.wav",
	# Minigames
	"minigame_tap_correct":      "res://audio/sfx/minigames/Minigame Rhythm Tap (Correct).wav",
	"minigame_tap_miss":         "res://audio/sfx/minigames/Minigame Rhythm Tap (Miss).wav",
	"harvest_qte_prompt":        "res://audio/sfx/minigames/Harvest QTE Prompt.wav",
	"harvest_qte_success":       "res://audio/sfx/minigames/Harvest QTE Success.wav",
	"harvest_qte_fail":          "res://audio/sfx/minigames/Harvest QTE Fail.wav",
}

var _pool: Array[AudioStreamPlayer] = []
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _cache: Dictionary = {}
var _pool_index: int = 0
var _pool_2d_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	for i: int in range(POOL_SIZE):
		var p2: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		p2.process_mode = Node.PROCESS_MODE_ALWAYS
		p2.bus = &"SFX"
		add_child(p2)
		_pool_2d.append(p2)


func play(sfx_id: String, pitch_rand: float = 0.0) -> void:
	var stream: AudioStream = _get_stream(sfx_id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _next_player()
	if player == null:
		return
	player.stream = stream
	if pitch_rand > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	else:
		player.pitch_scale = 1.0
	player.play()


func play_at(sfx_id: String, world_position: Vector2, pitch_rand: float = 0.0) -> void:
	var stream: AudioStream = _get_stream(sfx_id)
	if stream == null:
		return
	var player: AudioStreamPlayer2D = _next_player_2d()
	if player == null:
		return
	player.stream = stream
	player.global_position = world_position
	if pitch_rand > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	else:
		player.pitch_scale = 1.0
	player.play()


func _get_stream(sfx_id: String) -> AudioStream:
	if _cache.has(sfx_id):
		return _cache[sfx_id]
	var path: String = SFX.get(sfx_id, "")
	if path.is_empty():
		push_warning("[SfxManager] Unknown sfx_id: %s" % sfx_id)
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("[SfxManager] Could not load SFX: %s" % path)
		return null
	_cache[sfx_id] = stream
	return stream


func _next_player() -> AudioStreamPlayer:
	if _pool.is_empty():
		return null
	var player: AudioStreamPlayer = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	return player


func _next_player_2d() -> AudioStreamPlayer2D:
	if _pool_2d.is_empty():
		return null
	var player: AudioStreamPlayer2D = _pool_2d[_pool_2d_index]
	_pool_2d_index = (_pool_2d_index + 1) % POOL_SIZE
	return player
