extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
signal attack_hit(target: Node, damage: int)
signal energy_changed(current_energy: int, max_energy: int)
signal loadout_changed(weapon_slots: Array, skill_id: String, selected_slot: int)
signal status_effect_added(effect: Dictionary)
signal status_effect_updated(effect: Dictionary)
signal status_effect_removed(effect_id: String)
signal status_effect_expired(effect_id: String)

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
const CORE_ENERGY_TICK_INTERVAL: float = 1.2
const WEAPON_SLOT_COUNT: int = 2
const SKILL_ENERGY_COST: int = 30

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_tree: AnimationTree = %AnimationTree
@onready var _camera: Camera2D = %Camera2D
@onready var _sword_hitbox: Area2D = %SwordHitbox
@onready var _weapon_vfx_anchor: Node2D = %WeaponVfxAnchor

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
var _force_next_quality: int = -1
var _ability_manager: AbilityManager = null

const DEBUG_ENEMY_SCENES: Array[String] = [
	"res://enemies/shadowling/shadowling.tscn",
	"res://enemies/voidrunner/voidrunner.tscn",
	"res://enemies/stonehusk/stonehusk.tscn",
	"res://enemies/phantom_weaver/phantom_weaver.tscn",
	"res://enemies/swarm_larva/swarm_larva.tscn",
]
var current_energy: int = 0
var max_energy: int = BASE_MAX_ENERGY
var _energy_regen_accumulator: float = 0.0
var _core_energy_tick_active: bool = false
var _core_energy_tick_timer: Timer = null
var damage_reduction: float = 0.0
var attack_speed_bonus: float = 0.0
var bonus_melee_damage: int = 0
var environment_speed_modifier: float = 1.0
var _status_effect_sources: Dictionary = {}
var _status_effect_snapshots: Dictionary = {}

const PETAL_SHIELD_DR: float = 0.8
const PETAL_SHIELD_PERFECT_WINDOW: float = 0.2
const PETAL_SHIELD_COUNTER_STUN: float = 0.6
const SPORE_BOMB_RELEASE_TIME: float = 0.08
const SPORE_BOMB_ATTACK_TIME: float = 0.2
const SPORE_BOMB_PROJECTILE_SCENE: PackedScene = preload("res://combat/projectiles/spore_bomb_projectile.tscn")
const VOID_GRENADE_PROJECTILE_SCENE: PackedScene = preload("res://combat/projectiles/void_grenade_projectile.tscn")
const WEAPON_VFX_BURST_SCENE: PackedScene = preload("res://vfx/weapon_vfx/weapon_vfx_burst.tscn")
const WEAPON_VFX_LIBRARY = preload("res://vfx/weapon_vfx/weapon_vfx_library.gd")
const WEAPON_VFX_VISUAL_OFFSET: Vector2 = Vector2(0, -28)
const WEAPON_VFX_VISUAL_SCALE: Vector2 = Vector2(0.5, 0.5)
const IMPACT_VFX_VISUAL_SCALE: Vector2 = Vector2(0.75, 0.75)

var is_blocking: bool = false
var _block_raised_time: float = -1.0
var _saved_damage_reduction: float = 0.0
var is_harvesting: bool = false

func _ready() -> void:
	add_to_group("player")
	PlayerAnimationBuilder.build(%AnimationPlayer, "Sprite2D")
	PlayerAnimationBuilder.build_tree(%AnimationTree)
	_anim_tree.active = true
	_state_machine = _anim_tree["parameters/playback"]
	_update_blend_position()
	hp_changed.emit(current_hp, MAX_HP)
	energy_changed.emit(current_energy, max_energy)
	if not weapon_slots[0].is_empty():
		_current_weapon = CraftingManager.get_weapon_data(weapon_slots[0])
		_refresh_weapon_pose(true)
	_sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	CraftingManager.weapon_crafted.connect(_on_weapon_crafted)
	_setup_core_energy_tick_timer()
	_ability_manager = AbilityManager.new()
	add_child(_ability_manager)
	loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)


func _exit_tree() -> void:
	_stop_core_energy_tick_loop()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_cooldown_timer = max(_attack_cooldown_timer - delta, 0.0)
	if is_attacking or is_harvesting:
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
		velocity = dir * SPEED * environment_speed_modifier
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

func _animation_prefix_for_state(state: String) -> String:
	if _current_weapon == null:
		return ""
	match _current_weapon.weapon_id:
		"thorn_sword":
			return "thornsword_"
		"blazeblade":
			return "blazeblade_"
		"spore_bomb":
			if state in ["idle", "walk", "attack"]:
				return "spore_bomb_"
		"void_grenade":
			if state in ["idle", "walk", "attack"]:
				return "void_grenade_"
		"vine_whip":
			if state in ["idle", "walk", "attack"]:
				return "vine_whip_"
		"crystal_lash":
			if state in ["idle", "walk", "attack"]:
				return "crystal_lash_"
		"petal_shield":
			if state in ["idle", "walk"]:
				return "petal_shield_"
		"iron_bloom_shield":
			if state in ["idle", "walk"]:
				return "iron_bloom_shield_"
	return ""

