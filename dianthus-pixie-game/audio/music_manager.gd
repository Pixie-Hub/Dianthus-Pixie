extends Node

# Dynamic BGM controller for every track listed in docs/design/BGM_LIST.md.

const TRACKS: Dictionary = {
	"main_menu": "res://audio/music/main_menu.mp3",
	"exploration_day": "res://audio/music/exploration_day.mp3",
	"preparation_phase": "res://audio/music/preparation_phase.mp3",
	"night_combat_base": "res://audio/music/night_combat_base.mp3",
	"night_combat_intense": "res://audio/music/night_combat_intense.mp3",
	"surge_night": "res://audio/music/surge_night.mp3",
	"devourer_boss": "res://audio/music/devourer_boss.mp3",
	"ending_true": "res://audio/music/ending_true.mp3",
	"ending_survival": "res://audio/music/ending_survival.mp3",
	"ending_discovery": "res://audio/music/ending_discovery.mp3",
}

const LOOPING_TRACKS: Dictionary = {
	"main_menu": true,
	"exploration_day": true,
	"preparation_phase": true,
	"night_combat_base": true,
	"night_combat_intense": true,
	"surge_night": true,
	"devourer_boss": true,
	"ending_true": false,
	"ending_survival": false,
	"ending_discovery": false,
}

const BGM_VOLUME_DB: Dictionary = {
	"main_menu": -20.0,
	"exploration_day": -20.0,
	"preparation_phase": -20.0,
	"night_combat_base": -20.0,
	"night_combat_intense": -20.0,
	"surge_night": -20.0,
	"devourer_boss": -20.0,
	"ending_true": -20.0,
	"ending_survival": -20.0,
	"ending_discovery": -20.0,
}

const PREPARATION_THRESHOLD: float = 30.0
const FADE_DURATION: float = 1.5
const INTENSE_THRESHOLD: float = 0.5
const INTENSE_POLL_INTERVAL: float = 2.0
const MUFFLE_FADE: float = 0.3
const MUFFLE_VOLUME_OFFSET_DB: float = -8.0
const MUFFLE_LOWPASS_HZ: float = 800.0

var _player_a: AudioStreamPlayer = null
var _player_b: AudioStreamPlayer = null
var _player_intense: AudioStreamPlayer = null
var _active_player: AudioStreamPlayer = null

var _current_track: String = ""
var _intense_active: bool = false
var _in_prep_phase: bool = false
var _poll_timer: float = 0.0

var _cache: Dictionary = {}
var _fade_tween: Tween = null
var _intense_tween: Tween = null
var _muffle_tween: Tween = null
var _wave_spawner: Node = null
var _muffle_effect_index: int = -1
var _is_muffled: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player_a = _make_player("MusicA")
	_player_b = _make_player("MusicB")
	_player_intense = _make_player("MusicIntense")

	DayNightCycle.phase_changed.connect(_on_phase_changed)
	get_tree().root.child_entered_tree.connect(_on_scene_changed)
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)
	call_deferred("_setup_muffle_effect")
	call_deferred("_sync_to_current_context")


func _process(delta: float) -> void:
	if not DayNightCycle.is_night():
		_update_day_layers()
		return
	_poll_timer -= delta
	if _poll_timer <= 0.0:
		_poll_timer = INTENSE_POLL_INTERVAL
		_update_intense_layer()


func play_track(track_id: String, loop: Variant = null) -> void:
	if _current_track == track_id:
		return
	var stream: AudioStream = _get_stream(track_id)
	if stream == null:
		return
	_current_track = track_id
	var should_loop: bool = LOOPING_TRACKS.get(track_id, true) if loop == null else bool(loop)
	_crossfade_to(track_id, stream, should_loop)


func play_music(track_id: String) -> void:
	play_track(track_id)


func play_boss_music() -> void:
	play_devourer_boss()


func play_devourer_boss() -> void:
	play_track("devourer_boss", true)
	_set_intense(false, false)


