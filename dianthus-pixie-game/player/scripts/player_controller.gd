extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
signal attack_hit(target: Node, damage: int)
signal energy_changed(current_energy: int, max_energy: int)

const TILE_SIZE: int = 16
const SPEED: float = TILE_SIZE * 5.0
const MAX_HP: int = 100
const RESPAWN_DELAY: float = 5.0
const INVINCIBILITY_DURATION: float = 3.0
const ENERGY_DEATH_PENALTY: float = 0.25
const BASE_MAX_ENERGY: int = 100
const ENERGY_PER_HIT: int = 3
const ENERGY_PER_KILL: int = 10
const ENERGY_NEAR_CORE_RATE: float = 2.0
const CORE_PROXIMITY_RADIUS: float = 64.0

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_tree: AnimationTree = %AnimationTree
@onready var _camera: Camera2D = %Camera2D
@onready var _sword_hitbox: Area2D = %SwordHitbox
@onready var _sword_sfx: AudioStreamPlayer2D = %SwordSFX

var _state_machine: AnimationNodeStateMachinePlayback

var last_direction: Vector2 = Vector2.DOWN
var current_hp: int = MAX_HP
var is_dead: bool = false
var is_invincible: bool = false
var _blink_tween: Tween = null
var is_attacking: bool = false
var _attack_cooldown_timer: float = 0.0
var _hit_bodies: Array[Node2D] = []
var _current_weapon: WeaponData = null
var _debug_plant_cycle: int = 0
var current_energy: int = 0
var max_energy: int = BASE_MAX_ENERGY
var _energy_regen_accumulator: float = 0.0
var damage_reduction: float = 0.0

func _ready() -> void:
	_anim_tree.active = true
	_state_machine = _anim_tree["parameters/playback"]
	_update_blend_position()
	hp_changed.emit(current_hp, MAX_HP)
	energy_changed.emit(current_energy, max_energy)
	_current_weapon = CraftingManager.get_weapon_data("thorn_sword")
	_sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	CraftingManager.weapon_crafted.connect(_on_weapon_crafted)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_cooldown_timer = max(_attack_cooldown_timer - delta, 0.0)
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		last_direction = _dominant_direction(dir)
		velocity = dir * SPEED
		_travel("walk")
	else:
		velocity = Vector2.ZERO
		_travel("idle")
	_update_blend_position()
	move_and_slide()
	_update_core_energy_regen(delta)

func _dominant_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) >= abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP

func _travel(state: String) -> void:
	var current: StringName = _state_machine.get_current_node()
	if current == state:
		return
	if current == &"hurt" or current == &"death" or current == &"attack":
		return
	_state_machine.travel(state)

func _direction_to_blend() -> Vector2:
	if last_direction == Vector2.DOWN:
		return Vector2(0, 1)
	if last_direction == Vector2.UP:
		return Vector2(0, -1)
	if last_direction == Vector2.LEFT:
		return Vector2(-1, 0)
	return Vector2(1, 0)

