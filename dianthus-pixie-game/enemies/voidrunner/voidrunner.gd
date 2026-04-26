class_name Voidrunner
extends EnemyBase


func _ready() -> void:
	super._ready()


func activate() -> void:
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Rush")


# Override: Voidrunner never retreats.
func should_retreat() -> bool:
	return false