func _shield_animation_state(state: String) -> String:
	if _current_weapon != null and _current_weapon.weapon_id == "iron_bloom_shield":
		return "iron_bloom_shield_%s" % state
	return "petal_shield_%s" % state

func _travel(state: String, force: bool = false) -> void:
	var prefix: String = _animation_prefix_for_state(state)
	var target_state: StringName = StringName(prefix + state)
	var root: AnimationNodeStateMachine = _anim_tree.tree_root as AnimationNodeStateMachine
	if root != null and not root.has_node(target_state):
		target_state = StringName(state)

	var current: StringName = _state_machine.get_current_node()
	if current == target_state:
		return
	if not force:
		if current == &"hurt" or current == &"death" or current == &"attack" or current == &"thornsword_attack" or current == &"blazeblade_attack" or current == &"vine_whip_attack" or current == &"crystal_lash_attack" or current == &"spore_bomb_attack" or current == &"void_grenade_attack" or current == &"petal_shield_block" or current == &"petal_shield_counter" or current == &"iron_bloom_shield_block" or current == &"iron_bloom_shield_counter" or current == &"dash":
			return
	_state_machine.travel(target_state)


func _refresh_weapon_pose(force: bool = false) -> void:
	if _state_machine == null or is_dead or is_attacking or is_harvesting or is_blocking:
		return
	var movement_state: String = "walk" if velocity.length_squared() > 0.0 else "idle"
	_travel(movement_state, force)
	_update_blend_position()

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
	var root: AnimationNodeStateMachine = _anim_tree.tree_root as AnimationNodeStateMachine
	if root == null:
		return
	if root.has_node(&"idle"):
		_anim_tree["parameters/idle/blend_position"] = blend
	if root.has_node(&"walk"):
		_anim_tree["parameters/walk/blend_position"] = blend
	if root.has_node(&"run"):
		_anim_tree["parameters/run/blend_position"] = blend
	if root.has_node(&"hurt"):
		_anim_tree["parameters/hurt/blend_position"] = blend
	if root.has_node(&"death"):
		_anim_tree["parameters/death/blend_position"] = blend
	if root.has_node(&"attack"):
		_anim_tree["parameters/attack/blend_position"] = blend
	if root.has_node(&"thornsword_idle"):
		_anim_tree["parameters/thornsword_idle/blend_position"] = blend
	if root.has_node(&"thornsword_walk"):
		_anim_tree["parameters/thornsword_walk/blend_position"] = blend
	if root.has_node(&"thornsword_attack"):
		_anim_tree["parameters/thornsword_attack/blend_position"] = blend
	if root.has_node(&"blazeblade_idle"):
		_anim_tree["parameters/blazeblade_idle/blend_position"] = blend
	if root.has_node(&"blazeblade_walk"):
		_anim_tree["parameters/blazeblade_walk/blend_position"] = blend
	if root.has_node(&"blazeblade_attack"):
		_anim_tree["parameters/blazeblade_attack/blend_position"] = blend
	if root.has_node(&"spore_bomb_idle"):
		_anim_tree["parameters/spore_bomb_idle/blend_position"] = blend
	if root.has_node(&"spore_bomb_walk"):
		_anim_tree["parameters/spore_bomb_walk/blend_position"] = blend
	if root.has_node(&"void_grenade_idle"):
		_anim_tree["parameters/void_grenade_idle/blend_position"] = blend
	if root.has_node(&"void_grenade_walk"):
		_anim_tree["parameters/void_grenade_walk/blend_position"] = blend
	if root.has_node(&"void_grenade_attack"):
		_anim_tree["parameters/void_grenade_attack/blend_position"] = blend
	if root.has_node(&"vine_whip_attack"):
		_anim_tree["parameters/vine_whip_attack/blend_position"] = blend
	if root.has_node(&"vine_whip_idle"):
		_anim_tree["parameters/vine_whip_idle/blend_position"] = blend
	if root.has_node(&"vine_whip_walk"):
		_anim_tree["parameters/vine_whip_walk/blend_position"] = blend
	if root.has_node(&"crystal_lash_idle"):
		_anim_tree["parameters/crystal_lash_idle/blend_position"] = blend
	if root.has_node(&"crystal_lash_walk"):
		_anim_tree["parameters/crystal_lash_walk/blend_position"] = blend
	if root.has_node(&"crystal_lash_attack"):
		_anim_tree["parameters/crystal_lash_attack/blend_position"] = blend
	if root.has_node(&"petal_shield_idle"):
		_anim_tree["parameters/petal_shield_idle/blend_position"] = blend
	if root.has_node(&"petal_shield_walk"):
		_anim_tree["parameters/petal_shield_walk/blend_position"] = blend
	if root.has_node(&"iron_bloom_shield_idle"):
		_anim_tree["parameters/iron_bloom_shield_idle/blend_position"] = blend
	if root.has_node(&"iron_bloom_shield_walk"):
		_anim_tree["parameters/iron_bloom_shield_walk/blend_position"] = blend
	if root.has_node(&"spore_bomb_attack"):
		_anim_tree["parameters/spore_bomb_attack/blend_position"] = blend
	if root.has_node(&"petal_shield_block"):
		_anim_tree["parameters/petal_shield_block/blend_position"] = blend
	if root.has_node(&"petal_shield_counter"):
		_anim_tree["parameters/petal_shield_counter/blend_position"] = blend
	if root.has_node(&"iron_bloom_shield_block"):
		_anim_tree["parameters/iron_bloom_shield_block/blend_position"] = blend
	if root.has_node(&"iron_bloom_shield_counter"):
		_anim_tree["parameters/iron_bloom_shield_counter/blend_position"] = blend
	if root.has_node(&"dash"):
		_anim_tree["parameters/dash/blend_position"] = blend

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
		elif event.keycode == KEY_M:
			if event.ctrl_pressed:
				var mgScene: PackedScene = load("res://minigames/plant_experimentation/plant_experimentation_screen.tscn")
				if mgScene != null:
					var mg: Node = mgScene.instantiate()
					get_tree().root.add_child(mg)
					if mg.has_method("start_puzzle"):
						mg.start_puzzle("bunga_api", "bougainvillea_extract", "kecombrang_extract")
					if mg.has_signal("finished"):
						mg.finished.connect(func(q: int, s: bool) -> void: print("DEBUG Minigame result: tier=%d success=%s" % [q, s]))
					print("DEBUG: Ctrl+M forced Plant Experimentation Minigame for bunga_api.")
			elif event.shift_pressed:
				_force_next_quality += 1
				if _force_next_quality > 2:
					_force_next_quality = -1
				print("DEBUG: Shift+M set forced seed quality to: %s" % ("NONE" if _force_next_quality == -1 else str(_force_next_quality)))
		elif event.keycode == KEY_N:
			if event.ctrl_pressed:
				var craft_mg_scene: PackedScene = load("res://minigames/crafting_assembly/crafting_assembly_screen.tscn")
				if craft_mg_scene != null:
					var craft_mg: Node = craft_mg_scene.instantiate()
					get_tree().root.add_child(craft_mg)
					if craft_mg.has_method("start_assembly"):
						craft_mg.call("start_assembly", "thorn_sword")
					if craft_mg.has_signal("finished"):
						craft_mg.finished.connect(func(q: int, s: bool) -> void: print("DEBUG Crafting Assembly result: tier=%d success=%s" % [q, s]))
					print("DEBUG: Ctrl+N forced Crafting Assembly Minigame for thorn_sword.")
			elif event.shift_pressed:
				CraftingManager._force_next_quality = 0 if CraftingManager._force_next_quality != 0 else 1
				print("DEBUG: Shift+N set next crafted weapon quality to: %d" % CraftingManager._force_next_quality)
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
			if event.shift_pressed:
				get_tree().change_scene_to_file("res://core/cutscenes/opening_cutscene.tscn")
				print("DEBUG: Shift+F12 — Replaying opening cutscene.")
			else:
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
				InventoryManager.add_item("aether_bloom", 2)
				InventoryManager.add_item("stone", 10)
				print("DEBUG: Added crafting + plant seed + ability test materials (Shift+Insert).")
			else:
				InventoryManager.add_item("petal_shard", 5)
				InventoryManager.add_item("verdant_sap", 2)
				InventoryManager.add_item("moonspore", 1)
				InventoryManager.add_item("dianthus_pollen", 1)
				print("DEBUG: Added 5 Petal Shard, 2 Verdant Sap, 1 Moonspore to inventory.")
		if event.keycode == KEY_B and event.shift_pressed and not event.ctrl_pressed:
			UnlockFlags.set_flag(StoryEndingFlags.unlock_blackwater_hollow)
			print("[DEBUG] Shift+B — Blackwater Hollow unlocked")
		if event.keycode == KEY_B and event.ctrl_pressed and not event.shift_pressed:
			UnlockFlags.set_flag(StoryEndingFlags.unlock_core_sacred_bloom)
			print("[DEBUG] Ctrl+B — Core Sacred Bloom unlocked")
		if event.keycode == KEY_B and event.ctrl_pressed and event.shift_pressed:
			var core_nodes: Array[Node] = get_tree().get_nodes_in_group("dianthus_core")
			if not core_nodes.is_empty():
				core_nodes[0].set("_harvested_today", false)
				core_nodes[0].set("_last_harvest_day", -1)
				core_nodes[0].call("_refresh_prompt")
				print("[DEBUG] Ctrl+Shift+B — Core Sacred Bloom daily cooldown reset")
			else:
				push_warning("[DEBUG] Ctrl+Shift+B — DianthusCore not found in group 'dianthus_core'")
		if event.keycode == KEY_A and event.shift_pressed and not event.ctrl_pressed:
			CraftingManager.owned_abilities["dash"] = true
			CraftingManager.owned_abilities["heal_pulse"] = true
			CraftingManager.owned_abilities["thorn_burst"] = true
			print("DEBUG: Shift+A — granted all 3 abilities.")
			var ls_a: Node = get_tree().current_scene.find_child("LoadoutScreen", true, false)
			if ls_a != null and ls_a.has_method("_refresh"):
				ls_a._refresh()
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
		elif event.keycode == KEY_4 and event.shift_pressed and not event.ctrl_pressed:
			InventoryManager.add_item("petal_shard", 12)
			InventoryManager.add_item("verdant_sap", 8)
			InventoryManager.add_item("moonspore", 4)
			print("DEBUG: Shift+4 — Added fortification materials (12 Petal Shard, 8 Verdant Sap, 4 Moonspore).")
		elif event.keycode == KEY_5 and event.shift_pressed and not event.ctrl_pressed:
			ZoneTracker.enter_zone("dusk_forest")
			print("DEBUG: Shift+5 — Emitted zone_entered{zone_id=dusk_forest}.")
		elif event.keycode == KEY_6 and event.shift_pressed:
			QuestManager._on_devourer_omen_deciphered()
			print("DEBUG: Shift+6 — Emitted devourer_omen_deciphered.")
		elif event.keycode == KEY_7 and event.shift_pressed:
			QuestManager._on_devourer_defeated()
			print("DEBUG: Shift+7 — Emitted devourer_defeated.")
			print("DEBUG: flag_story_devourer_defeated == %s" % str(UnlockFlags.has_flag("flag_story_devourer_defeated")))
		elif event.keycode == KEY_9 and event.shift_pressed:
			DayNightCycle._phase_timer = 35.0
			print("DEBUG: Shift+9 — Set DAY timer to 35s remaining.")
		elif event.keycode == KEY_0 and event.shift_pressed:
			var _ev_types: Array[StringName] = [
				&"corrupted_root", &"wild_seedling", &"void_fissure", &"dianthus_resonance"
			]
			var ev_spawner: Node = get_tree().current_scene.find_child("DaytimeEventSpawner", true, false)
			if ev_spawner != null and ev_spawner.has_method("force_spawn_event"):
				if not ev_spawner.has_meta(&"_dbg_ev_idx"):
					ev_spawner.set_meta(&"_dbg_ev_idx", 0)
				var idx: int = int(ev_spawner.get_meta(&"_dbg_ev_idx"))
				ev_spawner.force_spawn_event(_ev_types[idx])
				print("DEBUG: Shift+0 — Force-spawned event: %s" % _ev_types[idx])
				ev_spawner.set_meta(&"_dbg_ev_idx", (idx + 1) % _ev_types.size())
			else:
				push_warning("DEBUG: DaytimeEventSpawner not found.")
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
		elif event.keycode == KEY_5 and event.ctrl_pressed and not event.shift_pressed:
			var spawner: WaveSpawner = get_tree().current_scene.find_child("WaveSpawner", true, false) as WaveSpawner
			if spawner != null:
				spawner._start_devourer_fight()
				print("DEBUG: Ctrl+5 — Force-started Devourer fight.")
			else:
				push_warning("DEBUG: Ctrl+5 — WaveSpawner not found.")
		elif event.keycode == KEY_6 and event.ctrl_pressed and not event.shift_pressed:
			var devourers: Array[Node] = get_tree().get_nodes_in_group(&"devourer")
			if devourers.is_empty():
				print("DEBUG: Ctrl+6 — No active Devourer found.")
			else:
				var devourer: TheDevourer = devourers[0] as TheDevourer
				if devourer != null:
					var next_phase: int = devourer.get_current_phase() + 1
					if next_phase > 3:
						next_phase = 1
					var fsm: Node = devourer.get_node_or_null("StateMachine")
					if fsm != null and fsm.has_method("transition_to"):
						fsm.transition_to(StringName("Phase%d" % next_phase))
						devourer.set("_current_phase", next_phase)
					print("DEBUG: Ctrl+6 — Devourer forced to Phase %d." % next_phase)
		elif event.keycode == KEY_0 and event.ctrl_pressed and not event.shift_pressed:
			var struct_mgr: Node = get_tree().current_scene.find_child("GardenStructureManager", true, false)
			if struct_mgr != null and struct_mgr.has_method("build_watchtower"):
				InventoryManager.add_item("stone", 20)
				InventoryManager.add_item("verdant_sap", 10)
				DayNightCycle.day_count = max(DayNightCycle.day_count, 5)
				struct_mgr.call("build_watchtower")
				print("DEBUG: Ctrl+0 — Watchtower force built.")
			else:
				push_warning("DEBUG: Ctrl+0 — GardenStructureManager not found.")
		elif event.keycode == KEY_9 and event.ctrl_pressed and not event.shift_pressed:
			var struct_mgr: Node = get_tree().current_scene.find_child("GardenStructureManager", true, false)
			if struct_mgr != null and struct_mgr.has_method("build_storage"):
				InventoryManager.add_item("stone", 20)
				InventoryManager.add_item("verdant_sap", 10)
				DayNightCycle.day_count = max(DayNightCycle.day_count, 3)
				struct_mgr.call("build_storage")
				print("DEBUG: Ctrl+9 — Storage Shed force built, tier now %d." % int(struct_mgr.get("storage_tier")))
			else:
				push_warning("DEBUG: Ctrl+9 — GardenStructureManager not found.")
		elif event.keycode == KEY_8 and event.ctrl_pressed and not event.shift_pressed:
			var ppm: Node = get_tree().current_scene.find_child("PlantPlacementManager", true, false)
			if ppm != null and ppm.has_method("expand_garden"):
				var old_tier: int = int(ppm.get("expansion_tier"))
				if ppm.has_method("can_expand") and not ppm.call("can_expand"):
					ppm.set("expansion_tier", old_tier)
					InventoryManager.add_item("verdant_sap", 20)
					InventoryManager.add_item("stone", 30)
					print("DEBUG: Ctrl+8 — Added materials and retrying expand.")
					DayNightCycle.day_count = max(DayNightCycle.day_count, 12)
				ppm.call("expand_garden")
				print("DEBUG: Ctrl+8 — Garden tier now %d." % int(ppm.get("expansion_tier")))
			else:
				push_warning("DEBUG: Ctrl+8 — PlantPlacementManager not found.")
		elif event.keycode == KEY_7 and event.ctrl_pressed and not event.shift_pressed:
			var devourers: Array[Node] = get_tree().get_nodes_in_group(&"devourer")
			if devourers.is_empty():
				print("DEBUG: Ctrl+7 — No active Devourer found.")
			else:
				var devourer: TheDevourer = devourers[0] as TheDevourer
				if devourer != null:
					var summoned: Array = devourer.get("_summoned_minions")
					var killed: int = 0
					for minion in summoned:
						if is_instance_valid(minion) and not minion.is_dead:
							minion.die()
							killed += 1
					print("DEBUG: Ctrl+7 — Killed %d summoned Devourer minions." % killed)
		elif event.keycode == KEY_5 and event.ctrl_pressed and event.shift_pressed:
			QuestManager.start_quest(&"story_01_whispers")
			print("DEBUG: Ctrl+Shift+5 — Force-started story_01_whispers.")
		elif event.keycode == KEY_F and event.shift_pressed and not event.ctrl_pressed:
			set_active_skill("dash")
			print("DEBUG: Shift+F — Equipped 'dash' skill. Press F to activate (costs 20 energy).")
		elif event.keycode == KEY_G and event.shift_pressed and not event.ctrl_pressed:
			set_active_skill("thorn_burst")
			print("DEBUG: Shift+G — Equipped 'thorn_burst' skill. Press F to activate (costs 35 energy).")
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

