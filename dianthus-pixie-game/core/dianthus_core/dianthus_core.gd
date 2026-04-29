extends StaticBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal core_damaged(amount: int)

const MAX_HP: int = 200
const DAYTIME_REGEN_RATE: float = 5.0 / 60.0

var current_hp: int = MAX_HP

@onready var _aura_light: PointLight2D = %AuraLight
@onready var _sprite: Sprite2D = %Sprite2D

var _base_aura_energy: float = 1.5
var _regen_accumulator: float = 0.0
var _base_sprite_scale: Vector2
var _breathe_tween: Tween = null


func _ready() -> void:
	_base_aura_energy = _aura_light.energy
	_base_sprite_scale = _sprite.scale
	$DamageArea.body_entered.connect(_on_enemy_entered)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	call_deferred("_emit_initial_hp")
	call_deferred("_start_breathe_animation")


func _process(delta: float) -> void:
	if !DayNightCycle.is_night():
		_regen_accumulator += DAYTIME_REGEN_RATE * delta
		if _regen_accumulator >= 1.0:
			var amount: int = int(_regen_accumulator)
			_regen_accumulator -= float(amount)
			heal(amount, false)


func take_damage(amount: int) -> void:
	var was_above_low: bool = current_hp > MAX_HP * 0.25
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, MAX_HP)
	core_damaged.emit(amount)
	_update_aura()
	SfxManager.play("core_take_damage")
	if was_above_low and current_hp <= MAX_HP * 0.25 and current_hp > 0:
		SfxManager.play("core_low_hp")
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.8, 0.9), 0.2)
	if current_hp <= 0:
		SfxManager.play("core_destroyed")
		core_destroyed.emit()


func heal(amount: int, play_sfx: bool = true) -> void:
	current_hp = min(current_hp + amount, MAX_HP)
	hp_changed.emit(current_hp, MAX_HP)
	_update_aura()
	if play_sfx:
		SfxManager.play("core_heal")


func _update_aura() -> void:
	var ratio: float = float(current_hp) / float(MAX_HP)
	var tween: Tween = create_tween()
	tween.tween_property(_aura_light, "energy", _base_aura_energy * ratio, 0.5)
	tween.parallel().tween_property(_sprite, "modulate:a", lerp(0.5, 1.0, ratio), 0.5)


func _on_enemy_entered(body: Node2D) -> void:
	print("Core hit by: ", body.name)


func get_hp_ratio() -> float:
	return float(current_hp) / float(MAX_HP)


func _emit_initial_hp() -> void:
	hp_changed.emit(current_hp, MAX_HP)


func _start_breathe_animation() -> void:
	if _breathe_tween:
		_breathe_tween.kill()
	_breathe_tween = create_tween().set_loops()
	var inhale: Vector2 = _base_sprite_scale * Vector2(0.96, 1.06)
	_breathe_tween.tween_property(_sprite, "scale", inhale, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_tween.tween_property(_sprite, "scale", _base_sprite_scale, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_phase_changed(_phase: String) -> void:
	_regen_accumulator = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			take_damage(20)
			print("DEBUG: Core took 20 damage. HP: %d/%d" % [current_hp, MAX_HP])
		elif event.keycode == KEY_F2:
			heal(20)
			print("DEBUG: Core healed 20. HP: %d/%d" % [current_hp, MAX_HP])
