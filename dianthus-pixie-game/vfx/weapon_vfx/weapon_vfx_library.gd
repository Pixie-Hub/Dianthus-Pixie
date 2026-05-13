class_name WeaponVfxLibrary
extends RefCounted

const ATTACK_FRAMES: Dictionary = {
	"thorn_sword": preload("res://vfx/weapon_vfx/sprite_frames/thorn_sword_swing_vfx_sprite_frames.tres"),
	"blazeblade": preload("res://vfx/weapon_vfx/sprite_frames/blazeblade_swing_vfx_sprite_frames.tres"),
	"vine_whip": preload("res://vfx/weapon_vfx/sprite_frames/vine_whip_swing_vfx_sprite_frames.tres"),
	"crystal_lash": preload("res://vfx/weapon_vfx/sprite_frames/crystal_lash_swing_vfx_sprite_frames.tres"),
	"spore_bomb": preload("res://vfx/weapon_vfx/sprite_frames/spore_bomb_throw_vfx_sprite_frames.tres"),
	"void_grenade": preload("res://vfx/weapon_vfx/sprite_frames/void_grenade_throw_vfx_sprite_frames.tres"),
}

const SHIELD_FRAMES: Dictionary = {
	"petal_shield": preload("res://vfx/weapon_vfx/sprite_frames/petal_shield_counter_vfx_sprite_frames.tres"),
	"iron_bloom_shield": preload("res://vfx/weapon_vfx/sprite_frames/iron_bloom_shield_counter_vfx_sprite_frames.tres"),
}

const IMPACT_FRAMES: Dictionary = {
	"thorn_sword": preload("res://vfx/weapon_vfx/sprite_frames/thorn_sword_impact_vfx_sprite_frames.tres"),
	"blazeblade": preload("res://vfx/weapon_vfx/sprite_frames/blazeblade_impact_vfx_sprite_frames.tres"),
	"vine_whip": preload("res://vfx/weapon_vfx/sprite_frames/vine_whip_impact_vfx_sprite_frames.tres"),
	"crystal_lash": preload("res://vfx/weapon_vfx/sprite_frames/crystal_lash_impact_vfx_sprite_frames.tres"),
	"petal_shield": preload("res://vfx/weapon_vfx/sprite_frames/petal_shield_impact_vfx_sprite_frames.tres"),
	"iron_bloom_shield": preload("res://vfx/weapon_vfx/sprite_frames/iron_bloom_shield_impact_vfx_sprite_frames.tres"),
	"spore_bomb": preload("res://vfx/weapon_vfx/sprite_frames/spore_bomb_impact_vfx_sprite_frames.tres"),
	"void_grenade": preload("res://vfx/weapon_vfx/sprite_frames/void_grenade_impact_vfx_sprite_frames.tres"),
}


static func get_attack_frames(weapon_id: String) -> SpriteFrames:
	return ATTACK_FRAMES.get(weapon_id, null) as SpriteFrames


static func get_shield_frames(weapon_id: String) -> SpriteFrames:
	return SHIELD_FRAMES.get(weapon_id, null) as SpriteFrames


static func get_impact_frames(weapon_id: String) -> SpriteFrames:
	return IMPACT_FRAMES.get(weapon_id, null) as SpriteFrames


static func direction_animation(direction: Vector2) -> StringName:
	if direction == Vector2.UP:
		return &"up"
	if direction == Vector2.LEFT:
		return &"left"
	if direction == Vector2.RIGHT:
		return &"right"
	return &"down"


static func shield_animation(phase: String, direction: Vector2) -> StringName:
	return StringName("%s_%s" % [phase, String(direction_animation(direction))])