func set_harvesting(value: bool) -> void:
	is_harvesting = value
	if not value:
		_travel("idle")


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
	_state_machine.travel(&"hurt")
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
	environment_speed_modifier = 1.0
	damage_reduction = 0.0
	attack_speed_bonus = 0.0
	bonus_melee_damage = 0
	clear_status_effects()
	if is_harvesting:
		is_harvesting = false
	if is_blocking:
		_drop_block()
	_stop_core_energy_tick_loop()
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
	_travel("idle", true)
	_update_blend_position()
	_start_invincibility()

func _start_invincibility() -> void:
	is_invincible = true
	SfxManager.play("player_invincibility")
	var _inv_tint: Color = Color(0.7, 1.0, 0.75)
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_sprite, "modulate", _inv_tint * Color(1, 1, 1, 0.4), 0.15)
	_blink_tween.tween_property(_sprite, "modulate", _inv_tint, 0.15)
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


func _play_weapon_attack_vfx(weapon_id: String, direction: Vector2) -> void:
	var frames: SpriteFrames = WEAPON_VFX_LIBRARY.get_attack_frames(weapon_id)
	var animation_name: StringName = WEAPON_VFX_LIBRARY.direction_animation(direction)
	_spawn_local_weapon_vfx(frames, animation_name)


