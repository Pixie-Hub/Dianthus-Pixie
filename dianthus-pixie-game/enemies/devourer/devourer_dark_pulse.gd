extends Area2D

const PROJECTILE_SPEED: float = 120.0
const AOE_RADIUS: float = 32.0
const SLOW_MULTIPLIER: float = 0.5
const SLOW_DURATION: float = 1.5

var _target_pos: Vector2 = Vector2.ZERO
var _damage: int = 35
var _direction: Vector2 = Vector2.ZERO
var _arrived: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	if has_meta("damage"):
		_damage = get_meta("damage") as int
	if has_meta("target_pos"):
		_target_pos = get_meta("target_pos") as Vector2
		_direction = ((_target_pos - global_position).normalized()
			if _target_pos != global_position else Vector2.DOWN)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _arrived:
		return
	var dist: float = global_position.distance_to(_target_pos)
	if dist <= PROJECTILE_SPEED * delta + 4.0:
		global_position = _target_pos
		_arrived = true
		_explode()
		return
	global_position += _direction * PROJECTILE_SPEED * delta


func _explode() -> void:
	SfxManager.play_at("devourer_dark_pulse", global_position)
	_hit_nearby(global_position)
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		col.disabled = false
	var tween: Tween = create_tween()
	var vis: Node2D = get_node_or_null("Visual") as Node2D
	if is_instance_valid(vis):
		tween.tween_property(vis, "scale", Vector2(3.0, 3.0), 0.3)
		tween.parallel().tween_property(vis, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _hit_nearby(pos: Vector2) -> void:
	if get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if node is EnemyBase:
			continue
	var player: Node2D = GameManager.player as Node2D
	if is_instance_valid(player):
		if player.global_position.distance_to(pos) <= AOE_RADIUS:
			if player.has_method("take_damage"):
				player.take_damage(_damage)
	for plant in get_tree().get_nodes_in_group(&"plants"):
		if not is_instance_valid(plant):
			continue
		if plant.global_position.distance_to(pos) <= AOE_RADIUS:
			if plant.has_method("take_damage"):
				plant.take_damage(20)


func _on_body_entered(body: Node) -> void:
	if _arrived:
		return
	if body.is_in_group(&"enemies"):
		return
	_arrived = true
	_target_pos = global_position
	_explode()
