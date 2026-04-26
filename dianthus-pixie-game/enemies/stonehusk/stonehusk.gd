class_name Stonehusk
extends EnemyBase


func _ready() -> void:
	super._ready()


func activate() -> void:
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Scout")


# Override: Stonehusk never retreats.
func should_retreat() -> bool:
	return false


# Override: Stonehusk resists pull — halve the pull distance.
# TODO: ENEMY-WEAKNESS — replace with pull_resistance: float export for a generic system.
func apply_pull(toward: Vector2, duration: float, distance: float) -> void:
	super.apply_pull(toward, duration, distance * 0.5)
