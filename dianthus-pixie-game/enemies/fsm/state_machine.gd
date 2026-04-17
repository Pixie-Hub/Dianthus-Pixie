class_name StateMachine
extends Node

@export var initial_state: StringName = &"Idle"

var current_state: State = null
var _states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			_states[StringName(child.name)] = child
			child.enemy = get_parent() as CharacterBody2D
			child.state_machine = self
	if _states.has(initial_state):
		current_state = _states[initial_state]
		current_state.enter()


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func transition_to(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_warning("StateMachine: unknown state '%s'" % state_name)
		return
	if current_state != null:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter()
