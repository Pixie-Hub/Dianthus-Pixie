extends Node

const SAME_SFX_MIN_INTERVAL_MS: int = 35
const SAME_SFX_MAX_PER_FRAME: int = 1
const GLOBAL_PLAYERS_PATH: NodePath = ^"GlobalPlayers"
const SPATIAL_PLAYERS_PATH: NodePath = ^"SpatialPlayers"

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
	_apply_pitch(player, pitch_rand)
	player.play()


func play_at(sfx_id: String, world_position: Vector2, pitch_rand: float = 0.0) -> void:
	if not _can_play_now(sfx_id):
		return
	var player: AudioStreamPlayer2D = _find_player(_spatial_pool, sfx_id)
	if player == null:
		return
	player.global_position = world_position
	_apply_pitch(player, pitch_rand)
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


func _apply_pitch(player: AudioStreamPlayer2D, override_pitch_rand: float) -> void:
	var pitch_rand: float = override_pitch_rand
	if pitch_rand <= 0.0 and player.has_meta(&"pitch_rand_range"):
		pitch_rand = float(player.get_meta(&"pitch_rand_range"))
	if pitch_rand > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	else:
		player.pitch_scale = 1.0


func _global_playback_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return Vector2.ZERO
	return camera.global_position
