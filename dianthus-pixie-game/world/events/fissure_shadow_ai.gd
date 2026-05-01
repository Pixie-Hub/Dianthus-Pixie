extends CharacterBody2D

var _attack_cooldown: float = 0.0

func _physics_process(delta: float) -> void:
	if not has_meta(&"hp"):
		return
	var player: Node2D = GameManager.player as Node2D
	if not is_instance_valid(player):
		return
	var spd: float = float(get_meta(&"speed", 48.0))
	var dir: Vector2 = (player.global_position - global_position).normalized()
	velocity = dir * spd
	move_and_slide()

	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= 14.0 and player.has_method("take_damage"):
			player.take_damage(int(get_meta(&"damage", 4)))
			_attack_cooldown = 1.0


func take_damage(amount: int) -> void:
	var hp: int = int(get_meta(&"hp", 1)) - amount
	set_meta(&"hp", hp)
	SfxManager.play_at("enemy_hit", global_position, 0.1)
	if hp <= 0:
		die()


func die() -> void:
	remove_from_group(&"enemies")
	remove_from_group(&"void_fissure_shadows")
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("add_energy"):
		GameManager.player.add_energy(5)
	queue_free()
