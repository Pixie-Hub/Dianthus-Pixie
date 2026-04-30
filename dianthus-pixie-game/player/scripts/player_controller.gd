extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
signal attack_hit(target: Node, damage: int)
signal energy_changed(current_energy: int, max_energy: int)
signal loadout_changed(weapon_slots: Array, skill_id: String, selected_slot: int)

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
const WEAPON_SLOT_COUNT: int = 2
const SKILL_ENERGY_COST: int = 30

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_tree: AnimationTree = %AnimationTree
@onready var _camera: Camera2D = %Camera2D
@onready var _sword_hitbox: Area2D = %SwordHitbox

var _state_machine: AnimationNodeStateMachinePlayback

var last_direction: Vector2 = Vector2.DOWN
var current_hp: int = MAX_HP
var is_dead: bool = false
var is_invincible: bool = false
var _blink_tween: Tween = null
var is_attacking: bool = false
var _attack_cooldown_timer: float = 0.0
var _hit_bodies: Array[Node2D] = []
var weapon_slots: Array[String] = ["", ""]
var active_skill_id: String = ""
var selected_weapon_slot: int = 0
var _current_weapon: WeaponData = null
var _debug_plant_cycle: int = 0
var _debug_enemy_index: int = 0

const DEBUG_ENEMY_SCENES: Array[String] = [
	"res://enemies/shadowling/shadowling.tscn",
	"res://enemies/voidrunner/voidrunner.tscn",
	"res://enemies/stonehusk/stonehusk.tscn",
	"res://enemies/phantom_weaver/phantom_weaver.tscn",
]
var current_energy: int = 0
var max_energy: int = BASE_MAX_ENERGY
var _energy_regen_accumulator: float = 0.0
var damage_reduction: float = 0.0
var attack_speed_bonus: float = 0.0
var bonus_melee_damage: int = 0

const PETAL_SHIELD_DR: float = 0.8
const PETAL_SHIELD_PERFECT_WINDOW: float = 0.2
const PETAL_SHIELD_COUNTER_STUN: float = 0.6

var is_blocking: bool = false
var _block_raised_time: float = -1.0
var _saved_damage_reduction: float = 0.0

