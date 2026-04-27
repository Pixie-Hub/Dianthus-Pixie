class_name Beringin
extends PlantBase

@export var wall_hp: int = 60
@export var wall_duration: float = 20.0
@export var wall_cooldown: float = 25.0
@export var wall_damage_per_sec: int = 2

var _cooldown_timer: float = 0.0
var _active_wall: StaticBody2D = null
var _wall_life_timer: float = 0.0
var _wall_enemies: Array[EnemyBase] = []
var _wall_dmg_accumulator: float = 0.0
var _wall_current_hp: int = 0


func _ready() -> void:
	super._ready()
	add_to_group(&"beringins")
	max_hp = 50
	current_hp = max_hp
	effect_radius = 32.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)


func _process(delta: float) -> void:
	_cooldown_timer = max(_cooldown_timer - delta, 0.0)
	if _active_wall != null:
		if not is_instance_valid(_active_wall):
			_active_wall = null
			_wall_enemies.clear()
		else:
			_wall_life_timer -= delta
			# Enemies touching the wall deal their damage each second
			if not _wall_enemies.is_empty():
				_wall_dmg_accumulator += delta
				if _wall_dmg_accumulator >= 1.0:
					_wall_dmg_accumulator -= 1.0
					for enemy in _wall_enemies.duplicate():
						if is_instance_valid(enemy) and not enemy.is_dead:
							_wall_current_hp -= enemy.damage
					if _wall_current_hp <= 0:
						_destroy_wall()
						return
			if _wall_life_timer <= 0.0:
				_destroy_wall()


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		if _active_wall == null and _cooldown_timer <= 0.0:
			_spawn_wall.call_deferred(body as EnemyBase)


func _spawn_wall(toward_enemy: EnemyBase) -> void:
	var dir: Vector2 = (toward_enemy.global_position - global_position).normalized()
	var wall_pos: Vector2 = global_position + dir * 20.0

	var wall: StaticBody2D = StaticBody2D.new()
	wall.collision_layer = CollisionLayers.PLAYER
	wall.collision_mask = 0

	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(24, 8)
	shape_node.shape = shape
	wall.add_child(shape_node)

	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(24, 8)
	visual.position = Vector2(-12, -4)
	visual.color = Color(0.36, 0.24, 0.12, 1)
	wall.add_child(visual)

	# Detection area for enemies touching the wall
	var detect: Area2D = Area2D.new()
	detect.collision_layer = 0
	detect.collision_mask = CollisionLayers.ENEMY
	detect.monitoring = true
	detect.monitorable = false
	var detect_shape_node: CollisionShape2D = CollisionShape2D.new()
	var detect_shape: RectangleShape2D = RectangleShape2D.new()
	detect_shape.size = Vector2(28, 12)
	detect_shape_node.shape = detect_shape
	detect.add_child(detect_shape_node)
	detect.body_entered.connect(_on_wall_body_entered)
	detect.body_exited.connect(_on_wall_body_exited)
	wall.add_child(detect)

	wall.global_position = wall_pos
	# Rotate wall perpendicular to direction
	wall.rotation = dir.angle() + PI * 0.5
	get_tree().current_scene.add_child(wall)

	_active_wall = wall
	_wall_life_timer = wall_duration
	_cooldown_timer = wall_cooldown
	_wall_current_hp = wall_hp
	_wall_dmg_accumulator = 0.0
	_wall_enemies.clear()
	SfxManager.play_at("beringin_wall_spawn", wall_pos)


func _on_wall_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		if not _wall_enemies.has(body as EnemyBase):
			_wall_enemies.append(body as EnemyBase)


func _on_wall_body_exited(body: Node2D) -> void:
	if body is EnemyBase:
		_wall_enemies.erase(body as EnemyBase)


func _destroy_wall() -> void:
	if is_instance_valid(_active_wall):
		SfxManager.play_at("beringin_wall_break", _active_wall.global_position)
		_active_wall.queue_free()
	_active_wall = null
	_wall_enemies.clear()


func destroy() -> void:
	_destroy_wall()
	super.destroy()
