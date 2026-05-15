extends Node

signal game_state_changed(new_state: String)
signal core_hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal game_over_triggered
signal player_hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
signal player_energy_changed(current_energy: int, max_energy: int)
signal loadout_changed(weapon_slots: Array, skill_id: String, selected_slot: int)
signal player_registered(player: Node)
signal night_survived(day: int)
signal ending_triggered(ending_id: String)
signal colorblind_mode_changed(enabled: bool)

enum GameState {
	EXPLORATION,
	DEFENSE,
	GAME_OVER,
	TRANSITIONING,
}

var current_state: GameState = GameState.EXPLORATION
var dianthus_core: Node = null
var player: Node = null
var colorblind_mode: bool = false
var endless_mode: bool = false
var core_current_hp: int = -1
var core_max_hp: int = 500

var player_data: Dictionary = {
	"position": Vector2.ZERO,
	"last_zone": "",
}

func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	game_state_changed.emit(GameState.keys()[new_state])


func set_colorblind_mode(enabled: bool) -> void:
	if colorblind_mode == enabled:
		return
	colorblind_mode = enabled
	colorblind_mode_changed.emit(enabled)
	print("[GameManager] Colorblind mode: %s" % ("ON" if enabled else "OFF"))


func reset_core_runtime_state() -> void:
	dianthus_core = null
	core_current_hp = -1
	core_max_hp = 500


func register_core(core: Node) -> void:
	dianthus_core = core
	if core_current_hp >= 0 and core.has_method("set"):
		core.set("current_hp", clampi(core_current_hp, 0, core_max_hp))
	elif core.get("current_hp") != null:
		core_current_hp = int(core.get("current_hp"))
	if core.get("MAX_HP") != null:
		core_max_hp = int(core.get("MAX_HP"))
	if core.has_signal("hp_changed") and not core.hp_changed.is_connected(_on_core_hp_changed):
		core.hp_changed.connect(_on_core_hp_changed)
	if core.has_signal("core_destroyed") and not core.core_destroyed.is_connected(_on_core_destroyed):
		core.core_destroyed.connect(_on_core_destroyed)
	if core.has_method("_update_aura"):
		core.call("_update_aura")
	core_hp_changed.emit(core_current_hp, core_max_hp)


func _on_core_hp_changed(hp: int, max_hp: int) -> void:
	core_current_hp = hp
	core_max_hp = max_hp
	core_hp_changed.emit(hp, max_hp)


func set_core_hp_from_save(hp: int, max_hp: int = 500) -> void:
	core_max_hp = max(1, max_hp)
	core_current_hp = clampi(hp, 0, core_max_hp)
	if is_instance_valid(dianthus_core) and dianthus_core.get("current_hp") != null:
		dianthus_core.set("current_hp", core_current_hp)
		if dianthus_core.has_method("_update_aura"):
			dianthus_core.call("_update_aura")
	core_hp_changed.emit(core_current_hp, core_max_hp)


func apply_core_damage(amount: int) -> void:
	if amount <= 0 or current_state == GameState.GAME_OVER:
		return
	if is_instance_valid(dianthus_core) and dianthus_core.has_method("take_damage"):
		dianthus_core.call("take_damage", amount)
		return
	if core_current_hp < 0:
		core_current_hp = core_max_hp
	core_current_hp = max(core_current_hp - amount, 0)
	core_hp_changed.emit(core_current_hp, core_max_hp)
	SfxManager.play("core_take_damage")
	if core_current_hp <= 0:
		_on_core_destroyed()


func get_core_hp_ratio() -> float:
	if core_max_hp <= 0:
		return 0.0
	if core_current_hp < 0:
		return 1.0
	return clampf(float(core_current_hp) / float(core_max_hp), 0.0, 1.0)


func _on_core_destroyed() -> void:
	core_current_hp = 0
	core_hp_changed.emit(core_current_hp, core_max_hp)
	if current_state == GameState.GAME_OVER:
		return
	set_state(GameState.GAME_OVER)
	game_over_triggered.emit()


func trigger_night_survived() -> void:
	night_survived.emit(DayNightCycle.day_count)


func register_player(p: Node) -> void:
	player = p
	player_registered.emit(p)
	if p.has_signal("hp_changed"):
		p.hp_changed.connect(func(hp: int, max_hp: int) -> void: player_hp_changed.emit(hp, max_hp))
	if p.has_signal("player_died"):
		p.player_died.connect(func() -> void: player_died.emit())
	if p.has_signal("player_respawned"):
		p.player_respawned.connect(func() -> void: player_respawned.emit())
	if p.has_signal("energy_changed"):
		p.energy_changed.connect(
			func(e: int, m: int) -> void: player_energy_changed.emit(e, m))
	if p.has_signal("loadout_changed"):
		p.loadout_changed.connect(
			func(slots: Array, sid: String, sel: int) -> void: loadout_changed.emit(slots, sid, sel))
		var slots: Array = p.get("weapon_slots") as Array
		var skill_id: String = str(p.get("active_skill_id"))
		var selected_slot: int = int(p.get("selected_weapon_slot"))
		loadout_changed.emit(slots, skill_id, selected_slot)
