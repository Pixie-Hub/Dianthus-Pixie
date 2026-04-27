class_name Voidrunner
extends EnemyBase


func _ready() -> void:
	super._ready()


func activate() -> void:
	SfxManager.play_at("voidrunner_charge", global_position)
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Rush")


# Override: Voidrunner never retreats.
func should_retreat() -> bool:
	return false


func _get_death_sfx_id() -> String:
	return "voidrunner_death"
