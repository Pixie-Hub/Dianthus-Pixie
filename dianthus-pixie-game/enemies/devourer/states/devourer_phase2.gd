extends State

# TODO: ENEMY-05 (Step 5) — Phase 2 logic: faster speed, Dark Pulse, summon every 12s.
# Placeholder so the_devourer.tscn loads without errors.


func enter() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		e.play_animation(&"walk")


func physics_update(_delta: float) -> void:
	pass
