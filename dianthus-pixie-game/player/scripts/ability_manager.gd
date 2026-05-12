class_name AbilityManager
extends Node

const ABILITIES: Dictionary = {
	"dash": {
		"display_name": "Dash",
		"description": "Dash in the facing direction, granting brief invincibility.",
		"energy_cost": 20,
		"cooldown": 2.0,
	},
	"heal_pulse": {
		"display_name": "Heal Pulse",
		"description": "Release a burst of Dianthus energy to restore 25 HP.",
		"energy_cost": 40,
		"cooldown": 8.0,
	},
	"thorn_burst": {
		"display_name": "Thorn Burst",
		"description": "Unleash a ring of thorns that damages and briefly stuns nearby enemies.",
		"energy_cost": 35,
		"cooldown": 5.0,
	},
}

const DASH_DISTANCE: float = 64.0
const DASH_DURATION: float = 0.12
const HEAL_PULSE_AMOUNT: int = 25
const THORN_BURST_DAMAGE: int = 18
const THORN_BURST_RADIUS: float = 56.0
const THORN_BURST_STUN: float = 0.4

var _cooldown_timers: Dictionary = {}


func _process(delta: float) -> void:
	for ability_id: String in _cooldown_timers.keys():
		_cooldown_timers[ability_id] = max(float(_cooldown_timers[ability_id]) - delta, 0.0)


func get_energy_cost(ability_id: String) -> int:
	return int(ABILITIES.get(ability_id, {}).get("energy_cost", 30))


func is_on_cooldown(ability_id: String) -> bool:
	return float(_cooldown_timers.get(ability_id, 0.0)) > 0.0


func get_remaining_cooldown(ability_id: String) -> float:
	return float(_cooldown_timers.get(ability_id, 0.0))


func try_activate(ability_id: String, player: CharacterBody2D) -> bool:
	if ability_id.is_empty():
		print("[AbilityManager] No skill equipped in the skill slot.")
		return false
	if not ABILITIES.has(ability_id):
		push_warning("[AbilityManager] Unknown ability_id: '%s'" % ability_id)
		return false
	if is_on_cooldown(ability_id):
		print("[AbilityManager] '%s' still on cooldown (%.1fs remaining)." % [
				ability_id, get_remaining_cooldown(ability_id)])
		return false
	var cost: int = int(ABILITIES[ability_id].get("energy_cost", 30))
	if not player.try_spend_energy(cost):
		print("[AbilityManager] Not enough energy for '%s'. Need %d, have %d." % [
				ability_id, cost, int(player.get("current_energy"))])
		return false
	_cooldown_timers[ability_id] = float(ABILITIES[ability_id].get("cooldown", 0.0))
	_execute(ability_id, player)
	print("[AbilityManager] Activated '%s' (-%d energy, %.1fs cooldown)." % [
			ability_id, cost, float(ABILITIES[ability_id].get("cooldown", 0.0))])
	return true


func _execute(ability_id: String, player: CharacterBody2D) -> void:
	match ability_id:
		"dash":
			_ability_dash(player)
		"heal_pulse":
			_ability_heal_pulse(player)
		"thorn_burst":
			_ability_thorn_burst(player)
		_:
			push_warning("[AbilityManager] No behavior implemented for ability_id: '%s'" % ability_id)


func _ability_dash(player: CharacterBody2D) -> void:
	var dir: Vector2 = Vector2(player.get("last_direction"))
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	SfxManager.play_at("ability_dash", player.global_position)
	player.set("is_invincible", true)
	var tween: Tween = player.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "position", player.position + dir * DASH_DISTANCE, DASH_DURATION)
	var end_timer: SceneTreeTimer = player.get_tree().create_timer(DASH_DURATION + 0.05)
	end_timer.timeout.connect(func() -> void:
		if is_instance_valid(player) and not bool(player.get("is_dead")):
			player.set("is_invincible", false)
	)


func _ability_heal_pulse(player: CharacterBody2D) -> void:
	SfxManager.play_at("ability_heal_pulse", player.global_position)
	if player.has_method("heal"):
		var heal_amount: int = int(roundf(float(HEAL_PULSE_AMOUNT) * CraftingManager.get_ability_effect_multiplier("heal_pulse")))
		player.heal(heal_amount)


func _ability_thorn_burst(player: CharacterBody2D) -> void:
	SfxManager.play_at("ability_thorn_burst", player.global_position)
	var hit_count: int = 0
	var burst_damage: int = int(roundf(float(THORN_BURST_DAMAGE) * CraftingManager.get_ability_effect_multiplier("thorn_burst")))
	for body in player.get_tree().get_nodes_in_group(&"enemies"):
		if body is EnemyBase and not body.is_dead:
			if player.global_position.distance_to(body.global_position) <= THORN_BURST_RADIUS:
				body.take_damage(burst_damage)
				if body.has_method("apply_stun"):
					body.apply_stun(THORN_BURST_STUN)
				hit_count += 1
	if hit_count > 0 and player.has_method("add_energy"):
		player.add_energy(hit_count * 3)
	_spawn_thorn_burst_vfx(player)


func _spawn_thorn_burst_vfx(player: CharacterBody2D) -> void:
	var ring: ColorRect = ColorRect.new()
	ring.color = Color(0.45, 0.85, 0.25, 0.5)
	var size: float = THORN_BURST_RADIUS * 2.0
	ring.size = Vector2(size, size)
	ring.position = -Vector2(size * 0.5, size * 0.5)
	player.add_child(ring)
	var tween: Tween = player.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)
