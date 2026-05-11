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


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false


func destroy() -> void:
	_player_in_range = false
	super.destroy()