func _play_weapon_shield_vfx(weapon_id: String, direction: Vector2, phase: String) -> void:
	var frames: SpriteFrames = WEAPON_VFX_LIBRARY.get_shield_frames(weapon_id)
	var animation_name: StringName = WEAPON_VFX_LIBRARY.shield_animation(phase, direction)
	_spawn_local_weapon_vfx(frames, animation_name)


func _spawn_local_weapon_vfx(frames: SpriteFrames, animation_name: StringName) -> void:
	if frames == null or _weapon_vfx_anchor == null:
		return
	var burst = WEAPON_VFX_BURST_SCENE.instantiate()
	_weapon_vfx_anchor.add_child(burst)
	burst.play(frames, animation_name, WEAPON_VFX_VISUAL_OFFSET, WEAPON_VFX_VISUAL_SCALE)


func _spawn_weapon_impact_vfx(weapon_id: String, world_position: Vector2) -> void:
	var frames: SpriteFrames = WEAPON_VFX_LIBRARY.get_impact_frames(weapon_id)
	if frames == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = self
	var burst = WEAPON_VFX_BURST_SCENE.instantiate()
	parent.add_child(burst)
	burst.global_position = world_position
	burst.play(frames, &"burst", Vector2.ZERO, IMPACT_VFX_VISUAL_SCALE)


