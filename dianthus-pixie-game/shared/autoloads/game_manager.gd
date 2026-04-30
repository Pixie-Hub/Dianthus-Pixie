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


func register_core(core: Node) -> void:
	dianthus_core = core
	if core.has_signal("hp_changed"):
		core.hp_changed.connect(func(hp: int, max_hp: int) -> void: core_hp_changed.emit(hp, max_hp))
	if core.has_signal("core_destroyed"):
		core.core_destroyed.connect(_on_core_destroyed)


func _on_core_destroyed() -> void:
	set_state(GameState.GAME_OVER)
	game_over_triggered.emit()


func trigger_night_survived() -> void:
	night_survived.emit(DayNightCycle.day_count)


func register_player(p: Node) -> void:
	player = p
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
