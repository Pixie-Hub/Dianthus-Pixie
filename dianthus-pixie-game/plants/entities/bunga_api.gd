class_name BungaApi
extends PlantBase

@export var damage_per_tick: int = 7
@export var tick_interval: float = 1.0
@export var burn_damage_per_tick: int = 3
@export var burn_duration: float = 2.0

var _enemies_in_range: Array[EnemyBase] = []
var _tick_timer: float = 0.0
var _burn_timers: Dictionary = {}
var _burn_accumulators: Dictionary = {}


func _ready() -> void:
	super._ready()
	add_to_group(&"bunga_apis")
	max_hp = 35
	current_hp = max_hp
	effect_radius = 28.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)


func _process(delta: float) -> void:
	if is_wilted:
		return
	# Tick damage
	if not _enemies_in_range.is_empty():
		_tick_timer += delta
		if _tick_timer >= tick_interval:
			_tick_timer -= tick_interval
			var triggered: bool = false
			for enemy in _enemies_in_range.duplicate():
				if is_instance_valid(enemy) and not enemy.is_dead:
					enemy.take_damage(damage_per_tick)
					_start_burn(enemy)
					triggered = true
			if triggered:
				_report_ability_triggered(&"fire_thorn_tick")
	# Burn processing
	var to_remove: Array = []
	for enemy: Variant in _burn_timers.keys():
		if not is_instance_valid(enemy) or (enemy as EnemyBase).is_dead:
			to_remove.append(enemy)
			continue
		_burn_timers[enemy] -= delta
		if _burn_timers[enemy] <= 0.0:
			to_remove.append(enemy)
			continue
		_burn_accumulators[enemy] = _burn_accumulators.get(enemy, 0.0) + delta
		if _burn_accumulators[enemy] >= 1.0:
			_burn_accumulators[enemy] -= 1.0
			(enemy as EnemyBase).take_damage(burn_damage_per_tick)
	for e in to_remove:
		_burn_timers.erase(e)
		_burn_accumulators.erase(e)


func _start_burn(enemy: EnemyBase) -> void:
	_burn_timers[enemy] = burn_duration
	if not _burn_accumulators.has(enemy):
		_burn_accumulators[enemy] = 0.0


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		if not _enemies_in_range.has(body):
			_enemies_in_range.append(body)
			if not body.enemy_died.is_connected(_on_tracked_enemy_died.bind(body)):
				body.enemy_died.connect(_on_tracked_enemy_died.bind(body), CONNECT_ONE_SHOT)


func _on_effect_area_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)


func _on_tracked_enemy_died(_enemy: EnemyBase, body: EnemyBase) -> void:
	_enemies_in_range.erase(body)
	_burn_timers.erase(body)
	_burn_accumulators.erase(body)


func destroy() -> void:
	_enemies_in_range.clear()
	_burn_timers.clear()
	_burn_accumulators.clear()
	super.destroy()
