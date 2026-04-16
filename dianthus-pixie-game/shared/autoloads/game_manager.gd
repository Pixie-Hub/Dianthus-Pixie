extends Node

signal game_state_changed(new_state: String)
signal core_hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal game_over_triggered

enum GameState {
	EXPLORATION,
	PREPARATION,
	DEFENSE,
	GAME_OVER,
	TRANSITIONING,
}

var current_state: GameState = GameState.EXPLORATION
var dianthus_core: Node = null

var player_data: Dictionary = {
	"position": Vector2.ZERO,
	"last_zone": "",
	"inventory": {},
}

func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	game_state_changed.emit(GameState.keys()[new_state])


func register_core(core: Node) -> void:
	dianthus_core = core
	if core.has_signal("hp_changed"):
		core.hp_changed.connect(func(hp: int, max_hp: int) -> void: core_hp_changed.emit(hp, max_hp))
	if core.has_signal("core_destroyed"):
		core.core_destroyed.connect(_on_core_destroyed)


func _on_core_destroyed() -> void:
	set_state(GameState.GAME_OVER)
	game_over_triggered.emit()
