class_name TheDevourer
extends EnemyBase

signal damaged_during_surge()

const PHASE2_THRESHOLD: float = 0.7
const PHASE3_THRESHOLD: float = 0.3
const SURGE_THRESHOLD: float = 0.15

const VOID_SLAM_RADIUS: float = 40.0
const VOID_SLAM_DAMAGE_PHASE1: int = 50
const VOID_SLAM_DAMAGE_PHASE3: int = 60

const POLLEN_DAMAGE_MULTIPLIER: float = 1.5

var _current_phase: int = 1
var _surge_used: bool = false
var _summoned_minions: Array[EnemyBase] = []


func _ready() -> void:
	super._ready()
	add_to_group(&"devourer")
	modulate = Color(0.55, 0.2, 0.75, 1.0)


func activate() -> void:
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Phase1")


func should_retreat() -> bool:
	return false


func _uses_top_down_facing() -> bool:
	return false


func _get_death_sfx_id() -> String:
	return "devourer_death"


func _get_seed_drop_table() -> Array[Dictionary]:
	return []


func get_current_phase() -> int:
	return _current_phase


func is_surge_used() -> bool:
	return _surge_used


func mark_surge_used() -> void:
	_surge_used = true


func register_minion(minion: EnemyBase) -> void:
	_summoned_minions.append(minion)
	if not minion.enemy_died.is_connected(_on_minion_died):
		minion.enemy_died.connect(_on_minion_died)


func _on_minion_died(_minion: EnemyBase) -> void:
	pass


func _is_pollen_weapon_equipped() -> bool:
	if not is_instance_valid(GameManager.player):
		return false
	var player: CharacterBody2D = GameManager.player
	if not player.has_method("get") or not "weapon_slots" in player:
		return false
	var slots: Array = player.get("weapon_slots")
	var selected: int = player.get("selected_weapon_slot") if "selected_weapon_slot" in player else 0
	if selected >= slots.size():
		return false
	var weapon_id: String = slots[selected]
	if weapon_id.is_empty():
		return false
	var data: WeaponData = CraftingManager.get_weapon_data(weapon_id)
	if data == null:
		return false
	return data.is_pollen_weapon


func take_damage(amount: int) -> void:
	if is_dead:
		return
	var effective: int = amount
	if _is_pollen_weapon_equipped():
		effective = int(float(amount) * POLLEN_DAMAGE_MULTIPLIER)
	super.take_damage(effective)
	if is_dead:
		return
	damaged_during_surge.emit()
	_check_phase_transition()


func _check_phase_transition() -> void:
	var ratio: float = float(current_hp) / float(max_hp)
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm == null:
		return
	if _current_phase == 1 and ratio <= PHASE2_THRESHOLD:
		_current_phase = 2
		SfxManager.play("devourer_phase_transition")
		MusicManager.seek_to_boss_phase(2)
		fsm.transition_to(&"Phase2")
	elif _current_phase == 2 and ratio <= PHASE3_THRESHOLD:
		_current_phase = 3
		SfxManager.play("devourer_phase_transition")
		MusicManager.seek_to_boss_phase(3)
		fsm.transition_to(&"Phase3")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	var fsm: Node = get_node_or_null("StateMachine")
	if fsm != null:
		fsm.set_process(false)
		fsm.set_physics_process(false)
	for minion in _summoned_minions:
		if is_instance_valid(minion) and not minion.is_dead:
			minion.die()
	enemy_died.emit(self)
	remove_from_group(&"enemies")
	remove_from_group(&"devourer")
	QuestManager.report_event(&"devourer_defeated", 1)
	_play_boss_death_animation()


func _play_boss_death_animation() -> void:
	SfxManager.play_at(_get_death_sfx_id(), global_position)
	if not is_instance_valid(_sprite):
		queue_free()
		return
	if is_instance_valid(_anim_player) and _anim_player.has_animation(&"death"):
		_anim_player.play(&"death")
		await _anim_player.animation_finished
		if is_instance_valid(self):
			queue_free()
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.2, 0.8, 1.4, 1.0), 0.3)
	tween.tween_property(_sprite, "modulate:a", 0.0, 1.5)
	tween.tween_callback(queue_free)