func stop_music(fade: bool = true) -> void:
	_current_track = ""
	_is_muffled = false
	if fade:
		_fade_out_player(_active_player)
	else:
		_stop_player(_player_a)
		_stop_player(_player_b)
	_set_intense(false, false)
	var bus_idx: int = AudioServer.get_bus_index(&"Music")
	if bus_idx >= 0 and _muffle_effect_index >= 0:
		AudioServer.set_bus_effect_enabled(bus_idx, _muffle_effect_index, false)


func play_ending_music(ending_id: String) -> void:
	var track_id: String = "ending_" + ending_id
	if not TRACKS.has(track_id):
		track_id = "ending_survival"
	play_track(track_id, false)
	_set_intense(false, false)


func play_end(ending_id: String) -> void:
	play_ending_music(ending_id)


func get_track_path(track_id: String) -> String:
	return TRACKS.get(track_id, "")


func _sync_to_current_context() -> void:
	var scene: Node = get_tree().current_scene
	if _is_main_menu_scene(scene):
		play_track("main_menu")
	elif _is_gameplay_scene(scene):
		_play_current_phase_music()


func _play_current_phase_music() -> void:
	if DayNightCycle.is_night():
		_start_night_music()
	else:
		_set_intense(false, false)
		_in_prep_phase = false
		play_track("exploration_day")


func _on_phase_changed(phase: String) -> void:
	_in_prep_phase = false
	if phase == "NIGHT":
		_wave_spawner = null
		_start_night_music()
	elif phase == "DAY":
		_set_intense(false, false)
		play_track("exploration_day")


func _start_night_music() -> void:
	var day: int = DayNightCycle.day_count
	_poll_timer = 0.0
	_set_intense(false, false)
	_stop_player(_player_intense)
	if day % 7 == 0:
		play_track("surge_night")
	else:
		play_track("night_combat_base")
		_start_intense_player()


func _start_intense_player() -> void:
	var stream: AudioStream = _get_stream("night_combat_intense")
	if stream == null:
		return
	_apply_loop(stream, true)
	_player_intense.stream = stream
	_player_intense.volume_db = -80.0
	var playback_position: float = 0.0
	if is_instance_valid(_active_player) and _active_player.playing:
		playback_position = _active_player.get_playback_position()
	_player_intense.play(playback_position)


func _update_intense_layer() -> void:
	if _current_track == "surge_night":
		_set_intense(false, true)
		return
	var spawner: Node = _get_wave_spawner()
	if spawner == null:
		_set_intense(false, true)
		return
	var alive: int = spawner.get_alive_count()
	var total: int = spawner.get_wave_total()
	var should_be_intense: bool = (total > 0) and (float(alive) / float(total) > INTENSE_THRESHOLD)
	_set_intense(should_be_intense, true)


func _set_intense(on: bool, fade: bool = true) -> void:
	if on == _intense_active:
		if not on and not fade:
			_stop_player(_player_intense)
		return
	_intense_active = on
	if _intense_tween:
		_intense_tween.kill()
	if on and not _player_intense.playing:
		_start_intense_player()
	if fade:
		_intense_tween = create_tween()
		_intense_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var target_db: float = 0.0 if on else -80.0
		target_db = _get_track_volume_db("night_combat_intense") if on else target_db
		_intense_tween.tween_property(_player_intense, "volume_db", target_db, FADE_DURATION)
		if not on:
			_intense_tween.tween_callback(_player_intense.stop)
	else:
		_player_intense.volume_db = _get_track_volume_db("night_combat_intense") if on else -80.0
		if not on:
			_player_intense.stop()


func _update_day_layers() -> void:
	if _current_track == "exploration_day":
		var remaining: float = DayNightCycle.get_time_remaining()
		if remaining <= PREPARATION_THRESHOLD and not _in_prep_phase:
			_in_prep_phase = true
			play_track("preparation_phase")
	elif _current_track == "preparation_phase":
		var remaining: float = DayNightCycle.get_time_remaining()
		if remaining > PREPARATION_THRESHOLD:
			_in_prep_phase = false
			play_track("exploration_day")


