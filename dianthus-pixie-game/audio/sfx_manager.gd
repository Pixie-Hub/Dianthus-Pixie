extends Node

const SAME_SFX_MIN_INTERVAL_MS: int = 35
const SAME_SFX_MAX_PER_FRAME: int = 1
const GLOBAL_PLAYERS_PATH: NodePath = ^"GlobalPlayers"
const SPATIAL_PLAYERS_PATH: NodePath = ^"SpatialPlayers"

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

var _global_pool: Node = null
var _spatial_pool: Node = null
var _last_play_msec_by_id: Dictionary = {}
var _last_play_frame_by_id: Dictionary = {}
var _plays_this_frame_by_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_global_pool = get_node_or_null(GLOBAL_PLAYERS_PATH)
	_spatial_pool = get_node_or_null(SPATIAL_PLAYERS_PATH)


func play(sfx_id: String, pitch_rand: float = 0.0) -> void:
	if not _can_play_now(sfx_id):
		return
	var player: AudioStreamPlayer2D = _find_player(_global_pool, sfx_id)
	if player == null:
		return
	player.global_position = _global_playback_position()
	_apply_pitch(player, _pitch_randomization_for(sfx_id, pitch_rand))
	player.play()


func play_at(sfx_id: String, world_position: Vector2, pitch_rand: float = 0.0) -> void:
	if not _can_play_now(sfx_id):
		return
	var player: AudioStreamPlayer2D = _find_player(_spatial_pool, sfx_id)
	if player == null:
		return
	player.global_position = world_position
	_apply_pitch(player, _pitch_randomization_for(sfx_id, pitch_rand))
	player.play()


func _find_player(pool: Node, sfx_id: String) -> AudioStreamPlayer2D:
	if pool == null:
		push_warning("[SfxManager] Player pool is null when looking for: %s" % sfx_id)
		return null
	var player: AudioStreamPlayer2D = pool.get_node_or_null(NodePath(sfx_id)) as AudioStreamPlayer2D
	if player == null:
		push_warning("[SfxManager] No player node found for sfx_id: %s" % sfx_id)
	return player


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


func _apply_pitch(player: AudioStreamPlayer2D, pitch_rand: float) -> void:
	if pitch_rand > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	else:
		player.pitch_scale = 1.0


func _pitch_randomization_for(sfx_id: String, explicit_pitch_rand: float) -> float:
	if explicit_pitch_rand > 0.0:
		return explicit_pitch_rand
	return SFX_PITCH_RANDOMIZATION.get(sfx_id, 0.0)


func _global_playback_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return Vector2.ZERO
	return camera.global_position
