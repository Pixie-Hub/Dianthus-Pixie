class_name SporeBombProjectile
extends Area2D

@export var fuse_time: float = 1.0
@export var damage: int = 20
@export var aoe_radius: float = 32.0
@export var slow_multiplier: float = 0.6
@export var slow_duration: float = 2.0
@export var arc_height: float = 24.0

const PROJECTILE_FRAME_SIZE: Vector2i = Vector2i(16, 16)
const PROJECTILE_FRAMES: int = 8
const PROJECTILE_FRAME_TIME: float = 0.08
const DETONATION_FRAME_SIZE: Vector2i = Vector2i(64, 64)
const DETONATION_FRAMES: int = 8
const DETONATION_FRAME_TIME: float = 0.06

var _start_pos: Vector2
var _target_pos: Vector2
var _t: float = 0.0
var _exploded: bool = false
@onready var _visual: Sprite2D = %Visual
@onready var _detonation_vfx: Sprite2D = %DetonationVfx

func _ready() -> void:
	_set_projectile_frame(0)
	_set_detonation_frame(0)

func launch(from_pos: Vector2, to_pos: Vector2) -> void:
	_start_pos = from_pos
	_target_pos = to_pos
	global_position = from_pos


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_t += delta
	var u: float = clamp(_t / fuse_time, 0.0, 1.0)
	var lin: Vector2 = _start_pos.lerp(_target_pos, u)
	lin.y -= sin(u * PI) * arc_height
	global_position = lin
	var frame: int = int(floor(_t / PROJECTILE_FRAME_TIME)) % PROJECTILE_FRAMES
	_set_projectile_frame(frame)
	if _t >= fuse_time:
		_explode()


func _explode() -> void:
	_exploded = true
	set_physics_process(false)
	var _det_sfx: String = "void_grenade_detonate" if damage >= 30 else "spore_bomb_detonate"
	SfxManager.play_at(_det_sfx, global_position)
	for body in get_tree().get_nodes_in_group(&"enemies"):
		if body is EnemyBase and not body.is_dead:
			if global_position.distance_to(body.global_position) <= aoe_radius:
				body.take_damage(damage)
				body.apply_timed_slow(slow_multiplier, slow_duration)
				if is_instance_valid(GameManager.player):
					GameManager.player.add_energy(GameManager.player.ENERGY_PER_HIT)
	await _play_detonation_vfx()
	print("[SporeBomb] Exploded at %s — radius %.0f, dmg %d" % [global_position, aoe_radius, damage])
	queue_free()


func _set_projectile_frame(frame: int) -> void:
	if _visual == null:
		return
	_visual.region_rect = Rect2(
		frame * PROJECTILE_FRAME_SIZE.x,
		0,
		PROJECTILE_FRAME_SIZE.x,
		PROJECTILE_FRAME_SIZE.y
	)


func _set_detonation_frame(frame: int) -> void:
	if _detonation_vfx == null:
		return
	_detonation_vfx.region_rect = Rect2(
		frame * DETONATION_FRAME_SIZE.x,
		0,
		DETONATION_FRAME_SIZE.x,
		DETONATION_FRAME_SIZE.y
	)


func _play_detonation_vfx() -> void:
	if _visual != null:
		_visual.visible = false
	if _detonation_vfx == null:
		await get_tree().create_timer(0.4).timeout
		return
	_detonation_vfx.visible = true
	for frame: int in DETONATION_FRAMES:
		_set_detonation_frame(frame)
		await get_tree().create_timer(DETONATION_FRAME_TIME).timeout
