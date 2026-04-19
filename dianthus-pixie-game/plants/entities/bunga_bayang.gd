class_name BungaBayang
extends PlantBase

@export var slow_multiplier: float = 0.7
@export var projectile_interval: float = 2.0
@export var projectile_damage: int = 4
@export var projectile_speed: float = 80.0
@export var projectile_lifetime: float = 1.5

var _enemies_in_range: Array[EnemyBase] = []
var _projectile_timer: float = 0.0
var _active_projectiles: Array[Node2D] = []


func _ready() -> void:
	super._ready()
	add_to_group(&"bunga_bayangs")
	max_hp = 40
	current_hp = max_hp
	effect_radius = 36.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)


func _process(delta: float) -> void:
	# Night projectile firing
	if DayNightCycle.is_night():
		_projectile_timer += delta
		if _projectile_timer >= projectile_interval:
			_projectile_timer = 0.0
			_fire_projectile()
	else:
		_projectile_timer = 0.0
	# Move active projectiles
	for proj in _active_projectiles.duplicate():
		if not is_instance_valid(proj):
			_active_projectiles.erase(proj)
			continue
		var target: Variant = proj.get_meta("target", null)
		var lifetime: float = float(proj.get_meta("lifetime", 0.0)) - delta
		proj.set_meta("lifetime", lifetime)
		if lifetime <= 0.0:
			proj.queue_free()
			_active_projectiles.erase(proj)
			continue
		if is_instance_valid(target) and not (target as EnemyBase).is_dead:
			var dir: Vector2 = ((target as EnemyBase).global_position - proj.global_position).normalized()
			proj.global_position += dir * projectile_speed * delta
		else:
			proj.queue_free()
			_active_projectiles.erase(proj)


func _fire_projectile() -> void:
	# Find nearest enemy
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
	# Build projectile as Area2D programmatically — TODO: PLANT-09 shared projectile system
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
	visual.color = Color(0.5, 0.2, 0.8, 1)
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


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		if not _enemies_in_range.has(body):
			_enemies_in_range.append(body)
			body.enemy_died.connect(_on_tracked_enemy_died.bind(body), CONNECT_ONE_SHOT)
		_apply_slow(body)


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body is EnemyBase:
		_enemies_in_range.erase(body)
		if is_instance_valid(body) and not body.is_dead:
			_recalculate_slow(body)


func _on_tracked_enemy_died(_enemy: EnemyBase, body: EnemyBase) -> void:
	_enemies_in_range.erase(body)


func _apply_slow(enemy: EnemyBase) -> void:
	enemy.speed_modifier = min(enemy.speed_modifier, slow_multiplier)


func _recalculate_slow(enemy: EnemyBase) -> void:
	var strongest: float = 1.0
	for plant in get_tree().get_nodes_in_group(&"bunga_bayangs"):
		if plant is BungaBayang and not plant.is_destroyed:
			if plant._enemies_in_range.has(enemy):
				strongest = min(strongest, plant.slow_multiplier)
	# Also account for any Rafflesia still affecting the enemy
	for plant in get_tree().get_nodes_in_group(&"rafflesias"):
		if plant is Rafflesia and not plant.is_destroyed:
			if plant._enemies_in_range.has(enemy):
				strongest = min(strongest, plant.slow_multiplier)
	enemy.speed_modifier = strongest


func destroy() -> void:
	for enemy in _enemies_in_range.duplicate():
		if is_instance_valid(enemy) and not enemy.is_dead:
			_recalculate_slow(enemy)
	_enemies_in_range.clear()
	for proj in _active_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	_active_projectiles.clear()
	super.destroy()
