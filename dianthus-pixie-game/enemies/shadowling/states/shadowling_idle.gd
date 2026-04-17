extends State

var _phase_connection: Callable


func enter() -> void:
	if DayNightCycle.is_night():
		state_machine.transition_to(&"Scout")
		return
	_phase_connection = func(phase: String) -> void:
		if phase == "NIGHT":
			state_machine.transition_to(&"Scout")
	DayNightCycle.phase_changed.connect(_phase_connection)


func exit() -> void:
	if _phase_connection.is_valid() and DayNightCycle.phase_changed.is_connected(_phase_connection):
		DayNightCycle.phase_changed.disconnect(_phase_connection)
