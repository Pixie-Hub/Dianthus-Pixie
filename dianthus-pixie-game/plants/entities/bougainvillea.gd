class_name Bougainvillea
extends PlantBase

@export var damage_per_tick: int = 5
@export var tick_interval: float = 1.0

var _enemies_in_range: Array[EnemyBase] = []
var _tick_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(&"bougainvilleas")
	max_hp = 30
	current_hp = max_hp
	effect_radius = 24.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)


func _process(delta: float) -> void:
	if _enemies_in_range.is_empty():
		return
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer -= tick_interval
		SfxManager.play_at("bougainvillea_thorn_tick", global_position)
		for enemy in _enemies_in_range.duplicate():
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy.take_damage(damage_per_tick)


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		if not _enemies_in_range.has(body):
			_enemies_in_range.append(body)
			body.enemy_died.connect(_on_tracked_enemy_died.bind(body), CONNECT_ONE_SHOT)


func _on_effect_area_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)
	if body is EnemyBase and body.enemy_died.is_connected(_on_tracked_enemy_died.bind(body)):
		body.enemy_died.disconnect(_on_tracked_enemy_died.bind(body))


func _on_tracked_enemy_died(_enemy: EnemyBase, body: EnemyBase) -> void:
	_enemies_in_range.erase(body)


func destroy() -> void:
	_enemies_in_range.clear()
	super.destroy()
