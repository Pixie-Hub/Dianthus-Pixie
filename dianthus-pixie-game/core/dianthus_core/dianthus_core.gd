extends StaticBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal core_damaged(amount: int)

const MAX_HP: int = 200
const DAYTIME_REGEN_RATE: float = 5.0 / 60.0
const DEATH_FRAME_COUNT: int = 8
const DEATH_FRAME_DURATION: float = 0.08

var current_hp: int = MAX_HP

@export var death_texture: Texture2D

@onready var _aura_light: PointLight2D = %AuraLight
@onready var _sprite: Sprite2D = %Sprite2D

var _base_aura_energy: float = 1.5
var _regen_accumulator: float = 0.0
var _base_sprite_scale: Vector2
var _breathe_tween: Tween = null
var _tutorial_glow_tween: Tween = null
var _tutorial_glow_active: bool = false
var _death_tween: Tween = null
var _is_destroyed: bool = false


func _ready() -> void:
	_base_aura_energy = _aura_light.energy
	_base_sprite_scale = _sprite.scale
	$DamageArea.body_entered.connect(_on_enemy_entered)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	call_deferred("_emit_initial_hp")
	call_deferred("_start_breathe_animation")


func _process(delta: float) -> void:
	if _is_destroyed:
		return
	if !DayNightCycle.is_night():
		_regen_accumulator += DAYTIME_REGEN_RATE * delta
		if _regen_accumulator >= 1.0:
			var amount: int = int(_regen_accumulator)
			_regen_accumulator -= float(amount)
			heal(amount, false)


func take_damage(amount: int) -> void:
	if _is_destroyed or amount <= 0:
		return
	var was_above_low: bool = current_hp > MAX_HP * 0.25
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, MAX_HP)
	core_damaged.emit(amount)
	SfxManager.play("core_take_damage")
	if current_hp <= 0:
		_destroy_core()
		return
	_update_aura()
	if was_above_low and current_hp <= MAX_HP * 0.25 and current_hp > 0:
		SfxManager.play("core_low_hp")
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.8, 0.9), 0.2)


func heal(amount: int, play_sfx: bool = true) -> void:
	if _is_destroyed or amount <= 0:
		return
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


func _destroy_core() -> void:
	_is_destroyed = true
	_regen_accumulator = 0.0
	_stop_core_animation_tweens()
	_play_death_animation()
	SfxManager.play("core_destroyed")
	core_destroyed.emit()


func _stop_core_animation_tweens() -> void:
	if is_instance_valid(_breathe_tween):
		_breathe_tween.kill()
	if is_instance_valid(_tutorial_glow_tween):
		_tutorial_glow_tween.kill()
	if is_instance_valid(_death_tween):
		_death_tween.kill()


func _play_death_animation() -> void:
	_aura_light.energy = 0.0
	_sprite.scale = _base_sprite_scale
	_sprite.self_modulate = Color.WHITE
	_sprite.modulate = Color.WHITE
	if death_texture == null:
		return
	_sprite.texture = death_texture
	_sprite.hframes = DEATH_FRAME_COUNT
	_sprite.vframes = 1
	_sprite.frame = 0
	_death_tween = create_tween()
	_death_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for frame_index: int in range(DEATH_FRAME_COUNT):
		_death_tween.tween_callback(_set_death_frame.bind(frame_index))
		_death_tween.tween_interval(DEATH_FRAME_DURATION)


func _set_death_frame(frame_index: int) -> void:
	_sprite.frame = frame_index


func _on_enemy_entered(body: Node2D) -> void:
	print("Core hit by: ", body.name)


func get_hp_ratio() -> float:
	return float(current_hp) / float(MAX_HP)


func set_tutorial_glow_active(active: bool) -> void:
	if _tutorial_glow_active == active:
		return
	_tutorial_glow_active = active
	if is_instance_valid(_tutorial_glow_tween):
		_tutorial_glow_tween.kill()
	if active:
		_tutorial_glow_tween = create_tween().set_loops()
		_tutorial_glow_tween.tween_property(_aura_light, "energy", _base_aura_energy * 1.6, 0.55)
		_tutorial_glow_tween.parallel().tween_property(_sprite, "self_modulate", Color(1.0, 0.92, 1.0, 1.0), 0.55)
		_tutorial_glow_tween.tween_property(_aura_light, "energy", _base_aura_energy * 1.15, 0.55)
		_tutorial_glow_tween.parallel().tween_property(_sprite, "self_modulate", Color(1.0, 0.8, 0.9, 1.0), 0.55)
	else:
		_update_aura()
		_sprite.self_modulate = Color(1.0, 0.8, 0.9, 1.0)


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