func _ready() -> void:
	PlayerAnimationBuilder.build(%AnimationPlayer, "Sprite2D")
	PlayerAnimationBuilder.build_tree(%AnimationTree)
	_anim_tree.active = true
	_state_machine = _anim_tree["parameters/playback"]
	_update_blend_position()
	hp_changed.emit(current_hp, MAX_HP)
	energy_changed.emit(current_energy, max_energy)
	if not weapon_slots[0].is_empty():
		_current_weapon = CraftingManager.get_weapon_data(weapon_slots[0])
	_sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	CraftingManager.weapon_crafted.connect(_on_weapon_crafted)
	loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)

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
	if Input.is_action_just_pressed("hotbar_weapon_1") and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_SHIFT):
		select_weapon_slot(0)
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed("hotbar_weapon_2") and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_SHIFT):
		select_weapon_slot(1)
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed("quest_log_toggle"):
		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT):
			var active: Array[QuestData] = QuestManager.get_active_quests()
			print("=== QUEST SUMMARY (%d active) ===" % active.size())
			for q: QuestData in active:
				var prog: Dictionary = QuestManager.get_progress(q.quest_id)
				print("  [%s] %s" % [QuestData.Type.keys()[q.quest_type], q.display_name])
				for obj_id: StringName in prog:
					var info: Dictionary = prog[obj_id]
					print("    %s: %d/%d" % [info.get("description", obj_id), info.get("current", 0), info.get("target", 1)])
			print("  Unlock flags: %s" % str(UnlockFlags.serialize()))
			get_viewport().set_input_as_handled()
			return
		elif Input.is_key_pressed(KEY_SHIFT):
			DailyQuestRoller.force_reroll()
			get_viewport().set_input_as_handled()
			return
		var screen: Node = get_tree().current_scene.find_child("QuestLogScreen", true, false)
		if screen != null and screen.has_method("toggle"):
			screen.toggle()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed("activate_skill") and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_SHIFT):
		_activate_skill()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed("loadout_toggle") and not Input.is_key_pressed(KEY_SHIFT):
		var lscreen: Node = get_tree().current_scene.find_child("LoadoutScreen", true, false)
		if lscreen != null:
			if lscreen.visible:
				lscreen.close()
			else:
				lscreen.open()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed("attack"):
		if not is_dead and not is_attacking and _attack_cooldown_timer <= 0.0:
			if _current_weapon == null:
				print("[Player] No weapon in selected slot — cannot attack.")
				return
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
			_debug_spawn_enemy()
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
				InventoryManager.add_item("melati_seed", 2)
				InventoryManager.add_item("wijaya_kusuma_seed", 1)
				InventoryManager.add_item("beringin_seed", 1)
				InventoryManager.add_item("kecombrang_seed", 1)
				InventoryManager.add_item("kunyit_seed", 1)
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
		if event.keycode == KEY_L and event.shift_pressed:
			for wid: String in CraftingManager.get_owned_weapon_ids():
				pass
			for wid: String in ["thorn_sword", "spore_bomb", "vine_whip", "petal_shield",
					"blazeblade", "void_grenade", "crystal_lash", "iron_bloom_shield"]:
				CraftingManager.owned_weapons[wid] = true
			print("DEBUG: Shift+L — granted all 8 weapons.")
			var ls2: Node = get_tree().current_scene.find_child("LoadoutScreen", true, false)
			if ls2 != null and ls2.has_method("_refresh"):
				ls2._refresh()
		if event.keycode == KEY_1 and event.shift_pressed:
			equip_weapon(0, "spore_bomb")
			print("DEBUG: Shift+1 — Equip Spore Bomb to slot 1.")
		elif event.keycode == KEY_2 and event.shift_pressed:
			equip_weapon(0, "vine_whip")
			print("DEBUG: Shift+2 — Equip Vine Whip to slot 1.")
		elif event.keycode == KEY_3 and event.shift_pressed:
			equip_weapon(0, "petal_shield")
			print("DEBUG: Shift+3 — Equip Petal Shield to slot 1.")
		elif event.keycode == KEY_5 and event.shift_pressed and not event.ctrl_pressed:
			ZoneTracker.enter_zone("ruins_of_veld")
			print("DEBUG: Shift+5 — Emitted zone_entered{zone_id=ruins_of_veld}.")
		elif event.keycode == KEY_6 and event.shift_pressed:
			QuestManager._on_voidlord_defeated()
			print("DEBUG: Shift+6 — Emitted voidlord_defeated.")
		elif event.keycode == KEY_7 and event.shift_pressed:
			QuestManager._on_devourer_defeated()
			print("DEBUG: Shift+7 — Emitted devourer_defeated.")
			print("DEBUG: flag_story_devourer_defeated == %s" % str(UnlockFlags.has_flag("flag_story_devourer_defeated")))
		elif event.keycode == KEY_1 and event.ctrl_pressed and not event.shift_pressed:
			EndingManager.force_trigger("true")
			print("DEBUG: Ctrl+1 — Force-triggered True ending.")
		elif event.keycode == KEY_2 and event.ctrl_pressed and not event.shift_pressed:
			EndingManager.force_trigger("survival")
			print("DEBUG: Ctrl+2 — Force-triggered Survival ending.")
		elif event.keycode == KEY_3 and event.ctrl_pressed and not event.shift_pressed:
			EndingManager.force_trigger("discovery")
			print("DEBUG: Ctrl+3 — Force-triggered Discovery ending.")
		elif event.keycode == KEY_4 and event.ctrl_pressed and not event.shift_pressed:
			GameManager.endless_mode = !GameManager.endless_mode
			print("DEBUG: Ctrl+4 — Endless Mode: %s" % ("ON" if GameManager.endless_mode else "OFF"))
		elif event.keycode == KEY_4 and event.ctrl_pressed and event.shift_pressed:
			var rank: int = EndlessLeaderboard.submit_score(DayNightCycle.day_count)
			print("DEBUG: Ctrl+Shift+4 — Submitted Day %d to leaderboard. Rank: #%d. Best: Day %d." % [DayNightCycle.day_count, rank, EndlessLeaderboard.get_best_day()])
		elif event.keycode == KEY_5 and event.ctrl_pressed and event.shift_pressed:
			QuestManager.start_quest(&"story_01_whispers")
			print("DEBUG: Ctrl+Shift+5 — Force-started story_01_whispers.")
		elif event.keycode == KEY_F and event.ctrl_pressed and event.shift_pressed:
			var story_active: Array[QuestData] = QuestManager.get_active_quests()
			var found_story: bool = false
			for q: QuestData in story_active:
				if q.quest_type == QuestData.Type.STORY:
					print("DEBUG: Ctrl+Shift+F — Force-failing story quest: %s" % q.quest_id)
					QuestManager.fail_quest(q.quest_id, "time_limit")
					found_story = true
					break
			if not found_story:
				print("DEBUG: Ctrl+Shift+F — No active story quest to fail.")
		if event.keycode == KEY_K and event.shift_pressed and not event.alt_pressed:
			var active: Array[QuestData] = QuestManager.get_active_quests()
			if active.is_empty():
				print("DEBUG: No active quests.")
			for q: QuestData in active:
				var prog: Dictionary = QuestManager.get_progress(q.quest_id)
				print("[Quest] %s (%s)" % [q.display_name, q.quest_id])
				for obj_id: StringName in prog:
					var entry: Dictionary = prog[obj_id]
					print("  %s: %d / %d" % [entry.get("description", obj_id), entry.get("current", 0), entry.get("target", 1)])
		if event.keycode == KEY_K and event.shift_pressed and event.alt_pressed:
			var active2: Array[QuestData] = QuestManager.get_active_quests()
			if active2.is_empty():
				print("DEBUG: No active quests to force-complete.")
			else:
				var first: QuestData = active2[0]
				print("DEBUG: Force-completing quest: %s" % first.quest_id)
				QuestManager.complete_quest(first.quest_id)
		if event.keycode == KEY_J and event.shift_pressed:
			for pid: String in PlantRegistry.get_all_plant_ids():
				CodexManager.discover_plant(pid)
			print("DEBUG: Shift+J — discovered all %d plants in codex." % PlantRegistry.get_all_plant_ids().size())
		if Input.is_action_just_pressed("codex_toggle"):
			var cscreen: Node = get_tree().current_scene.find_child("CodexScreen", true, false)
			if cscreen != null:
				if cscreen.visible:
					cscreen.close()
				else:
					cscreen.open()
			get_viewport().set_input_as_handled()
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
	if is_blocking:
		var window: float = PETAL_SHIELD_PERFECT_WINDOW
		if _current_weapon != null and _current_weapon.weapon_id == "iron_bloom_shield":
			window = 0.3
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _block_raised_time
		if elapsed <= window:
			print("[Player] Perfect block! Counter-attack.")
			_trigger_petal_counter()
			return
		SfxManager.play("petal_shield_block")
	var reduced: int = int(float(amount) * (1.0 - damage_reduction))
	reduced = max(reduced, 1)
	current_hp = max(current_hp - reduced, 0)
	hp_changed.emit(current_hp, MAX_HP)
	SfxManager.play("player_take_damage")
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
	if is_blocking:
		_drop_block()
	is_dead = true
	is_attacking = false
	SfxManager.play("player_death")
	var _hs: CollisionShape2D = _sword_hitbox.get_child(0)
	_hs.disabled = true
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
	SfxManager.play("player_respawn")
	var energy_penalty: int = int(current_energy * ENERGY_DEATH_PENALTY)
	current_energy = max(current_energy - energy_penalty, 0)
	energy_changed.emit(current_energy, max_energy)
	_state_machine.travel("idle")
	_update_blend_position()
	_start_invincibility()

