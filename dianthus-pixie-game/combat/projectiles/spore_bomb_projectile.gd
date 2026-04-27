class_name SporeBombProjectile
extends Area2D

@export var fuse_time: float = 1.0
@export var damage: int = 20
@export var aoe_radius: float = 32.0
@export var slow_multiplier: float = 0.6
@export var slow_duration: float = 2.0
@export var arc_height: float = 24.0

var _start_pos: Vector2
var _target_pos: Vector2
var _t: float = 0.0
var _exploded: bool = false

func launch(from_pos: Vector2, to_pos: Vector2) -> void:
	_start_pos = from_pos
	_target_pos = to_pos
	global_position = from_pos


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_t += delta
	var u: float = clamp(_t / fuse_time, 0.0, 1.0)
	var lin: Vector2 = _start_pos.lerp(_target_pos, u)
	lin.y -= sin(u * PI) * arc_height
	global_position = lin
	if _t >= fuse_time:
		_explode()


func _explode() -> void:
	_exploded = true
	set_physics_process(false)
	var _det_sfx: String = "void_grenade_detonate" if damage >= 30 else "spore_bomb_detonate"
	SfxManager.play_at(_det_sfx, global_position)
	for body in get_tree().get_nodes_in_group(&"enemies"):
		if body is EnemyBase and not body.is_dead:
			if global_position.distance_to(body.global_position) <= aoe_radius:
				body.take_damage(damage)
				body.apply_timed_slow(slow_multiplier, slow_duration)
				if is_instance_valid(GameManager.player):
					GameManager.player.add_energy(GameManager.player.ENERGY_PER_HIT)
	_spawn_explosion_vfx()
	print("[SporeBomb] Exploded at %s — radius %.0f, dmg %d" % [global_position, aoe_radius, damage])
	await get_tree().create_timer(0.4).timeout
	queue_free()


func _spawn_explosion_vfx() -> void:
	# TODO (VFX-05): Replace with real explosion particle effect.
	var ring: ColorRect = ColorRect.new()
	ring.color = Color(0.4, 0.8, 0.2, 0.6)
	var size: float = aoe_radius * 2.0
	ring.size = Vector2(size, size)
	ring.position = -Vector2(size * 0.5, size * 0.5)
	add_child(ring)
	var tween: Tween = create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)
