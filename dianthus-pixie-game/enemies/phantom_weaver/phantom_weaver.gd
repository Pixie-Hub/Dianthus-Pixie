class_name PhantomWeaver
extends EnemyBase

# TODO: ENEMY-WEAKNESS — GDD §8.1 lists Wijaya Kusuma + light AoE as weaknesses.
# Implement damage multiplier here once the generic weakness-multiplier system is built.

@export var teleport_threshold: float = 0.3
@export var teleport_min_distance: float = 96.0
@export var teleport_max_distance: float = 160.0
@export var teleport_min_dist_from_player: float = 64.0
@export var teleport_min_dist_from_core: float = 48.0

var _has_teleported: bool = false
var _pending_teleport: bool = false
var _is_teleporting: bool = false


func _ready() -> void:
	super._ready()


func activate() -> void:
	var fsm: StateMachine = get_node_or_null("StateMachine") as StateMachine
	if fsm != null:
		fsm.transition_to(&"Idle")


# Override: Phantom Weaver relocates instead of retreating.
func should_retreat() -> bool:
	return false


# Override: detect 30% HP crossover; trigger one-time teleport.
func take_damage(amount: int) -> void:
	if is_dead or _is_teleporting:
		return
	var hp_before: int = current_hp
	super.take_damage(amount)
	if is_dead:
		return
	if not _has_teleported and hp_before > int(max_hp * teleport_threshold) \
			and current_hp <= int(max_hp * teleport_threshold):
		_has_teleported = true
		_pending_teleport = true


# Picks a teleport destination satisfying all distance constraints.
# Falls back to a random direction if no valid spot is found within MAX_TRIES.
func pick_teleport_destination() -> Vector2:
	const MAX_TRIES: int = 12
	var player_pos: Vector2 = get_player_position()
	var core_pos: Vector2 = get_core_position()
	for _i in MAX_TRIES:
		var angle: float = randf() * TAU
		var dist: float = randf_range(teleport_min_distance, teleport_max_distance)
		var candidate: Vector2 = global_position + Vector2.from_angle(angle) * dist
		if candidate.distance_to(player_pos) < teleport_min_dist_from_player:
			continue
		if candidate.distance_to(core_pos) < teleport_min_dist_from_core:
			continue
		return candidate
	# Fallback — directly opposite the player at max distance.
	var away: Vector2 = (global_position - player_pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	return global_position + away * teleport_max_distance
