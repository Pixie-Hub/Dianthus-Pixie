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


func _on_effect_area_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false


func destroy() -> void:
	_player_in_range = false
	super.destroy()