func _on_scene_changed(node: Node) -> void:
	await get_tree().process_frame
	var scene: Node = get_tree().current_scene
	var target_scene: Node = scene
	if target_scene == null and is_instance_valid(node):
		target_scene = node
	if _is_main_menu_scene(target_scene):
		stop_music(false)
		_current_track = ""
		_in_prep_phase = false
		play_track("main_menu")
	elif _is_gameplay_scene(target_scene):
		_play_current_phase_music()


func _crossfade_to(track_id: String, stream: AudioStream, loop: bool) -> void:
	var incoming: AudioStreamPlayer = _player_b if _active_player == _player_a else _player_a
	var outgoing: AudioStreamPlayer = _active_player

	_apply_loop(stream, loop)
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()
	_active_player = incoming

	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	var target_vol: float = _get_track_volume_db(track_id)
	if _is_muffled:
		target_vol += MUFFLE_VOLUME_OFFSET_DB
	_fade_tween.tween_property(incoming, "volume_db", target_vol, FADE_DURATION)
	if is_instance_valid(outgoing):
		_fade_tween.tween_property(outgoing, "volume_db", -80.0, FADE_DURATION)
		_fade_tween.chain().tween_callback(outgoing.stop)


func _fade_out_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or not player.playing:
		return
	var t: Tween = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(player, "volume_db", -80.0, FADE_DURATION)
	t.tween_callback(player.stop)


func _stop_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.stop()
	player.volume_db = -80.0


func _make_player(player_name: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = player_name
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.bus = &"Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func _get_stream(track_id: String) -> AudioStream:
	if _cache.has(track_id):
		return _cache[track_id]
	var path: String = TRACKS.get(track_id, "")
	if path.is_empty():
		push_warning("[MusicManager] Unknown track_id: %s" % track_id)
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("[MusicManager] Could not load track: %s" % path)
		return null
	_cache[track_id] = stream
	return stream


func _get_track_volume_db(track_id: String) -> float:
	return float(BGM_VOLUME_DB.get(track_id, 0.0))


func _apply_loop(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop


func _is_main_menu_scene(node: Variant) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	return node.name == "MainMenu" or node.scene_file_path.ends_with("main_menu.tscn")


func _is_gameplay_scene(node: Variant) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	return node.scene_file_path.begins_with("res://world/zones/")


func _get_wave_spawner() -> Node:
	if is_instance_valid(_wave_spawner):
		return _wave_spawner
	_wave_spawner = get_tree().get_first_node_in_group("wave_spawners")
	if _wave_spawner == null:
		var scene: Node = get_tree().current_scene
		if scene != null:
			_wave_spawner = scene.find_child("WaveSpawner", true, false)
	return _wave_spawner


func _setup_muffle_effect() -> void:
	var bus_idx: int = AudioServer.get_bus_index(&"Music")
	if bus_idx < 0:
		return
	var effect: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	effect.cutoff_hz = MUFFLE_LOWPASS_HZ
	effect.resonance = 0.5
	AudioServer.add_bus_effect(bus_idx, effect)
	_muffle_effect_index = AudioServer.get_bus_effect_count(bus_idx) - 1
	AudioServer.set_bus_effect_enabled(bus_idx, _muffle_effect_index, false)


func _on_pause_state_changed(is_paused: bool) -> void:
	set_muffle(is_paused)


func set_muffle(on: bool) -> void:
	if on == _is_muffled:
		return
	_is_muffled = on
	var bus_idx: int = AudioServer.get_bus_index(&"Music")
	if bus_idx < 0:
		return
	if _muffle_tween and _muffle_tween.is_valid():
		_muffle_tween.kill()
	_muffle_tween = create_tween()
	_muffle_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var base_vol: float = _get_track_volume_db(_current_track) if not _current_track.is_empty() else 0.0
	var target_vol: float = base_vol + MUFFLE_VOLUME_OFFSET_DB if on else base_vol
	if is_instance_valid(_active_player):
		_muffle_tween.tween_property(_active_player, "volume_db", target_vol, MUFFLE_FADE)
	if _muffle_effect_index >= 0:
		AudioServer.set_bus_effect_enabled(bus_idx, _muffle_effect_index, on)
