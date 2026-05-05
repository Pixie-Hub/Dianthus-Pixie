extends State

# TODO: ENEMY-05 (Step 6) — Phase 3 logic: max speed, Devour Surge at 15% HP, summon every 10s.
# Placeholder so the_devourer.tscn loads without errors.


func enter() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		e.play_animation(&"walk")


func physics_update(_delta: float) -> void:
	pass
