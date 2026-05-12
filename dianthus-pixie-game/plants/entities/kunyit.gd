class_name Kunyit
extends PlantBase

@export var bonus_damage: int = 3

var _player_in_range: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"kunyits")
	max_hp = 25
	current_hp = max_hp
	effect_radius = 24.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)
	vitality_changed.connect(_on_vitality_changed)


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		SfxManager.play_at("kunyit_melee_buff", global_position)
		_recalculate_player_bonus_damage()
		_report_player_status_effect()
		_report_ability_triggered(&"melee_damage_boost")


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_recalculate_player_bonus_damage()
		_clear_player_status_effect()


func _recalculate_player_bonus_damage() -> void:
	if not is_instance_valid(GameManager.player):
		return
	var total: int = 0
	for plant in get_tree().get_nodes_in_group(&"kunyits"):
		if plant is Kunyit and not plant.is_destroyed and not plant.is_wilted and plant._player_in_range:
			total += int(plant.bonus_damage * plant.quality_multiplier)
	GameManager.player.set("bonus_melee_damage", total)


func _on_vitality_changed(_val: float) -> void:
	if _player_in_range and is_wilted:
		_player_in_range = false
		_recalculate_player_bonus_damage()
		_clear_player_status_effect()


func destroy() -> void:
	_player_in_range = false
	_recalculate_player_bonus_damage()
	_clear_player_status_effect()
	super.destroy()


func _report_player_status_effect() -> void:
	if not is_instance_valid(GameManager.player):
		return
	if not GameManager.player.has_method("report_status_effect_source"):
		return
	GameManager.player.report_status_effect_source(
			"plant_melee_damage",
			_status_source_id(),
			{
				"display_name": "Kunyit Edge",
				"description": "Damage Up",
				"category": "offense",
				"value": bonus_damage * quality_multiplier,
				"value_format": "flat",
				"aggregation": "sum",
				"duration": -1.0,
				"remaining_time": -1.0,
			})


func _clear_player_status_effect() -> void:
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("remove_status_effect_source"):
		GameManager.player.remove_status_effect_source("plant_melee_damage", _status_source_id())


func _status_source_id() -> String:
	return "kunyit:%d" % get_instance_id()
