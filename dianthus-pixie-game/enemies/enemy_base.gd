class_name EnemyBase
extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal enemy_died(enemy: EnemyBase)
signal damage_dealt(target: Node, amount: int)

const FLIP_DEADZONE: float = 5.0
const EnemyCatalog = preload("res://ui/codex/enemy_registry.gd")

@export var max_hp: int = 40
@export var damage: int = 8
@export var move_speed: float = 40.0
@export var detection_radius: float = 80.0
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var ally_proximity_radius: float = 96.0

var current_hp: int = 0
var is_dead: bool = false
var speed_modifier: float = 1.0
var current_siege_target: Node2D = null
var _timed_slow_until: float = 0.0
var _timed_slow_value: float = 1.0
var _stun_until: float = 0.0
var _pull_tween: Tween = null

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	current_hp = max_hp
	add_to_group(&"enemies")
	var enemy_id: String = EnemyCatalog.get_enemy_id_for_node(self)
	if not enemy_id.is_empty():
		CodexManager.discover_enemy(enemy_id)
	# Enemy scenes own their body physics masks; this only fills script-created defaults.
	if collision_layer == 1:
		collision_layer = CollisionLayers.ENEMY
	if collision_mask == 1:
		collision_mask = CollisionLayers.MASK_ENEMY


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)
	_flash_damage()
	SfxManager.play_at("enemy_hit", global_position, 0.1)
	damage_dealt.emit(self, amount)
	if current_hp <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	SfxManager.play_at(_get_death_sfx_id(), global_position)
	velocity = Vector2.ZERO
	var fsm: Node = get_node_or_null("StateMachine")
	if fsm != null:
		fsm.set_process(false)
		fsm.set_physics_process(false)
	enemy_died.emit(self)
	remove_from_group(&"enemies")
	_try_grant_seed_drop()
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("add_energy"):
		GameManager.player.add_energy(10)
	_play_death_animation()


func get_core_position() -> Vector2:
	if is_instance_valid(GameManager.dianthus_core):
		return GameManager.dianthus_core.global_position
	return global_position


func get_player_position() -> Vector2:
	if is_instance_valid(GameManager.player):
		return GameManager.player.global_position
	return global_position


func is_player_dead() -> bool:
	if not is_instance_valid(GameManager.player):
		return true
	return GameManager.player.is_dead


func distance_to_player() -> float:
	return global_position.distance_to(get_player_position())


func distance_to_core() -> float:
	return global_position.distance_to(get_core_position())


func get_nearby_barricade() -> Node2D:
	var closest: Node2D = null
	var closest_dist: float = detection_radius * 2.0
	for node in get_tree().get_nodes_in_group(&"barricades"):
		if not is_instance_valid(node):
			continue
		var d: float = _distance_to_body_edge(node as Node2D)
		if d < closest_dist:
			closest_dist = d
			closest = node as Node2D
	return closest


func get_siege_target_position() -> Vector2:
	if is_instance_valid(current_siege_target):
		return _nearest_edge_point(current_siege_target)
	return get_core_position()


func distance_to_siege_target() -> float:
	if is_instance_valid(current_siege_target):
		return _distance_to_body_edge(current_siege_target)
	return distance_to_core()


func _distance_to_body_edge(body: Node2D) -> float:
	return global_position.distance_to(_nearest_edge_point(body))


func _nearest_edge_point(body: Node2D) -> Vector2:
	var shape_node: CollisionShape2D = _find_body_collision_shape(body)
	if shape_node == null or shape_node.shape == null:
		return body.global_position
	var shape: Shape2D = shape_node.shape
	var local_pos: Vector2 = body.to_local(global_position) - shape_node.position
	var clamped: Vector2
	if shape is RectangleShape2D:
		var half: Vector2 = (shape as RectangleShape2D).size * 0.5
		clamped = Vector2(clampf(local_pos.x, -half.x, half.x), clampf(local_pos.y, -half.y, half.y))
	elif shape is CircleShape2D:
		var r: float = (shape as CircleShape2D).radius
		if local_pos.length() <= r:
			clamped = local_pos
		else:
			clamped = local_pos.normalized() * r
	else:
		return body.global_position
	return body.to_global(clamped + shape_node.position)


func _find_body_collision_shape(body: Node2D) -> CollisionShape2D:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape != null:
			return child as CollisionShape2D
	return null


func count_nearby_allies(radius: float) -> int:
	var count: int = 0
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if node == self:
			continue
		if node is EnemyBase and global_position.distance_to(node.global_position) <= radius:
			count += 1
	return count