func _update_blend_position() -> void:
	var blend: Vector2 = _direction_to_blend()
	_anim_tree["parameters/idle/blend_position"] = blend
	_anim_tree["parameters/walk/blend_position"] = blend
	_anim_tree["parameters/run/blend_position"] = blend
	_anim_tree["parameters/hurt/blend_position"] = blend
	_anim_tree["parameters/death/blend_position"] = blend
	if (_anim_tree.tree_root as AnimationNodeStateMachine).has_node(&"attack"):
		_anim_tree["parameters/attack/blend_position"] = blend

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	_camera.limit_left = left
	_camera.limit_top = top
	_camera.limit_right = right
	_camera.limit_bottom = bottom

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("attack"):
		if not is_dead and not is_attacking and _attack_cooldown_timer <= 0.0:
			_start_attack()
			return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			if event.shift_pressed:
				current_energy = 50
				energy_changed.emit(current_energy, max_energy)
				print("DEBUG: Energy set to 50/%d" % max_energy)
			else:
				take_damage(25)
				print("DEBUG: Player took 25 damage (DR=%.0f%%). HP: %d/%d" % [damage_reduction * 100, current_hp, MAX_HP])
		elif event.keycode == KEY_F4:
			if event.shift_pressed:
				current_energy = max_energy
				energy_changed.emit(current_energy, max_energy)
				print("DEBUG: Energy filled to %d/%d" % [current_energy, max_energy])
			else:
				heal(25)
				print("DEBUG: Player healed 25. HP: %d/%d" % [current_hp, MAX_HP])
		elif event.keycode == KEY_F5:
			_debug_spawn_shadowling()
		elif event.keycode == KEY_F6:
			get_tree().call_group(&"enemies", "die")
			print("DEBUG: Killed all enemies.")
		elif event.keycode == KEY_F7:
			var phase_before: String = DayNightCycle.get_phase_name()
			DayNightCycle.debug_skip_phase()
			print("DEBUG: Skipped phase %s." % phase_before)
		elif event.keycode == KEY_F8:
			var spawner: Node = get_tree().current_scene.find_child("WaveSpawner", true, false)
			if spawner != null and spawner.has_method("start_wave"):
				spawner.start_wave()
				print("DEBUG: Force-started wave.")
			else:
				push_warning("DEBUG: WaveSpawner not found in scene.")
		elif event.keycode == KEY_F9:
			var spawner: Node = get_tree().current_scene.find_child("WaveSpawner", true, false)
			if spawner != null and spawner.has_method("cleanup_wave"):
				spawner.cleanup_wave()
				print("DEBUG: Force-cleared wave.")
			else:
				push_warning("DEBUG: WaveSpawner not found in scene.")
		elif event.keycode == KEY_F10:
			_debug_place_plant()
			print("DEBUG: F10 direct-places at mouse (no grid). Use P key for proper grid placement mode.")
		elif event.keycode == KEY_F11:
			if event.shift_pressed:
				SaveManager.delete_save()
				print("DEBUG: Deleted save file.")
			else:
				var ok: bool = SaveManager.save_to_slot(true)
				print("DEBUG: Manual save %s" % ("OK" if ok else "BLOCKED (not in EXPLORATION)"))
		elif event.keycode == KEY_F12:
			var ok: bool = SaveManager.load_from_slot()
			print("DEBUG: Load save %s" % ("OK" if ok else "FAILED"))
		elif event.keycode == KEY_INSERT:
			if event.shift_pressed:
				InventoryManager.add_item("bougainvillea_extract", 1)
				InventoryManager.add_item("rafflesia_extract", 1)
				InventoryManager.add_item("beringin_root", 1)
				InventoryManager.add_item("kecombrang_extract", 1)
				InventoryManager.add_item("kunyit_extract", 1)
				InventoryManager.add_item("petal_shard", 5)
				InventoryManager.add_item("verdant_sap", 5)
				InventoryManager.add_item("moonspore", 3)
				InventoryManager.add_item("shadow_resin", 2)
				InventoryManager.add_item("dianthus_pollen", 1)
				InventoryManager.add_item("bougainvillea_seed", 3)
				InventoryManager.add_item("rafflesia_seed", 2)
				InventoryManager.add_item("bunga_api_seed", 1)
				InventoryManager.add_item("bunga_bayang_seed", 1)
				InventoryManager.add_item("melati_emas_seed", 1)
				InventoryManager.add_item("baja_kuning_seed", 1)
				print("DEBUG: Added crafting + plant seed test materials (Shift+Insert).")
			else:
				InventoryManager.add_item("petal_shard", 5)
				InventoryManager.add_item("verdant_sap", 2)
				InventoryManager.add_item("moonspore", 1)
				print("DEBUG: Added 5 Petal Shard, 2 Verdant Sap, 1 Moonspore to inventory.")
		if Input.is_action_just_pressed("breeding_toggle"):
			var bscreen: Node = get_tree().current_scene.find_child("CrossBreedingScreen", true, false)
			if bscreen != null:
				if bscreen.visible:
					bscreen.close()
				else:
					bscreen.open()
			get_viewport().set_input_as_handled()
		#DEBUG
		if Input.is_action_just_pressed("crafting_toggle"):
			var screen: Node = get_tree().current_scene.find_child("CraftingScreen", true, false)
			if screen != null:
				if screen.visible:
					screen.close()
				else:
					screen.open()
			get_viewport().set_input_as_handled()

func take_damage(amount: int) -> void:
	if is_dead or is_invincible:
		return
	var reduced: int = int(float(amount) * (1.0 - damage_reduction))
	reduced = max(reduced, 1)
	current_hp = max(current_hp - reduced, 0)
	hp_changed.emit(current_hp, MAX_HP)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	if current_hp <= 0:
		_die()

func heal(amount: int) -> void:
	if is_dead:
		return
	current_hp = min(current_hp + amount, MAX_HP)
	hp_changed.emit(current_hp, MAX_HP)

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()
	_state_machine.travel("death")
	_sprite.modulate.a = 0.3
	set_collision_layer_value(3, false)
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_respawn()

func _respawn() -> void:
	if is_instance_valid(GameManager.dianthus_core):
		global_position = GameManager.dianthus_core.global_position + Vector2(0, 32)
	current_hp = MAX_HP
	is_dead = false
	_sprite.modulate = Color.WHITE
	set_collision_layer_value(3, true)
	hp_changed.emit(current_hp, MAX_HP)
	player_respawned.emit()
	var energy_penalty: int = int(current_energy * ENERGY_DEATH_PENALTY)
	current_energy = max(current_energy - energy_penalty, 0)
	energy_changed.emit(current_energy, max_energy)
	_state_machine.travel("idle")
	_update_blend_position()
	_start_invincibility()

