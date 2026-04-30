class_name Kunyit
extends PlantBase

@export var bonus_damage: int = 3

var _player_in_range: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"kunyits")
	max_hp = 30
	current_hp = max_hp
	effect_radius = 24.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		SfxManager.play_at("kunyit_melee_buff", global_position)
		_recalculate_player_bonus_damage()
		_report_ability_triggered(&"melee_damage_boost")


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_recalculate_player_bonus_damage()


func _recalculate_player_bonus_damage() -> void:
	if not is_instance_valid(GameManager.player):
		return
	var best: int = 0
	for plant in get_tree().get_nodes_in_group(&"kunyits"):
		if plant is Kunyit and not plant.is_destroyed and plant._player_in_range:
			best = max(best, plant.bonus_damage)
	GameManager.player.set("bonus_melee_damage", best)


func destroy() -> void:
	if _player_in_range:
		_player_in_range = false
		_recalculate_player_bonus_damage()
	super.destroy()
