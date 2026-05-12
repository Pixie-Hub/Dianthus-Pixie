class_name Melati
extends PlantBase

@export var energy_regen_per_sec: float = 3.0

var _energy_accumulator: float = 0.0
var _player_in_range: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"melatis")
	max_hp = 25
	current_hp = max_hp
	effect_radius = 32.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)


func _process(delta: float) -> void:
	if is_wilted:
		return
	if not _player_in_range:
		return
	if not is_instance_valid(GameManager.player):
		return
	var player: Node = GameManager.player
	_energy_accumulator += energy_regen_per_sec * quality_multiplier * delta
	if _energy_accumulator >= 1.0:
		var amount: int = int(_energy_accumulator)
		_energy_accumulator -= float(amount)
		if player.has_method("add_energy"):
			player.add_energy(amount)
			_report_ability_triggered(&"energy_regen")


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		_energy_accumulator = 0.0
		_report_player_status_effect()


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_clear_player_status_effect()


func destroy() -> void:
	_player_in_range = false
	_clear_player_status_effect()
	super.destroy()


func _report_player_status_effect() -> void:
	if not is_instance_valid(GameManager.player):
		return
	if not GameManager.player.has_method("report_status_effect_source"):
		return
	GameManager.player.report_status_effect_source(
			"plant_energy_regen",
			_status_source_id(),
			{
				"display_name": "Melati Aura",
				"description": "Energy Regen",
				"category": "regeneration",
				"value": energy_regen_per_sec * quality_multiplier,
				"value_format": "per_second",
				"aggregation": "sum",
				"duration": -1.0,
				"remaining_time": -1.0,
			})


func _clear_player_status_effect() -> void:
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("remove_status_effect_source"):
		GameManager.player.remove_status_effect_source("plant_energy_regen", _status_source_id())


func _status_source_id() -> String:
	return "melati:%d" % get_instance_id()
