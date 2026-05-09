@tool
class_name PlayerAnimationBuilder

const UNARMED_FRAME_SIZE: Vector2i = Vector2i(64, 80)
const WEAPON_FRAME_SIZE: Vector2i = Vector2i(80, 96)

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
		"prefix": "thornsword_attack",
		"sheet": "res://player/sprites/PNG/ThornSword_Attack/thornsword_attack_full.png",
		"columns": 8,
		"frames": [8, 8, 8, 8],
		"loop": false,
		"duration": 0.4,
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
					f * frame_size.x,
					dir_idx * frame_size.y,
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

	sm.add_transition("idle", "walk", AnimationNodeStateMachineTransition.new())
	sm.add_transition("walk", "idle", AnimationNodeStateMachineTransition.new())

	sm.add_transition("thornsword_idle", "thornsword_walk", AnimationNodeStateMachineTransition.new())
	sm.add_transition("thornsword_walk", "thornsword_idle", AnimationNodeStateMachineTransition.new())

	sm.add_transition("idle", "thornsword_idle", AnimationNodeStateMachineTransition.new())
	sm.add_transition("thornsword_idle", "idle", AnimationNodeStateMachineTransition.new())
	sm.add_transition("walk", "thornsword_walk", AnimationNodeStateMachineTransition.new())
	sm.add_transition("thornsword_walk", "walk", AnimationNodeStateMachineTransition.new())

	for src: String in ["idle", "walk", "thornsword_idle", "thornsword_walk"]:
		sm.add_transition(src, "hurt", AnimationNodeStateMachineTransition.new())

	var hurt_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	hurt_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	sm.add_transition("hurt", "idle", hurt_to_idle)

	for src: String in ["idle", "walk", "hurt", "thornsword_idle", "thornsword_walk"]:
		sm.add_transition(src, "death", AnimationNodeStateMachineTransition.new())

	sm.add_transition("death", "idle", AnimationNodeStateMachineTransition.new())

	for src: String in ["thornsword_idle", "thornsword_walk"]:
		sm.add_transition(src, "thornsword_attack", AnimationNodeStateMachineTransition.new())

	var ts_attack_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	ts_attack_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	ts_attack_to_idle.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("thornsword_attack", "thornsword_idle", ts_attack_to_idle)

	sm.set_graph_offset(Vector2(0, 0))
	anim_tree.tree_root = sm
