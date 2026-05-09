@tool
class_name PlayerAnimationBuilder

const UNARMED_FRAME_SIZE: Vector2i = Vector2i(64, 80)
const WEAPON_FRAME_SIZE: Vector2i = Vector2i(80, 96)
const SPORE_BOMB_THROW_FRAME_SIZE: Vector2i = Vector2i(64, 64)

const DIR_DOWN: int = 0
const DIR_LEFT: int = 1
const DIR_RIGHT: int = 2
const DIR_UP: int = 3

const DIR_NAMES: PackedStringArray = ["down", "left", "right", "up"]

const ANIM_DEFS: Array[Dictionary] = [
	{
		"prefix": "idle",
		"sheet": "res://player/sprites/PNG/Unarmed_Idle/player_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 1.2,
	},
	{
		"prefix": "walk",
		"sheet": "res://player/sprites/PNG/Unarmed_Walk/player_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
	},
	{
		"prefix": "hurt",
		"sheet": "res://player/sprites/PNG/Unarmed_Hurt/Unarmed_Hurt_full.png",
		"columns": 5,
		"frames": [5, 5, 5, 5],
		"loop": false,
		"duration": 0.5,
	},
	{
		"prefix": "death",
		"sheet": "res://player/sprites/PNG/Unarmed_Death/player_death_full.png",
		"columns": 7,
		"frames": [7, 7, 7, 7],
		"loop": false,
		"duration": 0.7,
	},
	{
		"prefix": "thornsword_idle",
		"sheet": "res://player/sprites/PNG/Sword_Idle/thornsword_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "thornsword_walk",
		"sheet": "res://player/sprites/PNG/Sword_Walk/thornsword_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "blazeblade_idle",
		"sheet": "res://player/sprites/PNG/Blazeblade_Idle/blazeblade_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "blazeblade_walk",
		"sheet": "res://player/sprites/PNG/Blazeblade_Walk/blazeblade_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "spore_bomb_idle",
		"sheet": "res://player/sprites/PNG/SporeBomb_Idle/spore_bomb_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "spore_bomb_walk",
		"sheet": "res://player/sprites/PNG/SporeBomb_Walk/spore_bomb_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "void_grenade_idle",
		"sheet": "res://player/sprites/PNG/VoidGrenade_Idle/void_grenade_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "void_grenade_walk",
		"sheet": "res://player/sprites/PNG/VoidGrenade_Walk/void_grenade_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "vine_whip_idle",
		"sheet": "res://player/sprites/PNG/VineWhip_Idle/vine_whip_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "vine_whip_walk",
		"sheet": "res://player/sprites/PNG/VineWhip_Walk/vine_whip_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "crystal_lash_idle",
		"sheet": "res://player/sprites/PNG/CrystalLash_Idle/crystal_lash_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "crystal_lash_walk",
		"sheet": "res://player/sprites/PNG/CrystalLash_Walk/crystal_lash_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "petal_shield_idle",
		"sheet": "res://player/sprites/PNG/PetalShield_Idle/petal_shield_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "petal_shield_walk",
		"sheet": "res://player/sprites/PNG/PetalShield_Walk/petal_shield_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "iron_bloom_shield_idle",
		"sheet": "res://player/sprites/PNG/IronBloomShield_Idle/iron_bloom_shield_idle_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "iron_bloom_shield_walk",
		"sheet": "res://player/sprites/PNG/IronBloomShield_Walk/iron_bloom_shield_walk_full.png",
		"columns": 6,
		"frames": [6, 6, 6, 6],
		"loop": true,
		"duration": 0.6,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "thornsword_attack",
		"sheet": "res://player/sprites/PNG/ThornSword_Attack/thornsword_attack_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"loop": false,
		"duration": 0.4,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "blazeblade_attack",
		"sheet": "res://player/sprites/PNG/Blazeblade_Attack/blazeblade_attack_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"loop": false,
		"duration": 0.4,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "vine_whip_attack",
		"sheet": "res://player/sprites/PNG/VineWhip_Attack/vine_whip_attack_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"loop": false,
		"duration": 0.4,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "crystal_lash_attack",
		"sheet": "res://player/sprites/PNG/CrystalLash_Attack/crystal_lash_attack_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"loop": false,
		"duration": 0.4,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "spore_bomb_attack",
		"sheet": "res://player/sprites/PNG/SporeBomb_Attack/spore_bomb_throw_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"rows": [0, 3, 1, 2],
		"loop": false,
		"duration": 0.2,
		"frame_size": SPORE_BOMB_THROW_FRAME_SIZE,
	},
	{
		"prefix": "void_grenade_attack",
		"sheet": "res://player/sprites/PNG/VoidGrenade_Attack/void_grenade_throw_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"rows": [0, 3, 1, 2],
		"loop": false,
		"duration": 0.2,
		"frame_size": SPORE_BOMB_THROW_FRAME_SIZE,
	},
	{
		"prefix": "petal_shield_block",
		"sheet": "res://player/sprites/PNG/PetalShield_Attack/petal_shield_attack_full.png",
		"columns": 8,
		"frames": [3, 3, 3, 3],
		"loop": false,
		"duration": 0.15,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "petal_shield_counter",
		"sheet": "res://player/sprites/PNG/PetalShield_Attack/petal_shield_attack_full.png",
		"columns": 8,
		"frames": [5, 5, 5, 5],
		"start_frame": 3,
		"loop": false,
		"duration": 0.3,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "iron_bloom_shield_block",
		"sheet": "res://player/sprites/PNG/IronBloomShield_Attack/iron_bloom_shield_attack_full.png",
		"columns": 8,
		"frames": [3, 3, 3, 3],
		"loop": false,
		"duration": 0.15,
		"frame_size": WEAPON_FRAME_SIZE,
	},
	{
		"prefix": "iron_bloom_shield_counter",
		"sheet": "res://player/sprites/PNG/IronBloomShield_Attack/iron_bloom_shield_attack_full.png",
		"columns": 8,
		"frames": [5, 5, 5, 5],
		"start_frame": 3,
		"loop": false,
		"duration": 0.3,
		"frame_size": WEAPON_FRAME_SIZE,
	},
]