func _attack_melee_sword() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	_hit_bodies.clear()
	var atk_state: String = "blazeblade_attack" if _current_weapon.weapon_id == "blazeblade" else "thornsword_attack"
	_travel(atk_state, true)
	_update_blend_position()
	_play_weapon_attack_vfx(_current_weapon.weapon_id, last_direction)
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
	print("DEBUG: Attack! Damage: %d, Direction: %s" % [_get_weapon_damage(_current_weapon, bonus_melee_damage), last_direction])
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
	var atk_state: String = "crystal_lash_attack" if _current_weapon.weapon_id == "crystal_lash" else "vine_whip_attack"
	_travel(atk_state, true)
	_update_blend_position()
	_play_weapon_attack_vfx(_current_weapon.weapon_id, last_direction)
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
		_get_weapon_damage(_current_weapon, bonus_melee_damage), _current_weapon.attack_range, last_direction])
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
	var attack_weapon: WeaponData = _current_weapon
	_travel("attack", true)
	_update_blend_position()
	_play_weapon_attack_vfx(attack_weapon.weapon_id, last_direction)
	await get_tree().create_timer(SPORE_BOMB_RELEASE_TIME).timeout
	if is_dead or attack_weapon == null:
		is_attacking = false
		return
	SfxManager.play("spore_bomb_throw")
	var target: Vector2 = get_global_mouse_position()
	var dir: Vector2 = target - global_position
	if dir.length() > attack_weapon.attack_range:
		target = global_position + dir.normalized() * attack_weapon.attack_range
	var projectile_scene: PackedScene = (
		VOID_GRENADE_PROJECTILE_SCENE
		if attack_weapon.weapon_id == "void_grenade"
		else SPORE_BOMB_PROJECTILE_SCENE
	)
	var proj: SporeBombProjectile = projectile_scene.instantiate()
	proj.weapon_id = attack_weapon.weapon_id
	proj.damage = _get_weapon_damage(attack_weapon)
	proj.aoe_radius = attack_weapon.attack_range * 0.4
	proj.launch(global_position, target)
	var proj_parent: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	if proj_parent == null:
		proj_parent = get_tree().current_scene
	proj_parent.add_child(proj)
	print("DEBUG: Spore Bomb launched! Damage: %d, AoE: %.0f, Target: %s" % [
		proj.damage, attack_weapon.attack_range * 0.4, target])
	await get_tree().create_timer(SPORE_BOMB_ATTACK_TIME - SPORE_BOMB_RELEASE_TIME).timeout
	is_attacking = false
	if is_dead:
		return
	_attack_cooldown_timer = attack_weapon.cooldown * (1.0 - attack_speed_bonus)
	_travel("idle", true)


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
	_travel(_shield_animation_state("block"), true)
	_update_blend_position()
	_play_weapon_shield_vfx(_current_weapon.weapon_id, last_direction, "block")
	_sprite.modulate = Color(0.8, 0.9, 1.0)
	var _raise_sfx: String = "iron_bloom_shield_raise" if _current_weapon.weapon_id == "iron_bloom_shield" else "petal_shield_raise"
	SfxManager.play(_raise_sfx)
	print("[Player] Block raised (%s)" % _current_weapon.weapon_id)