func _start_invincibility() -> void:
	is_invincible = true
	SfxManager.play("player_invincibility")
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_sprite, "modulate:a", 0.4, 0.15)
	_blink_tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	is_invincible = false
	if is_instance_valid(_blink_tween):
		_blink_tween.kill()
	_sprite.modulate = Color.WHITE

func _start_attack() -> void:
	if _current_weapon == null:
		return
	match _current_weapon.weapon_id:
		"thorn_sword", "blazeblade":
			_attack_melee_sword()
		"vine_whip", "crystal_lash":
			_attack_vine_whip()
		"spore_bomb", "void_grenade":
			_attack_spore_bomb()
		"petal_shield", "iron_bloom_shield":
			_attack_petal_shield()
		_:
			push_warning("[Player] Unknown weapon_id: %s" % _current_weapon.weapon_id)


func _attack_melee_sword() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	_hit_bodies.clear()
	_state_machine.travel("attack")
	_update_blend_position()
	var hitbox_offset: Vector2
	if last_direction == Vector2.DOWN:
		hitbox_offset = Vector2(0, -4)
	elif last_direction == Vector2.UP:
		hitbox_offset = Vector2(0, -36)
	elif last_direction == Vector2.LEFT:
		hitbox_offset = Vector2(-16, -24)
	else:
		hitbox_offset = Vector2(16, -24)
	_sword_hitbox.position = hitbox_offset
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	print("DEBUG: Attack! Damage: %d, Direction: %s" % [_current_weapon.damage, last_direction])
	var _swing_sfx: String = "blazeblade_swing" if _current_weapon.weapon_id == "blazeblade" else "thorn_sword_swing"
	SfxManager.play(_swing_sfx)
	var effective_cd: float = _current_weapon.cooldown * (1.0 - attack_speed_bonus)
	await get_tree().create_timer(effective_cd * 0.25).timeout
	if is_dead:
		is_attacking = false
		return
	hitbox_shape.disabled = false
	await get_tree().create_timer(effective_cd * 0.5).timeout
	hitbox_shape.disabled = true
	if is_dead:
		is_attacking = false
		return
	await get_tree().create_timer(effective_cd * 0.25).timeout
	_end_attack()


