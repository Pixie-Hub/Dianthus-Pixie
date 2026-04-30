class_name WijayaKusuma
extends PlantBase

@export var projectile_interval: float = 1.5
@export var projectile_damage: int = 8
@export var projectile_speed: float = 90.0
@export var projectile_lifetime: float = 2.0

var _projectile_timer: float = 0.0
var _active_projectiles: Array[Node2D] = []


func _ready() -> void:
	super._ready()
	add_to_group(&"wijaya_kusumas")
	max_hp = 30
	current_hp = max_hp
	effect_radius = 48.0


func _process(delta: float) -> void:
	# Night-only projectile firing
	if DayNightCycle.is_night():
		_projectile_timer += delta
		if _projectile_timer >= projectile_interval:
			_projectile_timer = 0.0
			_fire_projectile()
	else:
		_projectile_timer = 0.0
	# Move active projectiles
	var i := _active_projectiles.size() - 1
	while i >= 0:
		var proj: Node2D = _active_projectiles[i]
		if not is_instance_valid(proj):
			_active_projectiles.remove_at(i)
			i -= 1
			continue
		var target: Variant = proj.get_meta("target", null)
		var lifetime: float = float(proj.get_meta("lifetime", 0.0)) - delta
		proj.set_meta("lifetime", lifetime)
		if lifetime <= 0.0:
			proj.queue_free()
			_active_projectiles.remove_at(i)
		elif is_instance_valid(target) and not (target as EnemyBase).is_dead:
			var dir: Vector2 = ((target as EnemyBase).global_position - proj.global_position).normalized()
			proj.global_position += dir * projectile_speed * delta
		else:
			proj.queue_free()
			_active_projectiles.remove_at(i)
		i -= 1


func _fire_projectile() -> void:
	var nearest: EnemyBase = null
	var nearest_dist: float = INF
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy is EnemyBase:
			continue
		var eb: EnemyBase = enemy as EnemyBase
		if eb.is_dead:
			continue
		var d: float = global_position.distance_to(eb.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = eb
	if nearest == null:
		return
	var proj: Area2D = Area2D.new()
	proj.collision_layer = 0
	proj.collision_mask = 8
	proj.monitoring = true
	proj.monitorable = false
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 4.0
	shape_node.shape = shape
	proj.add_child(shape_node)
	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(6, 6)
	visual.position = Vector2(-3, -3)
	visual.color = Color(0.94, 0.91, 1.0, 1)
	proj.add_child(visual)
	proj.set_meta("target", nearest)
	proj.set_meta("lifetime", projectile_lifetime)
	var dmg: int = projectile_damage
	proj.body_entered.connect(func(body: Node2D) -> void:
		if body is EnemyBase and not (body as EnemyBase).is_dead:
			(body as EnemyBase).take_damage(dmg)
		if is_instance_valid(proj):
			proj.queue_free()
	)
	proj.global_position = global_position
	get_tree().current_scene.add_child(proj)
	_active_projectiles.append(proj)
	_report_ability_triggered(&"night_projectile")


func destroy() -> void:
	for proj in _active_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	_active_projectiles.clear()
	super.destroy()