func get_effective_speed() -> float:
	var now: float = Time.get_ticks_msec() / 1000.0
	var timed: float = _timed_slow_value if now < _timed_slow_until else 1.0
	if now >= _timed_slow_until:
		_timed_slow_value = 1.0
	return move_speed * speed_modifier * timed


func is_stunned() -> bool:
	return (Time.get_ticks_msec() / 1000.0) < _stun_until


func apply_timed_slow(multiplier: float, duration: float) -> void:
	if is_dead:
		return
	var until: float = (Time.get_ticks_msec() / 1000.0) + duration
	if multiplier < _timed_slow_value or until > _timed_slow_until:
		_timed_slow_value = min(_timed_slow_value, multiplier)
		_timed_slow_until = max(_timed_slow_until, until)


func apply_stun(duration: float) -> void:
	if is_dead:
		return
	_stun_until = max(_stun_until, (Time.get_ticks_msec() / 1000.0) + duration)


func spawn_grace_period(duration: float = 0.5) -> void:
	var original_mask: int = collision_mask
	collision_mask = original_mask & ~CollisionLayers.TERRAIN
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self) and not is_dead:
		collision_mask = original_mask


func apply_pull(toward: Vector2, duration: float, distance: float) -> void:
	if is_dead:
		return
	var dir: Vector2 = (toward - global_position).normalized()
	var target: Vector2 = global_position + dir * distance
	if is_instance_valid(_pull_tween):
		_pull_tween.kill()
	_pull_tween = create_tween()
	_pull_tween.tween_property(self, "global_position", target, duration)
	var fsm: Node = get_node_or_null("StateMachine")
	if fsm != null:
		fsm.set_physics_process(false)
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(self) and not is_dead:
			fsm.set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if is_stunned():
		velocity = Vector2.ZERO
		move_and_slide()
	_update_sprite_facing()


func _update_sprite_facing() -> void:
	if not is_instance_valid(_sprite) or velocity == Vector2.ZERO:
		return
	if _uses_top_down_facing():
		_sprite.rotation = velocity.angle()
	else:
		if velocity.x < -FLIP_DEADZONE:
			_sprite.flip_h = true
		elif velocity.x > FLIP_DEADZONE:
			_sprite.flip_h = false


func _uses_top_down_facing() -> bool:
	return false


func should_retreat() -> bool:
	# TODO (CORE-07): Revisit ally threshold once Wave Spawner guarantees group spawns.
	return current_hp < max_hp * 0.2 and count_nearby_allies(ally_proximity_radius) < 2


func _get_death_sfx_id() -> String:
	return "enemy_hit"


func _get_seed_drop_table() -> Array[Dictionary]:
	return []


func _try_grant_seed_drop() -> void:
	for entry: Dictionary in _get_seed_drop_table():
		if randf() < float(entry.get("chance", 0.0)):
			var item_id: String = str(entry.get("item", ""))
			var amount: int = int(entry.get("amount", 1))
			if item_id.is_empty() or amount <= 0:
				return
			var overflow: int = InventoryManager.add_item(item_id, amount)
			var granted: int = amount - overflow
			if granted > 0:
				_show_drop_popup(
					"+%d %s" % [granted, ItemDatabase.get_display_name(item_id)],
					Color(1.0, 1.0, 0.6)
				)
			if overflow > 0:
				_show_drop_popup("Inventory Full!", Color(1.0, 0.4, 0.4))
			return


func _show_drop_popup(text: String, color: Color) -> void:
	var target_parent: Node = get_parent()
	if target_parent == null:
		target_parent = get_tree().current_scene
	if target_parent == null:
		return
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.position = Vector2(-24, -16)
	label.z_index = 10
	target_parent.add_child(label)
	label.global_position = global_position + Vector2(-24, -16)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 20.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


func play_animation(anim_name: StringName) -> void:
	if is_instance_valid(_anim_player) and _anim_player.has_animation(anim_name):
		if _anim_player.current_animation != anim_name or not _anim_player.is_playing():
			_anim_player.play(anim_name)


func _flash_damage() -> void:
	if not is_instance_valid(_sprite):
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _play_death_animation() -> void:
	if not is_instance_valid(_sprite):
		queue_free()
		return
	if is_instance_valid(_anim_player) and _anim_player.has_animation(&"death"):
		_anim_player.play(&"death")
		await _anim_player.animation_finished
		if is_instance_valid(self):
			queue_free()
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