func _attack_vine_whip() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	_hit_bodies.clear()
	_state_machine.travel("attack")
	_update_blend_position()
	var hitbox_offset: Vector2
	if last_direction == Vector2.DOWN:
		hitbox_offset = Vector2(0, -4)
	elif last_direction == Vector2.UP:
		hitbox_offset = Vector2(0, -36)
	elif last_direction == Vector2.LEFT:
		hitbox_offset = Vector2(-16, -24)
	else:
		hitbox_offset = Vector2(16, -24)
	_sword_hitbox.position = hitbox_offset
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	print("DEBUG: Vine Whip! Damage: %d, Range: %.0f, Direction: %s" % [
		_current_weapon.damage + bonus_melee_damage, _current_weapon.attack_range, last_direction])
	var _whip_sfx: String = "crystal_lash_crack" if _current_weapon.weapon_id == "crystal_lash" else "vine_whip_crack"
	SfxManager.play(_whip_sfx, 0.05)
	var effective_cd: float = _current_weapon.cooldown * (1.0 - attack_speed_bonus)
	await get_tree().create_timer(effective_cd * 0.25).timeout
	if is_dead:
		is_attacking = false
		return
	hitbox_shape.disabled = false
	await get_tree().create_timer(effective_cd * 0.5).timeout
	hitbox_shape.disabled = true
	if is_dead:
		is_attacking = false
		return
	await get_tree().create_timer(effective_cd * 0.25).timeout
	_end_attack()


func _attack_spore_bomb() -> void:
	is_attacking = true
	_state_machine.travel("attack")
	SfxManager.play("spore_bomb_throw")
	var target: Vector2 = get_global_mouse_position()
	var dir: Vector2 = target - global_position
	if dir.length() > _current_weapon.attack_range:
		target = global_position + dir.normalized() * _current_weapon.attack_range
	var proj: SporeBombProjectile = preload(
		"res://combat/projectiles/spore_bomb_projectile.tscn").instantiate()
	proj.damage = _current_weapon.damage
	proj.aoe_radius = _current_weapon.attack_range * 0.4
	proj.launch(global_position, target)
	var proj_parent: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	if proj_parent == null:
		proj_parent = get_tree().current_scene
	proj_parent.add_child(proj)
	print("DEBUG: Spore Bomb launched! Damage: %d, AoE: %.0f, Target: %s" % [
		_current_weapon.damage, _current_weapon.attack_range * 0.4, target])
	await get_tree().create_timer(0.2).timeout
	is_attacking = false
	if is_dead:
		return
	_attack_cooldown_timer = _current_weapon.cooldown * (1.0 - attack_speed_bonus)
	_state_machine.travel("idle")


