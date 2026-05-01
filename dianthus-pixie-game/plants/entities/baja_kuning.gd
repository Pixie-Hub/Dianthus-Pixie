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
		if body.has_method("heal"):
			body.set("damage_reduction", damage_reduction_amount)
		_report_ability_triggered(&"armor_buff")


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		body.set("damage_reduction", 0.0)


func _on_vitality_changed(_val: float) -> void:
	if _player_in_range and is_wilted and is_instance_valid(GameManager.player):
		GameManager.player.set("damage_reduction", 0.0)


func destroy() -> void:
	if _player_in_range and is_instance_valid(GameManager.player):
		GameManager.player.set("damage_reduction", 0.0)
	_player_in_range = false
	# TODO: PLANT-12 — counter-reflect mechanic (needs source param on take_damage)
	super.destroy()