const BLEND_POSITIONS: Dictionary = {
	"down": Vector2(0, 1),
	"up": Vector2(0, -1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0),
}


static func build(anim_player: AnimationPlayer, sprite_path: String) -> void:
	var lib: AnimationLibrary = AnimationLibrary.new()

	for def: Dictionary in ANIM_DEFS:
		var sheet: Texture2D = load(def["sheet"])
		for dir_idx: int in 4:
			var anim_name: String = "%s_%s" % [def["prefix"], DIR_NAMES[dir_idx]]
			var frame_count: int = def["frames"][dir_idx]
			var total_time: float = def["duration"]
			var frame_dur: float = total_time / float(frame_count)
			var frame_size: Vector2i = def["frame_size"] if def.has("frame_size") else UNARMED_FRAME_SIZE
			var row_idx: int = dir_idx
			if def.has("rows"):
				row_idx = int(def["rows"][dir_idx])
			var start_frame: int = int(def["start_frame"]) if def.has("start_frame") else 0

			var anim: Animation = Animation.new()
			anim.length = total_time
			anim.loop_mode = Animation.LOOP_LINEAR if def["loop"] else Animation.LOOP_NONE

			var t_tex: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(t_tex, "%s:texture" % sprite_path)
			anim.track_set_interpolation_type(t_tex, Animation.INTERPOLATION_NEAREST)
			anim.value_track_set_update_mode(t_tex, Animation.UPDATE_DISCRETE)
			anim.track_insert_key(t_tex, 0.0, sheet)

			var t_reg: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(t_reg, "%s:region_enabled" % sprite_path)
			anim.value_track_set_update_mode(t_reg, Animation.UPDATE_DISCRETE)
			anim.track_insert_key(t_reg, 0.0, true)

			var t_rect: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(t_rect, "%s:region_rect" % sprite_path)
			anim.track_set_interpolation_type(t_rect, Animation.INTERPOLATION_NEAREST)
			anim.value_track_set_update_mode(t_rect, Animation.UPDATE_DISCRETE)

			for f: int in frame_count:
				var rect: Rect2 = Rect2(
					(start_frame + f) * frame_size.x,
					row_idx * frame_size.y,
					frame_size.x,
					frame_size.y
				)
				anim.track_insert_key(t_rect, f * frame_dur, rect)

			lib.add_animation(anim_name, anim)

	var reset: Animation = Animation.new()
	reset.length = 0.001
	var rt: int = reset.add_track(Animation.TYPE_VALUE)
	reset.track_set_path(rt, "%s:region_rect" % sprite_path)
	reset.value_track_set_update_mode(rt, Animation.UPDATE_DISCRETE)
	reset.track_insert_key(rt, 0.0, Rect2(0, 0, UNARMED_FRAME_SIZE.x, UNARMED_FRAME_SIZE.y))
	lib.add_animation("RESET", reset)

	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	anim_player.add_animation_library("", lib)


