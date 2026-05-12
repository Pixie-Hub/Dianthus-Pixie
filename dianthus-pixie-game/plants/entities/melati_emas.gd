class_name MelatiEmas
extends PlantBase

@export var hp_regen_per_sec: float = 2.0
@export var energy_regen_per_sec: float = 4.0

var _hp_accumulator: float = 0.0
var _energy_accumulator: float = 0.0
var _player_in_range: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"melati_emases")
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
	_hp_accumulator += hp_regen_per_sec * quality_multiplier * delta
	if _hp_accumulator >= 1.0:
		var amount: int = int(_hp_accumulator)
		_hp_accumulator -= float(amount)
		if player.has_method("heal"):
			player.heal(amount)
			_report_ability_triggered(&"hp_regen")
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
		_hp_accumulator = 0.0
		_energy_accumulator = 0.0
		_report_player_status_effects()


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_clear_player_status_effects()


func destroy() -> void:
	_player_in_range = false
	_clear_player_status_effects()
	super.destroy()


func _report_player_status_effects() -> void:
	if not is_instance_valid(GameManager.player):
		return
	if not GameManager.player.has_method("report_status_effect_source"):
		return
	GameManager.player.report_status_effect_source(
			"plant_hp_regen",
			_status_source_id(),
			{
				"display_name": "Melati Emas",
				"description": "Health Regen",
				"category": "regeneration",
				"value": hp_regen_per_sec * quality_multiplier,
				"value_format": "per_second",
				"aggregation": "sum",
				"duration": -1.0,
				"remaining_time": -1.0,
			})
	GameManager.player.report_status_effect_source(
			"plant_energy_regen",
			_status_source_id(),
			{
				"display_name": "Melati Emas",
				"description": "Energy Regen",
				"category": "regeneration",
				"value": energy_regen_per_sec * quality_multiplier,
				"value_format": "per_second",
				"aggregation": "sum",
				"duration": -1.0,
				"remaining_time": -1.0,
			})


func _clear_player_status_effects() -> void:
	if not is_instance_valid(GameManager.player):
		return
	if not GameManager.player.has_method("remove_status_effect_source"):
		return
	GameManager.player.remove_status_effect_source("plant_hp_regen", _status_source_id())
	GameManager.player.remove_status_effect_source("plant_energy_regen", _status_source_id())


func _status_source_id() -> String:
	return "melati_emas:%d" % get_instance_id()
