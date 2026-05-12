class_name BajaKuning
extends PlantBase

@export var damage_reduction_amount: float = 0.3

var _player_in_range: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"baja_kunings")
	max_hp = 50
	current_hp = max_hp
	effect_radius = 28.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)
	vitality_changed.connect(_on_vitality_changed)


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		if is_wilted:
			return
		SfxManager.play_at("baja_kuning_armor_buff", global_position)
		_recalculate_player_damage_reduction()
		_report_player_status_effect()
		_report_ability_triggered(&"armor_buff")


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_recalculate_player_damage_reduction()
		_clear_player_status_effect()


func _on_vitality_changed(_val: float) -> void:
	if _player_in_range and is_wilted and is_instance_valid(GameManager.player):
		_player_in_range = false
		_recalculate_player_damage_reduction()
		_clear_player_status_effect()


func destroy() -> void:
	_player_in_range = false
	_recalculate_player_damage_reduction()
	_clear_player_status_effect()
	# TODO: PLANT-12 — counter-reflect mechanic (needs source param on take_damage)
	super.destroy()


func _recalculate_player_damage_reduction() -> void:
	if not is_instance_valid(GameManager.player):
		return
	var best: float = 0.0
	for plant in get_tree().get_nodes_in_group(&"baja_kunings"):
		if plant is BajaKuning and not plant.is_destroyed and not plant.is_wilted and plant._player_in_range:
			best = max(best, plant.damage_reduction_amount * plant.quality_multiplier)
	GameManager.player.set("damage_reduction", best)


func _report_player_status_effect() -> void:
	if not is_instance_valid(GameManager.player):
		return
	if not GameManager.player.has_method("report_status_effect_source"):
		return
	GameManager.player.report_status_effect_source(
			"plant_armor",
			_status_source_id(),
			{
				"display_name": "Baja Kuning Guard",
				"description": "Armor",
				"category": "defense",
				"value": damage_reduction_amount * quality_multiplier,
				"value_format": "percent",
				"aggregation": "max",
				"duration": -1.0,
				"remaining_time": -1.0,
			})


func _clear_player_status_effect() -> void:
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("remove_status_effect_source"):
		GameManager.player.remove_status_effect_source("plant_armor", _status_source_id())


func _status_source_id() -> String:
	return "baja_kuning:%d" % get_instance_id()
