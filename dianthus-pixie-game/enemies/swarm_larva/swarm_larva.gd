class_name SwarmLarva
extends EnemyBase

# TODO: ENEMY-WEAKNESS — GDD §8.1 lists AoE weapons (Spore Bomb, Rafflesia) as weakness.
# Implement damage multiplier here once the generic weakness-multiplier system is built.
# Mechanical weakness is already implicit: 15 HP means Spore Bomb (20 DMG) and
# Void Grenade (30 DMG) one-shot; Bougainvillea (5 DMG/tick) kills in 3 ticks;
# Rafflesia slow keeps the swarm in AoE zones longer.


func _ready() -> void:
	super._ready()
	add_to_group(&"swarm_larvae")


func activate() -> void:
	SfxManager.play_at("swarm_larva_skitter", global_position)
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Idle")


func should_retreat() -> bool:
	return false


func _uses_top_down_facing() -> bool:
	return true


func _get_death_sfx_id() -> String:
	return "swarm_larva_death"


func _get_seed_drop_table() -> Array[Dictionary]:
	return [
		{"item": "rafflesia_seed", "chance": 0.05},
		{"item": "bougainvillea_seed", "chance": 0.05},
	]
