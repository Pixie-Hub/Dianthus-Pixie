extends StaticBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal core_damaged(amount: int)

const DEFAULT_MAX_HP: int = 350
const DAYTIME_REGEN_RATE: float = 5.0 / 60.0
const CORE_ANIMATION_FRAME_COUNT: int = 16
const IDLE_FRAME_START: int = 0
const IDLE_FRAME_COUNT: int = 4
const IDLE_FRAME_DURATION: float = 0.18
const DAMAGE_FRAME_START: int = 4
const DAMAGE_FRAME_COUNT: int = 4
const DAMAGE_FRAME_DURATION: float = 0.08
const DESTRUCTION_FRAME_START: int = 8
const DEATH_FRAME_COUNT: int = 8
const DEATH_FRAME_DURATION: float = 0.08

const HARVEST_HOLD_TIME: float = 2.0
const POLLEN_PER_HARVEST: int = 1
const POLLEN_ITEM_ID: StringName = &"dianthus_pollen"

var max_hp: int = DEFAULT_MAX_HP
var current_hp: int = DEFAULT_MAX_HP

@export var core_animation_texture: Texture2D
@export var death_texture: Texture2D

@onready var _aura_light: PointLight2D = %AuraLight
@onready var _sprite: Sprite2D = %Sprite2D
@onready var _harvest_area: Area2D = %HarvestArea
@onready var _interaction_prompt: InteractionPrompt = %InteractionPrompt
@onready var _pollen_particles: CPUParticles2D = %PollenParticles

var _base_aura_energy: float = 1.5
var _regen_accumulator: float = 0.0
var _base_sprite_scale: Vector2
var _breathe_tween: Tween = null
var _idle_frame_tween: Tween = null
var _damage_frame_tween: Tween = null
var _idle_glow_tween: Tween = null
var _tutorial_glow_tween: Tween = null
var _tutorial_glow_active: bool = false
var _death_tween: Tween = null
var _is_destroyed: bool = false

var _sacred_bloom_active: bool = false
var _harvested_today: bool = false
var _last_harvest_day: int = -1
var _is_harvesting: bool = false
var _harvest_progress: float = 0.0
var _player_in_range: bool = false
var _bloom_tween: Tween = null


func _ready() -> void:
	_base_aura_energy = _aura_light.energy
	_base_sprite_scale = _sprite.scale
	_prepare_animation_texture()
	$DamageArea.body_entered.connect(_on_enemy_entered)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	UnlockFlags.flag_set.connect(_on_flag_set)
	call_deferred("_emit_initial_hp")
	call_deferred("_start_breathe_animation")
	call_deferred("_start_idle_frame_animation")
	call_deferred("_start_idle_glow_animation")
	call_deferred("_init_sacred_bloom")


func _process(delta: float) -> void:
	if _is_destroyed:
		return
	if !DayNightCycle.is_night():
		_regen_accumulator += DAYTIME_REGEN_RATE * delta
		if _regen_accumulator >= 1.0:
			var amount: int = int(_regen_accumulator)
			_regen_accumulator -= float(amount)
			heal(amount, false)
	if _is_harvesting:
		_harvest_progress += delta / HARVEST_HOLD_TIME
		_interaction_prompt.set_progress(_harvest_progress)
		if _harvest_progress >= 1.0:
			_complete_harvest()
		elif not _player_in_range:
			_cancel_harvest()


func take_damage(amount: int) -> void:
	if _is_destroyed or amount <= 0:
		return
	var was_above_low: bool = current_hp > max_hp * 0.25
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)
	core_damaged.emit(amount)
	SfxManager.play("core_take_damage")
	if current_hp <= 0:
		_destroy_core()
		return
	_update_aura()
	if was_above_low and current_hp <= max_hp * 0.25 and current_hp > 0:
		SfxManager.play("core_low_hp")
	_play_damage_animation()


func heal(amount: int, play_sfx: bool = true) -> void:
	if _is_destroyed or amount <= 0:
		return
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
	_update_aura()
	if play_sfx:
		SfxManager.play("core_heal")


func apply_hp_state(hp: int, new_max_hp: int) -> void:
	max_hp = max(1, new_max_hp)
	current_hp = clampi(hp, 0, max_hp)
	_is_destroyed = current_hp <= 0
	hp_changed.emit(current_hp, max_hp)


func _update_aura() -> void:
	if is_instance_valid(_idle_glow_tween):
		_idle_glow_tween.kill()
		_idle_glow_tween = null
	if is_instance_valid(_bloom_tween):
		_bloom_tween.kill()
		_bloom_tween = null
	var tween: Tween = create_tween()
	tween.tween_property(_aura_light, "energy", _get_hp_aura_energy(), 0.5)
	tween.parallel().tween_property(_sprite, "modulate:a", lerp(0.5, 1.0, get_hp_ratio()), 0.5)
	if not _sacred_bloom_active:
		tween.tween_callback(_start_idle_glow_animation)
	else:
		tween.tween_callback(_start_sacred_bloom_tween)


