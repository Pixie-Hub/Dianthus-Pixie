class_name Rafflesia
extends PlantBase

@export var slow_multiplier: float = 0.6

var _enemies_in_range: Array[EnemyBase] = []


func _ready() -> void:
	super._ready()
	add_to_group(&"rafflesias")
	max_hp = 40
	current_hp = max_hp
	effect_radius = 40.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)
	vitality_changed.connect(_on_vitality_changed)


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		if not _enemies_in_range.has(body):
			_enemies_in_range.append(body)
			if not body.enemy_died.is_connected(_on_tracked_enemy_died.bind(body)):
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
	_report_ability_triggered(&"slow")


func _recalculate_slow(enemy: EnemyBase) -> void:
	var strongest: float = 1.0
	for plant in get_tree().get_nodes_in_group(&"rafflesias"):
		if plant is Rafflesia and not plant.is_destroyed and not plant.is_wilted:
			if plant._enemies_in_range.has(enemy):
				strongest = min(strongest, plant.slow_multiplier)
	enemy.speed_modifier = strongest


func _on_vitality_changed(_val: float) -> void:
	if not is_wilted:
		return
	for enemy in _enemies_in_range.duplicate():
		if is_instance_valid(enemy) and not enemy.is_dead:
			_recalculate_slow(enemy)


func destroy() -> void:
	for enemy in _enemies_in_range.duplicate():
		if is_instance_valid(enemy) and not enemy.is_dead:
			_recalculate_slow(enemy)
	_enemies_in_range.clear()
	super.destroy()