static func build_tree(anim_tree: AnimationTree) -> void:
	var sm: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
	var movement_states: Array[String] = [
		"idle", "walk",
		"thornsword_idle", "thornsword_walk",
		"blazeblade_idle", "blazeblade_walk",
		"spore_bomb_idle", "spore_bomb_walk",
		"void_grenade_idle", "void_grenade_walk",
		"vine_whip_idle", "vine_whip_walk",
		"crystal_lash_idle", "crystal_lash_walk",
		"petal_shield_idle", "petal_shield_walk",
		"iron_bloom_shield_idle", "iron_bloom_shield_walk",
	]

	for def: Dictionary in ANIM_DEFS:
		var bs: AnimationNodeBlendSpace2D = AnimationNodeBlendSpace2D.new()
		bs.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_DISCRETE
		bs.set_auto_triangles(true)
		bs.min_space = Vector2(-1, -1)
		bs.max_space = Vector2(1, 1)

		for dir_idx: int in 4:
			var anim_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
			anim_node.animation = &"%s_%s" % [def["prefix"], DIR_NAMES[dir_idx]]
			bs.add_blend_point(anim_node, BLEND_POSITIONS[DIR_NAMES[dir_idx]])

		sm.add_node(def["prefix"], bs)

	for src: String in movement_states:
		for dst: String in movement_states:
			if src != dst:
				sm.add_transition(src, dst, AnimationNodeStateMachineTransition.new())

	for src: String in movement_states:
		sm.add_transition(src, "hurt", AnimationNodeStateMachineTransition.new())

	var hurt_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	hurt_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	sm.add_transition("hurt", "idle", hurt_to_idle)

	for src: String in movement_states:
		sm.add_transition(src, "death", AnimationNodeStateMachineTransition.new())
	sm.add_transition("hurt", "death", AnimationNodeStateMachineTransition.new())

	sm.add_transition("death", "idle", AnimationNodeStateMachineTransition.new())

	for src: String in movement_states:
		sm.add_transition(src, "thornsword_attack", AnimationNodeStateMachineTransition.new())

	var ts_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	ts_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	ts_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("thornsword_attack", "thornsword_idle", ts_attack_to_idle)

	for src: String in movement_states:
		sm.add_transition(src, "blazeblade_attack", AnimationNodeStateMachineTransition.new())

	var blaze_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	blaze_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	blaze_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("blazeblade_attack", "blazeblade_idle", blaze_attack_to_idle)

	for src: String in movement_states:
		sm.add_transition(src, "vine_whip_attack", AnimationNodeStateMachineTransition.new())

	var vine_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	vine_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	vine_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("vine_whip_attack", "vine_whip_idle", vine_attack_to_idle)

	for src: String in movement_states:
		sm.add_transition(src, "crystal_lash_attack", AnimationNodeStateMachineTransition.new())

	var crystal_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	crystal_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	crystal_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("crystal_lash_attack", "crystal_lash_idle", crystal_attack_to_idle)

	for src: String in movement_states:
		sm.add_transition(src, "spore_bomb_attack", AnimationNodeStateMachineTransition.new())

	var spore_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	spore_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	spore_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("spore_bomb_attack", "spore_bomb_idle", spore_attack_to_idle)

	for src: String in movement_states:
		sm.add_transition(src, "void_grenade_attack", AnimationNodeStateMachineTransition.new())

	var void_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	void_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	void_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("void_grenade_attack", "void_grenade_idle", void_attack_to_idle)

	for shield_prefix: String in ["petal_shield", "iron_bloom_shield"]:
		var block_state: String = "%s_block" % shield_prefix
		var counter_state: String = "%s_counter" % shield_prefix
		var idle_state: String = "%s_idle" % shield_prefix
		for src: String in movement_states:
			sm.add_transition(src, block_state, AnimationNodeStateMachineTransition.new())

		var block_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
		block_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
		block_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		sm.add_transition(block_state, idle_state, block_to_idle)

		for src: String in movement_states:
			sm.add_transition(src, counter_state, AnimationNodeStateMachineTransition.new())
		sm.add_transition(block_state, counter_state, AnimationNodeStateMachineTransition.new())

		var counter_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
		counter_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
		counter_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		sm.add_transition(counter_state, idle_state, counter_to_idle)

	sm.set_graph_offset(Vector2(0, 0))
	anim_tree.tree_root = sm