func _destroy_core() -> void:
	_is_destroyed = true
	_regen_accumulator = 0.0
	if is_instance_valid(_bloom_tween):
		_bloom_tween.kill()
		_bloom_tween = null
	if _is_harvesting:
		_cancel_harvest()
	_harvest_area.set_deferred("monitoring", false)
	_interaction_prompt.hide_prompt()
	_pollen_particles.emitting = false
	_stop_core_animation_tweens()
	_play_death_animation()
	SfxManager.play("core_destroyed")
	core_destroyed.emit()


func _stop_core_animation_tweens() -> void:
	if is_instance_valid(_breathe_tween):
		_breathe_tween.kill()
	if is_instance_valid(_idle_frame_tween):
		_idle_frame_tween.kill()
	if is_instance_valid(_damage_frame_tween):
		_damage_frame_tween.kill()
	if is_instance_valid(_idle_glow_tween):
		_idle_glow_tween.kill()
	if is_instance_valid(_tutorial_glow_tween):
		_tutorial_glow_tween.kill()
	if is_instance_valid(_death_tween):
		_death_tween.kill()


func _play_death_animation() -> void:
	_aura_light.energy = 0.0
	_sprite.scale = _base_sprite_scale
	_sprite.self_modulate = Color.WHITE
	_sprite.modulate = Color.WHITE
	if core_animation_texture != null:
		_sprite.texture = core_animation_texture
		_sprite.hframes = CORE_ANIMATION_FRAME_COUNT
		_sprite.vframes = 1
		_sprite.frame = DESTRUCTION_FRAME_START
	elif death_texture != null:
		_sprite.texture = death_texture
		_sprite.hframes = DEATH_FRAME_COUNT
		_sprite.vframes = 1
		_sprite.frame = 0
	else:
		return
	_death_tween = create_tween()
	_death_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for frame_index: int in range(DEATH_FRAME_COUNT):
		var sprite_frame: int = frame_index
		if core_animation_texture != null:
			sprite_frame += DESTRUCTION_FRAME_START
		_death_tween.tween_callback(_set_core_frame.bind(sprite_frame))
		_death_tween.tween_interval(DEATH_FRAME_DURATION)


func _set_core_frame(frame_index: int) -> void:
	_sprite.frame = frame_index


func _on_enemy_entered(body: Node2D) -> void:
	print("Core hit by: ", body.name)


func get_hp_ratio() -> float:
	return clampf(float(current_hp) / float(max(max_hp, 1)), 0.0, 1.0)


func _init_sacred_bloom() -> void:
	if UnlockFlags.has_flag(StoryEndingFlags.unlock_core_sacred_bloom):
		_activate_sacred_bloom()


func _on_flag_set(flag_name: String) -> void:
	if flag_name == StoryEndingFlags.unlock_core_sacred_bloom and not _sacred_bloom_active:
		_activate_sacred_bloom()


func _activate_sacred_bloom() -> void:
	if _is_destroyed:
		return
	_sacred_bloom_active = true
	_harvest_area.set_deferred("monitoring", true)
	_pollen_particles.emitting = true
	_start_sacred_bloom_tween()
	_refresh_prompt()


