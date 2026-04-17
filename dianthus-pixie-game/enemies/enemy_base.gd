class_name EnemyBase
extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal enemy_died(enemy: EnemyBase)
signal damage_dealt(target: Node, amount: int)

@export var max_hp: int = 40
@export var damage: int = 8
@export var move_speed: float = 40.0
@export var detection_radius: float = 80.0
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var ally_proximity_radius: float = 96.0

var current_hp: int = 0
var is_dead: bool = false

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	current_hp = max_hp
	add_to_group(&"enemies")
	collision_layer = CollisionLayers.ENEMY
	collision_mask = CollisionLayers.PLAYER


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)
	_flash_damage()
	if current_hp <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	var fsm: Node = get_node_or_null("StateMachine")
	if fsm != null:
		fsm.set_process(false)
		fsm.set_physics_process(false)
	enemy_died.emit(self)
	remove_from_group(&"enemies")
	# TODO (PLANT-07): Award +10 energy to player here.
	_play_death_animation()


func get_core_position() -> Vector2:
	if is_instance_valid(GameManager.dianthus_core):
		return GameManager.dianthus_core.global_position
	return global_position


func get_player_position() -> Vector2:
	if is_instance_valid(GameManager.player):
		return GameManager.player.global_position
	return global_position


func distance_to_player() -> float:
	return global_position.distance_to(get_player_position())


func distance_to_core() -> float:
	return global_position.distance_to(get_core_position())


func count_nearby_allies(radius: float) -> int:
	var count: int = 0
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if node == self:
			continue
		if node is EnemyBase and global_position.distance_to(node.global_position) <= radius:
			count += 1
	return count


func should_retreat() -> bool:
	# TODO (CORE-07): Revisit ally threshold once Wave Spawner guarantees group spawns.
	return current_hp < max_hp * 0.2 and count_nearby_allies(ally_proximity_radius) < 2


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
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
