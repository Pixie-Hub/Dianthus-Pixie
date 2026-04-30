extends Node

const SAME_SFX_MIN_INTERVAL_MS: int = 35
const SAME_SFX_MAX_PER_FRAME: int = 1
const GLOBAL_PLAYERS_PATH: NodePath = ^"GlobalPlayers"
const SPATIAL_PLAYERS_PATH: NodePath = ^"SpatialPlayers"
const GLOBAL_PLAYER_MAX_DISTANCE: float = 1000000.0

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

const SFX_VOLUME_DB: Dictionary = {
	"thorn_sword_swing": -10.0,
	"blazeblade_swing": -10.0,
	"blazeblade_hit": -2.0,
	"screen_open": -4.0,
	"screen_close": -4.0,
	"plant_placed": 10.0,
	"core_energy_tick": 0.0,
	"weapon_equipped": -6.0,
	"player_take_damage": -10.0,
	"void_grenade_detonate": 16.0,
	"vine_whip_pull": -14.0,
	"crystal_lash_crack": 6.0,
	"petal_shield_raise": 4.0,
	"petal_shield_block": 16.0,
	"petal_shield_counter": -4.0,
	"iron_bloom_shield_raise": 6.0,
	"player_death": -4.0,
	"player_respawn": -4.0,
	"rafflesia_miasma_hun": -14.0,
	"wijaya_kusuma_attack": 6.0,
	"beringin_wall_spawn": -12.0,
	"beringin_wall_break": -6.0,
	"kecombrang_speed_boost": -6.0,
	"kunyit_melee_buff": -10.0,
	"baja_kuning_armor_buff": -4.0,
	"enemy_hit": 4.0,
	"stonehusk_attack": -8.0,
	"stonehusk_death": -4.0,
	"phantom_weaver_attack": -12.0,
	"phantom_weaver_death": -10.0,
	"swarm_larva_skitter": -6.0,
	"core_take_damage": 8.0,

}

const SFX_PITCH_RANDOMIZATION: Dictionary = {
	"baja_kuning_armor_buff": 0.04,
	"beringin_wall_break": 0.05,
	"beringin_wall_spawn": 0.04,
	"blazeblade_hit": 0.06,
	"blazeblade_swing": 0.05,
	"bougainvillea_thorn_tick": 0.08,
	"breeding_fail": 0.03,
	"bunga_api_burn_tick": 0.08,
	"bunga_bayang_attack": 0.06,
	"core_energy_tick": 0.06,
	"core_heal": 0.04,
	"core_low_hp": 0.03,
	"core_take_damage": 0.06,
	"crafting_fail": 0.03,
	"enemy_hit": 0.08,
	"harvest_qte_fail": 0.04,
	"harvest_qte_prompt": 0.04,
	"harvest_qte_success": 0.04,
	"inventory_full": 0.04,
	"item_pickup": 0.06,
	"item_stack": 0.06,
	"kecombrang_speed_boost": 0.04,
	"kunyit_melee_buff": 0.04,
	"melati_emas_regen_pulse": 0.06,
	"melati_energy_pulse": 0.06,
	"minigame_tap_correct": 0.05,
	"minigame_tap_miss": 0.05,
	"phantom_weaver_attack": 0.05,
	"phantom_weaver_death": 0.04,
	"phantom_weaver_teleport": 0.05,
	"plant_destroyed": 0.05,
	"plant_placed": 0.05,
	"player_invincibility": 0.03,
	"player_take_damage": 0.06,
	"rafflesia_miasma_hum": 0.03,
	"screen_close": 0.03,
	"screen_open": 0.03,
	"shadowling_attack": 0.05,
	"shadowling_death": 0.04,
	"shadowling_footstep": 0.08,
	"shadowling_retreat": 0.05,
	"spore_bomb_detonate": 0.06,
	"spore_bomb_throw": 0.05,
	"stonehusk_attack": 0.05,
	"stonehusk_death": 0.04,
	"stonehusk_footstep": 0.07,
	"swarm_larva_death": 0.05,
	"swarm_larva_skitter": 0.08,
	"thorn_sword_hit": 0.06,
	"thorn_sword_swing": 0.08,
	"ui_button_click": 0.04,
	"vine_whip_crack": 0.06,
	"vine_whip_pull": 0.06,
	"void_grenade_detonate": 0.06,
	"voidrunner_charge": 0.04,
	"voidrunner_death": 0.04,
	"wijaya_kusuma_attack": 0.06,
}

var _global_players_by_id: Dictionary = {}
var _spatial_players_by_id: Dictionary = {}
var _cache: Dictionary = {}
var _players_ready: bool = false
var _last_play_msec_by_id: Dictionary = {}
var _last_play_frame_by_id: Dictionary = {}
var _plays_this_frame_by_id: Dictionary = {}


func _ready() -> void:
	_ensure_players_ready()


