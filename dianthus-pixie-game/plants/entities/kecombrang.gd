class_name Kecombrang
extends PlantBase

@export var attack_speed_bonus: float = 0.2

var _player_in_range: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"kecombrangs")
	max_hp = 25
	current_hp = max_hp
	effect_radius = 28.0
	var effect_area: Area2D = $EffectArea
	effect_area.body_entered.connect(_on_effect_area_body_entered)
	effect_area.body_exited.connect(_on_effect_area_body_exited)
	vitality_changed.connect(_on_vitality_changed)


func _on_effect_area_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		SfxManager.play_at("kecombrang_speed_boost", global_position)
		_recalculate_player_attack_speed()
		_report_ability_triggered(&"attack_speed_boost")


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_recalculate_player_attack_speed()


func _recalculate_player_attack_speed() -> void:
	if not is_instance_valid(GameManager.player):
		return
	var best: float = 0.0
	for plant in get_tree().get_nodes_in_group(&"kecombrangs"):
		if plant is Kecombrang and not plant.is_destroyed and not plant.is_wilted and plant._player_in_range:
			best = max(best, plant.attack_speed_bonus)
	GameManager.player.set("attack_speed_bonus", best)


func _on_vitality_changed(_val: float) -> void:
	if _player_in_range and is_wilted:
		_player_in_range = false
		_recalculate_player_attack_speed()


func destroy() -> void:
	_player_in_range = false
	_recalculate_player_attack_speed()
	super.destroy()
