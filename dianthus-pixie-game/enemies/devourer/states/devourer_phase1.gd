extends State

# TODO: ENEMY-05 (Step 4) — Phase 1 logic: move to Core, Void Slam, minion summon every 15s.
# Placeholder so the_devourer.tscn loads without errors.


func enter() -> void:
	var e: EnemyBase = enemy as EnemyBase
	if e != null:
		e.play_animation(&"walk")


func physics_update(_delta: float) -> void:
	pass
