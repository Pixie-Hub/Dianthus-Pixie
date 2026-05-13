class_name PlantAnimationController
extends Node

signal wither_animation_finished

@export var idle_animation: StringName = &"idle"
@export var bloom_animation: StringName = &"bloom"
@export var active_animation: StringName = &"active"
@export var wither_animation: StringName = &"wither"
@export var active_animation_min_interval: float = 0.35
@export var bloom_duration: float = 0.6
@export var active_duration: float = 0.4
@export var wither_duration: float = 0.6

var _static_sprite: Sprite2D = null
var _animated_sprite: AnimatedSprite2D = null
var _last_active_time_msec: int = -1000000
var _visual_base_scale: Vector2 = Vector2.ONE
var _visual_base_modulate: Color = Color.WHITE
var _current_tween: Tween = null
var _is_withering: bool = false


func setup(static_sprite: Sprite2D, animated_sprite: AnimatedSprite2D) -> void:
	_static_sprite = static_sprite
	_animated_sprite = animated_sprite
	var visual: CanvasItem = _static_sprite if is_instance_valid(_static_sprite) else _animated_sprite
	if visual is Node2D:
		_visual_base_scale = (visual as Node2D).scale
	if is_instance_valid(visual):
		_visual_base_modulate = visual.modulate
	_show_static_visual()


func play_bloom() -> void:
	if _is_withering:
		return
	var visual: CanvasItem = _prepare_animated_visual(bloom_animation)
	if not is_instance_valid(visual):
		return
	_kill_current_tween()
	if visual is Node2D:
		(visual as Node2D).scale = _visual_base_scale * 0.35
	visual.modulate = Color(_visual_base_modulate.r, _visual_base_modulate.g, _visual_base_modulate.b, 0.0)
	_current_tween = create_tween()
	if visual is Node2D:
		_current_tween.tween_property(visual, "scale", _visual_base_scale * 1.08, bloom_duration * 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_current_tween.tween_property(visual, "scale", _visual_base_scale, bloom_duration * 0.25)
	_current_tween.parallel().tween_property(visual, "modulate:a", _visual_base_modulate.a, bloom_duration * 0.65)
	_current_tween.tween_callback(_show_static_visual)


func play_active(_trigger_id: StringName = &"") -> void:
	if _is_withering:
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_active_time_msec < int(active_animation_min_interval * 1000.0):
		return
	_last_active_time_msec = now_msec
	var visual: CanvasItem = _prepare_animated_visual(active_animation)
	if not is_instance_valid(visual):
		return
	_kill_current_tween()
	visual.modulate = _visual_base_modulate
	if visual is Node2D:
		(visual as Node2D).scale = _visual_base_scale
	_current_tween = create_tween()
	if visual is Node2D:
		_current_tween.tween_property(visual, "scale", _visual_base_scale * 1.16, active_duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_current_tween.tween_property(visual, "scale", _visual_base_scale, active_duration * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_current_tween.parallel().tween_property(visual, "modulate", Color(1.25, 1.2, 1.0, _visual_base_modulate.a), active_duration * 0.45)
	_current_tween.tween_property(visual, "modulate", _visual_base_modulate, active_duration * 0.55)
	_current_tween.tween_callback(_show_static_visual)


func play_wither() -> Signal:
	_is_withering = true
	var visual: CanvasItem = _prepare_animated_visual(wither_animation)
	if not is_instance_valid(visual):
		call_deferred("_emit_wither_finished")
		return wither_animation_finished
	_kill_current_tween()
	visual.modulate = _visual_base_modulate
	if visual is Node2D:
		(visual as Node2D).scale = _visual_base_scale
	_current_tween = create_tween()
	if visual is Node2D:
		_current_tween.tween_property(visual, "scale", _visual_base_scale * 0.75, wither_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_current_tween.parallel().tween_property(visual, "modulate:a", 0.0, wither_duration)
	_current_tween.tween_callback(_emit_wither_finished)
	return wither_animation_finished


func _prepare_animated_visual(animation_name: StringName) -> CanvasItem:
	if is_instance_valid(_animated_sprite):
		_animated_sprite.visible = true
		if is_instance_valid(_static_sprite):
			_static_sprite.visible = false
		if _animated_sprite.sprite_frames != null and _animated_sprite.sprite_frames.has_animation(animation_name):
			_animated_sprite.play(animation_name)
		return _animated_sprite
	if is_instance_valid(_static_sprite):
		_static_sprite.visible = true
		return _static_sprite
	return null


func _show_static_visual() -> void:
	if _is_withering:
		return
	if is_instance_valid(_animated_sprite):
		if _animated_sprite.sprite_frames != null and _animated_sprite.sprite_frames.has_animation(idle_animation):
			_animated_sprite.play(idle_animation)
		_animated_sprite.visible = false
		_animated_sprite.modulate = _visual_base_modulate
		_animated_sprite.scale = _visual_base_scale
	if is_instance_valid(_static_sprite):
		_static_sprite.visible = true
		_static_sprite.modulate = _visual_base_modulate


func _get_preferred_visual() -> CanvasItem:
	if is_instance_valid(_animated_sprite):
		return _animated_sprite
	return _static_sprite


func _kill_current_tween() -> void:
	if is_instance_valid(_current_tween) and _current_tween.is_running():
		_current_tween.kill()
	_current_tween = null


func _emit_wither_finished() -> void:
	wither_animation_finished.emit()