func _drop_block() -> void:
	is_blocking = false
	_block_raised_time = -1.0
	damage_reduction = _saved_damage_reduction
	_sprite.modulate = Color.WHITE
	_travel("idle", true)
	print("[Player] Block dropped")


func _trigger_petal_counter() -> void:
	_travel(_shield_animation_state("counter"), true)
	_update_blend_position()
	SfxManager.play("petal_shield_counter")
	var radius: float = _current_weapon.attack_range
	var dmg: int = _get_weapon_damage(_current_weapon)
	for body in get_tree().get_nodes_in_group(&"enemies"):
		if body is EnemyBase and not body.is_dead:
			if global_position.distance_to(body.global_position) <= radius:
				body.take_damage(dmg)
				if body.has_method("apply_stun"):
					body.apply_stun(PETAL_SHIELD_COUNTER_STUN)
				add_energy(ENERGY_PER_HIT)
	_spawn_counter_vfx(radius)
	print("[Player] Petal Shield counter! Radius: %.0f, Dmg: %d" % [radius, dmg])


func _spawn_counter_vfx(_radius: float) -> void:
	if _current_weapon == null:
		return
	_play_weapon_shield_vfx(_current_weapon.weapon_id, last_direction, "counter")


func _end_attack() -> void:
	is_attacking = false
	if is_dead:
		return
	if _current_weapon == null:
		return
	_attack_cooldown_timer = _current_weapon.cooldown * (1.0 - attack_speed_bonus)
	var hitbox_shape: CollisionShape2D = _sword_hitbox.get_child(0)
	hitbox_shape.disabled = true
	_travel("idle", true)