func _attack_petal_shield() -> void:
	# Petal Shield damage = counter damage, attack_range = counter radius, cooldown = post-counter cooldown.
	if is_blocking:
		_drop_block()
	else:
		_raise_block()


func _raise_block() -> void:
	is_blocking = true
	_block_raised_time = Time.get_ticks_msec() / 1000.0
	_saved_damage_reduction = damage_reduction
	damage_reduction = max(damage_reduction, PETAL_SHIELD_DR)
	_sprite.modulate = Color(0.8, 0.9, 1.0)
	var _raise_sfx: String = "iron_bloom_shield_raise" if _current_weapon.weapon_id == "iron_bloom_shield" else "petal_shield_raise"
	SfxManager.play(_raise_sfx)
	print("[Player] Block raised (%s)" % _current_weapon.weapon_id)


func _drop_block() -> void:
	is_blocking = false
	_block_raised_time = -1.0
	damage_reduction = _saved_damage_reduction
	_sprite.modulate = Color.WHITE
	print("[Player] Block dropped")


func _trigger_petal_counter() -> void:
	SfxManager.play("petal_shield_counter")
	var radius: float = _current_weapon.attack_range
	var dmg: int = _current_weapon.damage
	for body in get_tree().get_nodes_in_group(&"enemies"):
		if body is EnemyBase and not body.is_dead:
			if global_position.distance_to(body.global_position) <= radius:
				body.take_damage(dmg)
				if body.has_method("apply_stun"):
					body.apply_stun(PETAL_SHIELD_COUNTER_STUN)
				add_energy(ENERGY_PER_HIT)
	_spawn_counter_vfx(radius)
	print("[Player] Petal Shield counter! Radius: %.0f, Dmg: %d" % [radius, dmg])


func _spawn_counter_vfx(radius: float) -> void:
	# TODO (VFX-05): Replace with real counter-attack particle ring.
	var ring: ColorRect = ColorRect.new()
	ring.color = Color(0.8, 0.9, 1.0, 0.6)
	var size: float = radius * 2.0
	ring.size = Vector2(size, size)
	ring.position = -Vector2(size * 0.5, size * 0.5)
	add_child(ring)
	var tween: Tween = create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ring.queue_free)


func _end_attack() -> void:
	is_attacking = false
	if is_dead:
		return
	_attack_cooldown_timer = _current_weapon.cooldown * (1.0 - attack_speed_bonus)
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	hitbox_shape.disabled = true
	_state_machine.travel("idle")

func _on_weapon_crafted(weapon_id: String) -> void:
	if DayNightCycle.is_night():
		print("[Player] Loadout locked at night — cannot auto-equip %s." % weapon_id)
		return
	var empty_slot: int = -1
	for i: int in range(WEAPON_SLOT_COUNT):
		if weapon_slots[i].is_empty():
			empty_slot = i
			break
	var target_slot: int = empty_slot if empty_slot >= 0 else 0
	equip_weapon(target_slot, weapon_id)
	print("[Player] Crafted weapon '%s' auto-equipped to slot %d." % [weapon_id, target_slot])


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
		var energy_before: int = current_energy
		add_energy(amount)
		if current_energy > energy_before:
			SfxManager.play_at("core_energy_tick", GameManager.dianthus_core.global_position)


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


func select_weapon_slot(index: int) -> void:
	if index < 0 or index >= WEAPON_SLOT_COUNT:
		return
	if is_blocking:
		_drop_block()
	selected_weapon_slot = index
	var wid: String = weapon_slots[selected_weapon_slot]
	if wid.is_empty():
		_current_weapon = null
	else:
		_current_weapon = CraftingManager.get_weapon_data(wid)
	SfxManager.play("weapon_equipped")
	loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)
	print("[Player] Selected weapon slot %d: %s" % [index, wid if not wid.is_empty() else "[Empty]"])


