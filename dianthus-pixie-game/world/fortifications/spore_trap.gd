class_name SporeTrap
extends Area2D

const TRAP_DAMAGE: int = 15
const SLOW_MULTIPLIER: float = 0.5
const SLOW_DURATION: float = 3.0
const TRIGGER_RADIUS: float = 10.0

var _triggered: bool = false

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.ENEMY
	body_entered.connect(_on_enemy_entered)


func _on_enemy_entered(body: Node2D) -> void:
	if _triggered:
		return
	_triggered = true
	if body.has_method("take_damage"):
		body.take_damage(TRAP_DAMAGE)
	if body.has_method("apply_timed_slow"):
		body.apply_timed_slow(SLOW_MULTIPLIER, SLOW_DURATION)
	SfxManager.play_at("spore_bomb_detonate", global_position)
	_show_trigger_vfx()
	queue_free()


func _show_trigger_vfx() -> void:
	if not is_instance_valid(_visual):
		return
	set_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color(0.5, 0.9, 0.5, 0.0), 0.4)
	tween.tween_callback(queue_free)