func play_dash_animation() -> void:
	_state_machine.travel(&"dash")
	_update_blend_position()


func _on_weapon_crafted(weapon_id: String, _quality_tier: int = 0) -> void:
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
		_stop_core_energy_tick_loop()
		return
	if not is_instance_valid(GameManager.dianthus_core):
		_stop_core_energy_tick_loop()
		return
	var dist: float = global_position.distance_to(
		GameManager.dianthus_core.global_position)
	if dist > CORE_PROXIMITY_RADIUS:
		_energy_regen_accumulator = 0.0
		_stop_core_energy_tick_loop()
		return
	_play_core_energy_tick_loop()
	_energy_regen_accumulator += ENERGY_NEAR_CORE_RATE * delta
	if _energy_regen_accumulator >= 1.0:
		var amount: int = int(_energy_regen_accumulator)
		_energy_regen_accumulator -= float(amount)
		add_energy(amount)


func _play_core_energy_tick_loop() -> void:
	if _core_energy_tick_active:
		return
	_core_energy_tick_active = true
	_play_core_energy_tick()
	if _core_energy_tick_timer != null:
		_core_energy_tick_timer.start()


func _stop_core_energy_tick_loop() -> void:
	if not _core_energy_tick_active:
		return
	_core_energy_tick_active = false
	if _core_energy_tick_timer != null:
		_core_energy_tick_timer.stop()


func _setup_core_energy_tick_timer() -> void:
	_core_energy_tick_timer = Timer.new()
	_core_energy_tick_timer.wait_time = CORE_ENERGY_TICK_INTERVAL
	_core_energy_tick_timer.one_shot = false
	_core_energy_tick_timer.timeout.connect(_on_core_energy_tick_timer_timeout)
	add_child(_core_energy_tick_timer)


func _on_core_energy_tick_timer_timeout() -> void:
	if not _core_energy_tick_active:
		return
	_play_core_energy_tick()


func _play_core_energy_tick() -> void:
	if not is_instance_valid(GameManager.dianthus_core):
		_stop_core_energy_tick_loop()
		return
	SfxManager.play_at("core_energy_tick", GameManager.dianthus_core.global_position)


func add_energy(amount: int) -> void:
	if is_dead:
		return
	current_energy = min(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)


func report_status_effect_source(effect_id: String, source_id: String, effect_data: Dictionary) -> void:
	if effect_id.is_empty() or source_id.is_empty():
		return
	var sources: Dictionary = _status_effect_sources.get(effect_id, {})
	sources[source_id] = effect_data.duplicate(true)
	_status_effect_sources[effect_id] = sources
	_emit_status_effect_snapshot(effect_id)


func remove_status_effect_source(effect_id: String, source_id: String) -> void:
	if effect_id.is_empty() or source_id.is_empty():
		return
	if not _status_effect_sources.has(effect_id):
		return
	var sources: Dictionary = _status_effect_sources[effect_id]
	sources.erase(source_id)
	if sources.is_empty():
		_status_effect_sources.erase(effect_id)
		_status_effect_snapshots.erase(effect_id)
		status_effect_removed.emit(effect_id)
		return
	_status_effect_sources[effect_id] = sources
	_emit_status_effect_snapshot(effect_id)


func clear_status_effects() -> void:
	var effect_ids: Array = _status_effect_sources.keys()
	_status_effect_sources.clear()
	_status_effect_snapshots.clear()
	for effect_id: Variant in effect_ids:
		status_effect_expired.emit(str(effect_id))
		status_effect_removed.emit(str(effect_id))


func get_active_status_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for effect_id: String in _status_effect_snapshots:
		effects.append((_status_effect_snapshots[effect_id] as Dictionary).duplicate(true))
	return effects