func play(sfx_id: String, pitch_rand: float = 0.0) -> void:
	_ensure_players_ready()
	if not _can_play_now(sfx_id):
		return
	var player: AudioStreamPlayer2D = _get_named_player(_global_players_by_id, sfx_id, "global")
	if player == null or not _prepare_player(player, sfx_id):
		return
	player.global_position = _global_playback_position()
	_apply_pitch(player, _pitch_randomization_for(sfx_id, pitch_rand))
	player.volume_db = SFX_VOLUME_DB.get(sfx_id, 0.0)
	player.play()


func play_at(sfx_id: String, world_position: Vector2, pitch_rand: float = 0.0) -> void:
	_ensure_players_ready()
	if not _can_play_now(sfx_id):
		return
	var player: AudioStreamPlayer2D = _get_named_player(_spatial_players_by_id, sfx_id, "spatial")
	if player == null or not _prepare_player(player, sfx_id):
		return
	player.global_position = world_position
	_apply_pitch(player, _pitch_randomization_for(sfx_id, pitch_rand))
	player.volume_db = SFX_VOLUME_DB.get(sfx_id, 0.0)
	player.play()


func _can_play_now(sfx_id: String) -> bool:
	var frame: int = Engine.get_process_frames()
	var last_frame: int = int(_last_play_frame_by_id.get(sfx_id, -1))
	var plays_this_frame: int = 0
	if last_frame == frame:
		plays_this_frame = int(_plays_this_frame_by_id.get(sfx_id, 0))
	if plays_this_frame >= SAME_SFX_MAX_PER_FRAME:
		return false

	var now_msec: int = Time.get_ticks_msec()
	var last_msec: int = int(_last_play_msec_by_id.get(sfx_id, -SAME_SFX_MIN_INTERVAL_MS))
	if now_msec - last_msec < SAME_SFX_MIN_INTERVAL_MS:
		return false

	_last_play_frame_by_id[sfx_id] = frame
	_plays_this_frame_by_id[sfx_id] = plays_this_frame + 1
	_last_play_msec_by_id[sfx_id] = now_msec
	return true


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


func _ensure_players_ready() -> void:
	if _players_ready:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_global_players_by_id = _collect_named_players(GLOBAL_PLAYERS_PATH, true)
	_spatial_players_by_id = _collect_named_players(SPATIAL_PLAYERS_PATH, false)
	_warn_missing_players("global", _global_players_by_id)
	_warn_missing_players("spatial", _spatial_players_by_id)
	_players_ready = true


func _collect_named_players(pool_path: NodePath, neutral_positioning: bool) -> Dictionary:
	var result: Dictionary = {}
	var parent: Node = get_node_or_null(pool_path)
	if parent == null:
		push_warning("[SfxManager] Missing SFX player pool: %s" % pool_path)
		return result
	parent.process_mode = Node.PROCESS_MODE_ALWAYS
	for child: Node in parent.get_children():
		var player: AudioStreamPlayer2D = child as AudioStreamPlayer2D
		if player == null:
			continue
		_configure_player(player, neutral_positioning)
		var sfx_id: String = String(player.name)
		if not SFX.has(sfx_id):
			push_warning("[SfxManager] Scene player node is not a registered sfx_id: %s" % sfx_id)
			continue
		result[sfx_id] = player
	return result


func _warn_missing_players(pool_label: String, players_by_id: Dictionary) -> void:
	for sfx_id: String in SFX.keys():
		if not players_by_id.has(sfx_id):
			push_warning("[SfxManager] Missing %s player node for sfx_id: %s" % [pool_label, sfx_id])


func _get_named_player(players_by_id: Dictionary, sfx_id: String, pool_label: String) -> AudioStreamPlayer2D:
	if not SFX.has(sfx_id):
		push_warning("[SfxManager] Unknown sfx_id: %s" % sfx_id)
		return null
	var player: AudioStreamPlayer2D = players_by_id.get(sfx_id, null) as AudioStreamPlayer2D
	if player == null:
		push_warning("[SfxManager] Missing %s player node for sfx_id: %s" % [pool_label, sfx_id])
	return player


func _prepare_player(player: AudioStreamPlayer2D, sfx_id: String) -> bool:
	if player.stream != null:
		return true
	player.stream = _get_stream(sfx_id)
	return player.stream != null


func _apply_pitch(player: AudioStreamPlayer2D, pitch_rand: float) -> void:
	if pitch_rand > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	else:
		player.pitch_scale = 1.0


func _pitch_randomization_for(sfx_id: String, explicit_pitch_rand: float) -> float:
	if explicit_pitch_rand > 0.0:
		return explicit_pitch_rand
	return SFX_PITCH_RANDOMIZATION.get(sfx_id, 0.0)


func _configure_player(player: AudioStreamPlayer2D, neutral_positioning: bool) -> void:
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = &"SFX"
	if neutral_positioning:
		player.panning_strength = 0.0
		player.max_distance = GLOBAL_PLAYER_MAX_DISTANCE


func _global_playback_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return Vector2.ZERO
	return camera.global_position