func _start_sacred_bloom_tween() -> void:
	if not _sacred_bloom_active or _is_destroyed:
		return
	if is_instance_valid(_idle_glow_tween):
		_idle_glow_tween.kill()
		_idle_glow_tween = null
	if is_instance_valid(_bloom_tween):
		_bloom_tween.kill()
	_bloom_tween = create_tween().set_loops()
	var hp_energy: float = _get_hp_aura_energy()
	_bloom_tween.tween_property(_aura_light, "energy", hp_energy * 1.5, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bloom_tween.tween_property(_aura_light, "energy", hp_energy * 0.9, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _can_harvest() -> bool:
	return _sacred_bloom_active and _player_in_range and not _harvested_today \
			and not _is_destroyed and not _is_harvesting


func _cancel_harvest() -> void:
	_is_harvesting = false
	_harvest_progress = 0.0
	_interaction_prompt.set_progress(-1.0)
	_refresh_prompt()


func _complete_harvest() -> void:
	_is_harvesting = false
	_harvest_progress = 0.0
	_interaction_prompt.set_progress(-1.0)
	var remaining: int = InventoryManager.add_item(POLLEN_ITEM_ID, POLLEN_PER_HARVEST)
	if remaining > 0:
		_show_popup("Inventory full!")
		_refresh_prompt()
		return
	_harvested_today = true
	_last_harvest_day = DayNightCycle.day_count
	_pollen_particles.restart()
	_pollen_particles.emitting = true
	SfxManager.play("item_pickup")
	_show_popup("+1 Dianthus Pollen", Color(1.0, 0.8, 0.95))
	_refresh_prompt()


func _refresh_prompt() -> void:
	if not _sacred_bloom_active or _is_destroyed or not _player_in_range:
		_interaction_prompt.hide_prompt()
		return
	if _harvested_today:
		_interaction_prompt.show_interaction("Sacred Bloom resting", "Come back tomorrow", "", "",
				InteractionPrompt.DISABLED_ACCENT, InteractionPrompt.Status.DISABLED)
		return
	if _is_harvesting:
		_interaction_prompt.show_interaction("Harvesting Pollen", "", "Hold E", "Release E to cancel",
				InteractionPrompt.DEFAULT_ACCENT, InteractionPrompt.Status.NORMAL, _harvest_progress)
		return
	_interaction_prompt.show_interaction("Dianthus Core", "Sacred Bloom is ready", "Hold E", "Harvest Pollen")


func _on_harvest_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	_refresh_prompt()


func _on_harvest_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	if _is_harvesting:
		_cancel_harvest()
	_refresh_prompt()


func _show_popup(text: String, color: Color = Color(1.0, 0.8, 0.3)) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(-50, -52)
	add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


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
	hp_changed.emit(current_hp, max_hp)


func _start_breathe_animation() -> void:
	if _breathe_tween:
		_breathe_tween.kill()
	_breathe_tween = create_tween().set_loops()
	var inhale: Vector2 = _base_sprite_scale * Vector2(0.96, 1.06)
	_breathe_tween.tween_property(_sprite, "scale", inhale, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_tween.tween_property(_sprite, "scale", _base_sprite_scale, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _prepare_animation_texture() -> void:
	if core_animation_texture == null:
		return
	_sprite.texture = core_animation_texture
	_sprite.hframes = CORE_ANIMATION_FRAME_COUNT
	_sprite.vframes = 1
	_sprite.frame = IDLE_FRAME_START


func _start_idle_frame_animation() -> void:
	if _is_destroyed or core_animation_texture == null:
		return
	if is_instance_valid(_damage_frame_tween):
		return
	if is_instance_valid(_idle_frame_tween):
		_idle_frame_tween.kill()
	_idle_frame_tween = create_tween().set_loops()
	for frame_offset: int in range(IDLE_FRAME_COUNT):
		_idle_frame_tween.tween_callback(_set_core_frame.bind(IDLE_FRAME_START + frame_offset))
		_idle_frame_tween.tween_interval(IDLE_FRAME_DURATION)


func _start_idle_glow_animation() -> void:
	if _is_destroyed or _sacred_bloom_active or _tutorial_glow_active:
		return
	if is_instance_valid(_idle_glow_tween):
		_idle_glow_tween.kill()
	var hp_energy: float = _get_hp_aura_energy()
	_idle_glow_tween = create_tween().set_loops()
	_idle_glow_tween.tween_property(_aura_light, "energy", hp_energy * 1.15, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_glow_tween.tween_property(_aura_light, "energy", hp_energy * 0.82, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _play_damage_animation() -> void:
	if is_instance_valid(_damage_frame_tween):
		_damage_frame_tween.kill()
	if core_animation_texture == null:
		var tween: Tween = create_tween()
		tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
		tween.tween_property(_sprite, "modulate", Color(1.0, 0.8, 0.9), 0.2)
		return
	if is_instance_valid(_idle_frame_tween):
		_idle_frame_tween.kill()
		_idle_frame_tween = null
	_sprite.texture = core_animation_texture
	_sprite.hframes = CORE_ANIMATION_FRAME_COUNT
	_sprite.vframes = 1
	_damage_frame_tween = create_tween()
	for frame_offset: int in range(DAMAGE_FRAME_COUNT):
		_damage_frame_tween.tween_callback(_set_core_frame.bind(DAMAGE_FRAME_START + frame_offset))
		_damage_frame_tween.tween_interval(DAMAGE_FRAME_DURATION)
	_damage_frame_tween.tween_callback(_finish_damage_animation)


func _finish_damage_animation() -> void:
	_damage_frame_tween = null
	_start_idle_frame_animation()


func _get_hp_aura_energy() -> float:
	if current_hp <= 0:
		return 0.0
	return _base_aura_energy * lerpf(0.25, 1.0, get_hp_ratio())


func _on_phase_changed(phase: String) -> void:
	_regen_accumulator = 0.0
	if phase == "DAY" and _sacred_bloom_active and not _is_destroyed:
		if DayNightCycle.day_count > _last_harvest_day:
			_harvested_today = false
			_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			take_damage(20)
			print("DEBUG: Core took 20 damage. HP: %d/%d" % [current_hp, max_hp])
		elif event.keycode == KEY_F2:
			heal(20)
			print("DEBUG: Core healed 20. HP: %d/%d" % [current_hp, max_hp])
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		if _can_harvest():
			_is_harvesting = true
			_harvest_progress = 0.0
			_refresh_prompt()
			get_viewport().set_input_as_handled()
	elif event.is_action_released("interact"):
		if _is_harvesting:
			_cancel_harvest()