func _emit_status_effect_snapshot(effect_id: String) -> void:
	var effect: Dictionary = _build_status_effect_snapshot(effect_id)
	if effect.is_empty():
		return
	var existed: bool = _status_effect_snapshots.has(effect_id)
	_status_effect_snapshots[effect_id] = effect
	if existed:
		status_effect_updated.emit(effect)
	else:
		status_effect_added.emit(effect)


func _build_status_effect_snapshot(effect_id: String) -> Dictionary:
	var sources: Dictionary = _status_effect_sources.get(effect_id, {})
	if sources.is_empty():
		return {}
	var first: Dictionary = {}
	for source_data: Variant in sources.values():
		if source_data is Dictionary:
			first = (source_data as Dictionary)
			break
	if first.is_empty():
		return {}

	var aggregation: String = str(first.get("aggregation", "max"))
	var value: float = 0.0
	var initialized: bool = false
	for source_data: Variant in sources.values():
		if not source_data is Dictionary:
			continue
		var source_value: float = float((source_data as Dictionary).get("value", 0.0))
		match aggregation:
			"sum":
				value += source_value
				initialized = true
			_:
				if not initialized or source_value > value:
					value = source_value
					initialized = true

	var effect: Dictionary = first.duplicate(true)
	effect["id"] = effect_id
	effect["value"] = value
	effect["stack_count"] = sources.size()
	effect["duration"] = float(first.get("duration", -1.0))
	effect["remaining_time"] = float(first.get("remaining_time", -1.0))
	effect["strength_text"] = _format_status_effect_strength(effect, value)
	return effect


func _format_status_effect_strength(effect: Dictionary, value: float) -> String:
	var format: String = str(effect.get("value_format", ""))
	if format.is_empty():
		return ""
	match format:
		"percent":
			return "+%d%%" % int(round(value * 100.0))
		"flat":
			return "+%d" % int(round(value))
		"per_second":
			return "+%s/s" % _format_compact_float(value)
		_:
			return str(effect.get("strength_text", ""))


func _format_compact_float(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.1f" % value


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
	_refresh_weapon_pose(true)
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
	_refresh_weapon_pose(true)


func set_active_skill(skill_id: String) -> void:
	if DayNightCycle.is_night():
		print("[Player] Loadout locked! Cannot change skill during Night.")
		loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)
		return
	active_skill_id = skill_id
	loadout_changed.emit(weapon_slots, active_skill_id, selected_weapon_slot)


func _activate_skill() -> void:
	if _ability_manager == null:
		return
	_ability_manager.try_activate(active_skill_id, self)


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
	var spawn_pos: Vector2 = global_position + Vector2(100, 0)
	if get_viewport() != null:
		var mouse_world: Vector2 = get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		spawn_pos = mouse_world
	var ysort: Node = get_tree().current_scene.get_node_or_null("YSortLayer")
	var container: Node = ysort if ysort != null else get_tree().current_scene
	var batch: int = 5 if scene_path.find("swarm_larva") >= 0 else 1
	for _b: int in batch:
		var e: EnemyBase = scene.instantiate() as EnemyBase
		var offset: Vector2 = Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)) if batch > 1 else Vector2.ZERO
		e.global_position = spawn_pos + offset
		container.add_child(e)
		if e.has_method("activate"):
			e.activate()
	var label: String = scene_path.get_file().get_basename()
	if batch > 1:
		label += " (x%d)" % batch
	print("[Debug] Spawned %s at %s" % [label, spawn_pos])
	_debug_enemy_index = (_debug_enemy_index + 1) % DEBUG_ENEMY_SCENES.size()


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	var total_damage: int = _get_weapon_damage(_current_weapon, bonus_melee_damage)
	if body.has_method("take_damage"):
		body.take_damage(total_damage)
	attack_hit.emit(body, total_damage)
	print("DEBUG: Hit %s for %d damage" % [body.name, total_damage])
	if body is EnemyBase:
		add_energy(ENERGY_PER_HIT)
	var _hit_sfx: String = "blazeblade_hit" if (_current_weapon != null and _current_weapon.weapon_id == "blazeblade") else "thorn_sword_hit"
	SfxManager.play_at(_hit_sfx, body.global_position, 0.05)
	if _current_weapon != null and (_current_weapon.weapon_id == "vine_whip" or _current_weapon.weapon_id == "crystal_lash"):
		SfxManager.play_at("vine_whip_pull", body.global_position)
		if body.has_method("apply_pull"):
			body.apply_pull(global_position, 0.25, 24.0)
	if _current_weapon != null:
		_spawn_weapon_impact_vfx(_current_weapon.weapon_id, body.global_position)


func _get_weapon_damage(weapon: WeaponData, flat_bonus: int = 0) -> int:
	if weapon == null:
		return 0
	var multiplier: float = CraftingManager.get_weapon_damage_multiplier(weapon.weapon_id)
	return int(roundf(float(weapon.damage + flat_bonus) * multiplier))
