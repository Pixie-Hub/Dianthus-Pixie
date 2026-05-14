class_name DevourerTeaseCinematic
extends Node2D

@export var enable_cinematic_vfx: bool = true:
	set(value):
		enable_cinematic_vfx = value
		if is_inside_tree():
			_apply_cinematic_vfx_enabled(value)

@export_range(6.0, 10.0, 0.1) var shot_duration_seconds: float = 8.2
@export var auto_quit_after_seconds: float = 0.0

var _base_positions: Dictionary = {}
var _base_modulates: Dictionary = {}
var _base_light_energy: Dictionary = {}
var _base_particle_amounts: Dictionary = {}
var _time: float = 0.0
var _sequence_tween: Tween = null
var _camera_base_zoom: Vector2 = Vector2.ONE

@onready var _camera: Camera2D = %Camera2D
@onready var _vfx_root: Node2D = %DevourerTeaseCinematicVFX
@onready var _devourer_silhouette: Sprite2D = %DevourerSilhouette
@onready var _fade_to_black: Sprite2D = %FadeToBlack
@onready var _eye_glint: Sprite2D = %EyeGlint


func _ready() -> void:
	_camera.make_current()
	_camera_base_zoom = _camera.zoom
	_cache_vfx_state(_vfx_root)
	_prepare_initial_state()
	_apply_cinematic_vfx_enabled(enable_cinematic_vfx)
	_play_camera_sequence()


func _process(delta: float) -> void:
	_time += delta
	if auto_quit_after_seconds > 0.0 and _time >= auto_quit_after_seconds:
		get_tree().quit()
	if not enable_cinematic_vfx:
		return
	_animate_fog_bands()
	_animate_glow_accents()
	_animate_shadow_motes()


func _exit_tree() -> void:
	if _sequence_tween and _sequence_tween.is_valid():
		_sequence_tween.kill()
	_sequence_tween = null


func _prepare_initial_state() -> void:
	_camera.position = Vector2(320, 196)
	_camera.zoom = _camera_base_zoom
	_fade_to_black.modulate.a = 1.0
	_devourer_silhouette.frame = 1
	_devourer_silhouette.modulate = Color(0.055, 0.035, 0.08, 0.92)
	_eye_glint.modulate.a = 0.0


func _play_camera_sequence() -> void:
	if _sequence_tween and _sequence_tween.is_valid():
		_sequence_tween.kill()
	_sequence_tween = create_tween()
	_sequence_tween.set_parallel(true)
	_sequence_tween.tween_property(_camera, "position", Vector2(390, 162), 6.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sequence_tween.tween_property(_camera, "zoom", _camera_base_zoom * 1.22, 6.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sequence_tween.tween_property(_fade_to_black, "modulate:a", 0.0, 1.0)
	_sequence_tween.set_parallel(false)
	_sequence_tween.tween_interval(5.5)
	_sequence_tween.tween_callback(_pulse_eye_glint)
	_sequence_tween.tween_interval(0.8)
	_sequence_tween.tween_property(_fade_to_black, "modulate:a", 1.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _pulse_eye_glint() -> void:
	if not enable_cinematic_vfx:
		return
	var glint_tween: Tween = create_tween()
	glint_tween.tween_property(_eye_glint, "modulate:a", 0.62, 0.14)
	glint_tween.tween_property(_eye_glint, "modulate:a", 0.0, 0.48)
	var silhouette_tween: Tween = create_tween()
	silhouette_tween.tween_property(_devourer_silhouette, "modulate", Color(0.085, 0.045, 0.13, 0.96), 0.18)
	silhouette_tween.tween_property(_devourer_silhouette, "modulate", Color(0.055, 0.035, 0.08, 0.92), 0.58)


func _cache_vfx_state(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Node2D:
			_base_positions[child] = (child as Node2D).position
		if child is CanvasItem:
			_base_modulates[child] = (child as CanvasItem).modulate
		if child is Light2D:
			_base_light_energy[child] = (child as Light2D).energy
		if child is GPUParticles2D:
			_base_particle_amounts[child] = (child as GPUParticles2D).amount
		_cache_vfx_state(child)


func _apply_cinematic_vfx_enabled(enabled: bool) -> void:
	_apply_enabled_recursive(_vfx_root, enabled)
	set_process(true)


func _apply_enabled_recursive(node: Node, enabled: bool) -> void:
	for child: Node in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = enabled
			if enabled and _base_modulates.has(child):
				(child as CanvasItem).modulate = _base_modulates[child]
		if child is GPUParticles2D:
			var particles: GPUParticles2D = child as GPUParticles2D
			particles.emitting = enabled
			particles.amount = int(_base_particle_amounts.get(child, particles.amount)) if enabled else 0
		if child is Light2D:
			var light: Light2D = child as Light2D
			light.enabled = enabled
			if enabled:
				light.energy = float(_base_light_energy.get(child, light.energy))
		_apply_enabled_recursive(child, enabled)


func _animate_fog_bands() -> void:
	for node_variant: Variant in _base_positions.keys():
		var node: Node2D = node_variant as Node2D
		if not is_instance_valid(node) or not node.name.begins_with("FogBand"):
			continue
		var base_position: Vector2 = _base_positions[node]
		var index: int = node.get_index()
		var drift_x: float = sin(_time * (0.16 + float(index) * 0.025) + float(index)) * 14.0
		node.position = base_position + Vector2(drift_x, 0.0)
		_update_shader_time(node as CanvasItem, 1.0)


func _animate_glow_accents() -> void:
	for node_variant: Variant in _base_light_energy.keys():
		var light: Light2D = node_variant as Light2D
		if not is_instance_valid(light):
			continue
		var base_energy: float = float(_base_light_energy[light])
		light.energy = base_energy * (0.84 + sin(_time * 1.25 + float(light.get_index())) * 0.12)
	for node_variant: Variant in _base_modulates.keys():
		var item: CanvasItem = node_variant as CanvasItem
		if not is_instance_valid(item) or not item.name.contains("Glow"):
			continue
		var base_color: Color = _base_modulates[item]
		var alpha_scale: float = 0.82 + sin(_time * 0.9 + float(item.get_index())) * 0.1
		item.modulate = Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha_scale)
		_update_shader_time(item, alpha_scale)


func _animate_shadow_motes() -> void:
	for node_variant: Variant in _base_modulates.keys():
		var item: CanvasItem = node_variant as CanvasItem
		if not is_instance_valid(item) or not item.name.contains("Mote"):
			continue
		var base_color: Color = _base_modulates[item]
		var alpha_scale: float = 0.74 + sin(_time * 0.55 + float(item.get_index())) * 0.16
		item.modulate = Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha_scale)
		_update_shader_time(item, alpha_scale)


func _update_shader_time(item: CanvasItem, alpha_scale: float) -> void:
	var shader_material: ShaderMaterial = item.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("mist_time", _time)
	shader_material.set_shader_parameter("runtime_alpha_scale", alpha_scale)
