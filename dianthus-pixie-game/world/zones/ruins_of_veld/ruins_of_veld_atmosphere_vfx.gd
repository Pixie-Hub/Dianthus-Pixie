extends Node2D

const SETTINGS_PATH: String = "user://settings.cfg"
const SETTINGS_SECTION: String = "graphics"
const ATMOSPHERIC_VFX_KEY: String = "atmospheric_vfx"

@export var enable_atmosphere_vfx: bool = true:
	set(value):
		enable_atmosphere_vfx = value
		if is_inside_tree():
			apply_atmosphere_enabled(_should_enable_atmosphere())
@export var enable_particles: bool = true:
	set(value):
		enable_particles = value
		if is_inside_tree():
			apply_atmosphere_enabled(_should_enable_atmosphere())
@export var enable_mist: bool = true:
	set(value):
		enable_mist = value
		if is_inside_tree():
			apply_atmosphere_enabled(_should_enable_atmosphere())
@export_range(0.0, 2.0, 0.05) var teaser_intensity: float = 1.55

var _mist_offsets: Dictionary = {}
var _base_modulates: Dictionary = {}
var _base_light_energy: Dictionary = {}
var _base_particle_amounts: Dictionary = {}
var _moonbeam_layers: Dictionary = {}
var _time: float = 0.0
var _settings_enabled: bool = true


func _ready() -> void:
	_settings_enabled = _load_atmosphere_setting()
	_cache_animation_state(self)
	apply_atmosphere_enabled(_should_enable_atmosphere())


func _process(delta: float) -> void:
	_time += delta
	_animate_mist()
	_animate_lights()
	_animate_shader_layers()


func apply_atmosphere_enabled(enabled: bool) -> void:
	visible = enabled
	set_process(enabled)
	_apply_enabled_recursive(self, enabled)


func _should_enable_atmosphere() -> bool:
	return enable_atmosphere_vfx and _settings_enabled


func _load_atmosphere_setting() -> bool:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return true
	return bool(config.get_value(SETTINGS_SECTION, ATMOSPHERIC_VFX_KEY, true))


func _cache_animation_state(node: Node) -> void:
	if node != self:
		if node is CanvasItem:
			_base_modulates[node] = (node as CanvasItem).modulate
		if node is Light2D:
			_base_light_energy[node] = (node as Light2D).energy
		if node is GPUParticles2D:
			_base_particle_amounts[node] = (node as GPUParticles2D).amount
		elif node is CPUParticles2D:
			_base_particle_amounts[node] = (node as CPUParticles2D).amount
		if node.name.begins_with("MistBand"):
			_mist_offsets[node] = (node as Node2D).position
		if _is_moonbeam_layer(node):
			_moonbeam_layers[node] = {
				"amplitude": _get_layer_flicker_amplitude(node.name),
				"speed": _get_layer_flicker_speed(node.name),
			}
	for child: Node in node.get_children():
		_cache_animation_state(child)


func _apply_enabled_recursive(node: Node, enabled: bool) -> void:
	for child: Node in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = enabled
		if child is GPUParticles2D:
			var particles: GPUParticles2D = child as GPUParticles2D
			particles.emitting = enabled and enable_particles
			particles.amount = int(_base_particle_amounts.get(child, particles.amount))
			if not enable_particles:
				particles.emitting = false
				particles.amount = 0
		elif child is CPUParticles2D:
			var cpu_particles: CPUParticles2D = child as CPUParticles2D
			cpu_particles.emitting = enabled and enable_particles
			cpu_particles.amount = int(_base_particle_amounts.get(child, cpu_particles.amount))
			if not enable_particles:
				cpu_particles.emitting = false
				cpu_particles.amount = 0
		if child is Light2D:
			var light: Light2D = child as Light2D
			light.enabled = enabled
			light.energy = float(_base_light_energy.get(child, light.energy)) * teaser_intensity
		if child.name == "MistBands" or child.name.begins_with("MistBand"):
			if child is CanvasItem:
				(child as CanvasItem).visible = enabled and enable_mist
		_apply_enabled_recursive(child, enabled)


func _animate_mist() -> void:
	if not enable_mist:
		return
	for node_variant: Variant in _mist_offsets.keys():
		var node: Node2D = node_variant as Node2D
		if not is_instance_valid(node):
			continue
		var base_position: Vector2 = _mist_offsets[node]
		var index: int = int(node.get_index())
		var drift: float = sin(_time * (0.08 + index * 0.015) + float(index)) * 9.0
		node.position = base_position + Vector2(drift, 0.0)


func _animate_lights() -> void:
	for node_variant: Variant in _base_light_energy.keys():
		var light: Light2D = node_variant as Light2D
		if not is_instance_valid(light):
			continue
		var base_energy: float = float(_base_light_energy[light]) * teaser_intensity
		light.energy = base_energy * (0.9 + sin(_time * 0.7 + float(light.get_index())) * 0.08)


func _animate_shader_layers() -> void:
	for node_variant: Variant in _base_modulates.keys():
		var item: CanvasItem = node_variant as CanvasItem
		if not is_instance_valid(item):
			continue
		var base_color: Color = _base_modulates[item]
		var alpha_scale: float = teaser_intensity
		if _moonbeam_layers.has(item):
			var layer_data: Dictionary = _moonbeam_layers[item]
			var amplitude: float = float(layer_data.get("amplitude", 0.04))
			var speed: float = float(layer_data.get("speed", 0.8))
			alpha_scale *= 1.0 + sin(_time * speed + _get_layer_phase(item)) * amplitude
		elif item.name.contains("Mote") or item.name.contains("Pollen"):
			alpha_scale *= 0.85 + sin(_time * 0.45 + float(item.get_index())) * 0.12
		else:
			_update_shader_time(item, alpha_scale)
			continue
		item.modulate = Color(base_color.r, base_color.g, base_color.b, base_color.a)
		_update_shader_time(item, alpha_scale)


func _update_shader_time(item: CanvasItem, alpha_scale: float) -> void:
	var shader_material: ShaderMaterial = item.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("mist_time", _time)
	shader_material.set_shader_parameter("runtime_alpha_scale", alpha_scale)


func _is_moonbeam_layer(node: Node) -> bool:
	return node.name == "BeamWide" \
		or node.name == "BeamCore" \
		or node.name == "BeamStreaks" \
		or node.name == "GroundGlow"


func _get_layer_flicker_amplitude(layer_name: StringName) -> float:
	match layer_name:
		&"BeamWide":
			return 0.038
		&"BeamCore":
			return 0.055
		&"BeamStreaks":
			return 0.072
		&"GroundGlow":
			return 0.028
		_:
			return 0.035


func _get_layer_flicker_speed(layer_name: StringName) -> float:
	match layer_name:
		&"BeamWide":
			return 0.78
		&"BeamCore":
			return 0.66
		&"BeamStreaks":
			return 0.54
		&"GroundGlow":
			return 0.44
		_:
			return 0.60


func _get_layer_phase(item: CanvasItem) -> float:
	var beam_parent: Node = item.get_parent()
	var beam_index: int = 0
	if beam_parent != null:
		beam_index = beam_parent.get_index()
	return float(beam_index) * 1.37 + float(item.get_index()) * 0.73
