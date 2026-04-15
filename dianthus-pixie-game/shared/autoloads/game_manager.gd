extends Node

signal game_state_changed(new_state: String)

enum GameState {
	EXPLORATION,
	PREPARATION,
	DEFENSE,
	GAME_OVER,
	TRANSITIONING,
}

var current_state: GameState = GameState.EXPLORATION

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