func _start_invincibility() -> void:
	is_invincible = true
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_sprite, "modulate:a", 0.4, 0.15)
	_blink_tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	is_invincible = false
	if is_instance_valid(_blink_tween):
		_blink_tween.kill()
	_sprite.modulate = Color.WHITE

func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	_hit_bodies.clear()
	_state_machine.travel("attack")
	_update_blend_position()
	var hitbox_offset: Vector2
	if last_direction == Vector2.DOWN:
		hitbox_offset = Vector2(0, 4)
	elif last_direction == Vector2.UP:
		hitbox_offset = Vector2(0, -28)
	elif last_direction == Vector2.LEFT:
		hitbox_offset = Vector2(-16, -12)
	else:
		hitbox_offset = Vector2(16, -12)
	_sword_hitbox.position = hitbox_offset
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	print("DEBUG: Attack! Damage: %d, Direction: %s" % [_current_weapon.damage, last_direction])
	if _sword_sfx.stream != null:
		_sword_sfx.play()
	await get_tree().create_timer(_current_weapon.cooldown * 0.25).timeout
	hitbox_shape.disabled = false
	await get_tree().create_timer(_current_weapon.cooldown * 0.5).timeout
	hitbox_shape.disabled = true
	await get_tree().create_timer(_current_weapon.cooldown * 0.25).timeout
	_end_attack()

func _end_attack() -> void:
	is_attacking = false
	_attack_cooldown_timer = _current_weapon.cooldown
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	hitbox_shape.disabled = true
	_state_machine.travel("idle")

func _on_weapon_crafted(weapon_id: String) -> void:
	var data: WeaponData = CraftingManager.get_weapon_data(weapon_id)
	if data != null:
		_current_weapon = data
		print("[Player] Equipped crafted weapon: %s" % weapon_id)


func _update_core_energy_regen(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(GameManager.dianthus_core):
		return
	var dist: float = global_position.distance_to(
		GameManager.dianthus_core.global_position)
	if dist > CORE_PROXIMITY_RADIUS:
		_energy_regen_accumulator = 0.0
		return
	_energy_regen_accumulator += ENERGY_NEAR_CORE_RATE * delta
	if _energy_regen_accumulator >= 1.0:
		var amount: int = int(_energy_regen_accumulator)
		_energy_regen_accumulator -= float(amount)
		add_energy(amount)


func add_energy(amount: int) -> void:
	if is_dead:
		return
	current_energy = min(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)


func try_spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false
	current_energy -= amount
	energy_changed.emit(current_energy, max_energy)
	return true
	# TODO (PLANT-08): Hook into active skill input.


func _debug_place_plant() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var scene_paths: Array[String] = [
		"res://plants/entities/bougainvillea.tscn",
		"res://plants/entities/rafflesia.tscn",
		"res://plants/entities/bunga_api.tscn",
		"res://plants/entities/bunga_bayang.tscn",
		"res://plants/entities/melati_emas.tscn",
		"res://plants/entities/baja_kuning.tscn",
	]
	var labels: Array[String] = ["Bougainvillea", "Rafflesia", "Bunga Api", "Bunga Bayang", "Melati Emas", "Baja Kuning"]
	if _debug_plant_cycle < scene_paths.size():
		var scene: PackedScene = load(scene_paths[_debug_plant_cycle])
		if scene == null:
			push_warning("DEBUG: Could not load %s scene." % labels[_debug_plant_cycle])
			return
		var plant: Node2D = scene.instantiate()
		plant.global_position = mouse_pos
		get_tree().current_scene.add_child(plant)
		print("[Debug] Placed %s at %s" % [labels[_debug_plant_cycle], mouse_pos])
	else:
		for plant in get_tree().get_nodes_in_group(&"plants"):
			plant.queue_free()
		print("[Debug] Cleared all plants")
	_debug_plant_cycle = (_debug_plant_cycle + 1) % 7


func _debug_spawn_shadowling() -> void:
	var scene: PackedScene = load("res://enemies/shadowling/shadowling.tscn")
	if scene == null:
		push_warning("DEBUG: Could not load Shadowling scene.")
		return
	var shadowling: Node2D = scene.instantiate() as Node2D
	var spawn_pos: Vector2 = global_position + Vector2(100, 0)
	if get_viewport() != null:
		var mouse_world: Vector2 = get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		spawn_pos = mouse_world
	shadowling.global_position = spawn_pos
	get_tree().current_scene.add_child(shadowling)
	if shadowling.has_method("activate"):
		shadowling.activate()
	print("DEBUG: Spawned Shadowling at %s" % spawn_pos)


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(_current_weapon.damage)
	attack_hit.emit(body, _current_weapon.damage)
	print("DEBUG: Hit %s for %d damage" % [body.name, _current_weapon.damage])
	add_energy(ENERGY_PER_HIT)
	# TODO (VFX-05): Add impact particles on hit.
