class_name Shadowling
extends EnemyBase


func _ready() -> void:
	super._ready()


func activate() -> void:
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Scout")