func equip_weapon(slot: int, weapon_id: String) -> void:
	if DayNightCycle.is_night():
		print("[Player] Loadout locked! Cannot equip during Night.")
		loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)
		return
	if slot < 0 or slot >= WEAPON_SLOT_COUNT:
		return
	weapon_slots[slot] = weapon_id
	if slot == selected_weapon_slot:
		if weapon_id.is_empty():
			_current_weapon = null
		else:
			_current_weapon = CraftingManager.get_weapon_data(weapon_id)
	loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)


func set_active_skill(skill_id: String) -> void:
	if DayNightCycle.is_night():
		print("[Player] Loadout locked! Cannot change skill during Night.")
		loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)
		return
	active_skill_id = skill_id
	loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)


func _activate_skill() -> void:
	if active_skill_id.is_empty():
		print("[Player] No active skill equipped.")
		return
	if not try_spend_energy(SKILL_ENERGY_COST):
		print("[Player] Not enough energy for skill. Need %d, have %d." % [SKILL_ENERGY_COST, current_energy])
		return
	print("[Player] Activated skill: %s (-%d energy)" % [active_skill_id, SKILL_ENERGY_COST])
	# TODO (PLANT-09): Spore Bomb skill behavior.
	# TODO (PLANT-10): Vine Whip skill behavior.
	# TODO (PLANT-11): Petal Shield skill behavior.


func _debug_place_plant() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var scene_paths: Array[String] = [
		"res://plants/entities/bougainvillea.tscn",
		"res://plants/entities/rafflesia.tscn",
		"res://plants/entities/melati.tscn",
		"res://plants/entities/wijaya_kusuma.tscn",
		"res://plants/entities/beringin.tscn",
		"res://plants/entities/kecombrang.tscn",
		"res://plants/entities/kunyit.tscn",
		"res://plants/entities/bunga_api.tscn",
		"res://plants/entities/bunga_bayang.tscn",
		"res://plants/entities/melati_emas.tscn",
		"res://plants/entities/baja_kuning.tscn",
	]
	var labels: Array[String] = [
		"Bougainvillea", "Rafflesia", "Melati", "Wijaya Kusuma", "Beringin",
		"Kecombrang", "Kunyit", "Bunga Api", "Bunga Bayang", "Melati Emas", "Baja Kuning",
	]
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
	_debug_plant_cycle = (_debug_plant_cycle + 1) % 12


func _debug_spawn_enemy() -> void:
	var scene_path: String = DEBUG_ENEMY_SCENES[_debug_enemy_index]
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_warning("DEBUG: Could not load enemy scene: %s" % scene_path)
		return
	var e: EnemyBase = scene.instantiate() as EnemyBase
	var spawn_pos: Vector2 = global_position + Vector2(100, 0)
	if get_viewport() != null:
		var mouse_world: Vector2 = get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		spawn_pos = mouse_world
	e.global_position = spawn_pos
	var ysort: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	if ysort != null:
		ysort.add_child(e)
	else:
		get_tree().current_scene.add_child(e)
	if e.has_method("activate"):
		e.activate()
	print("[Debug] Spawned %s at %s" % [scene_path.get_file().get_basename(), spawn_pos])
	_debug_enemy_index = (_debug_enemy_index + 1) % DEBUG_ENEMY_SCENES.size()


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	var total_damage: int = _current_weapon.damage + bonus_melee_damage
	if body.has_method("take_damage"):
		body.take_damage(total_damage)
	attack_hit.emit(body, total_damage)
	print("DEBUG: Hit %s for %d damage" % [body.name, total_damage])
	add_energy(ENERGY_PER_HIT)
	var _hit_sfx: String = "blazeblade_hit" if (_current_weapon != null and _current_weapon.weapon_id == "blazeblade") else "thorn_sword_hit"
	SfxManager.play_at(_hit_sfx, body.global_position, 0.05)
	if _current_weapon != null and (_current_weapon.weapon_id == "vine_whip" or _current_weapon.weapon_id == "crystal_lash"):
		SfxManager.play_at("vine_whip_pull", body.global_position)
		if body.has_method("apply_pull"):
			body.apply_pull(global_position, 0.25, 24.0)
	# TODO (VFX-05): Add impact particles on hit.
