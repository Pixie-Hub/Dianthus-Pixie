extends State

const FADE_DURATION: float = 0.3


func enter() -> void:
	var e: PhantomWeaver = enemy as PhantomWeaver
	if e == null:
		return
	e._pending_teleport = false
	e._is_teleporting = true
	e.velocity = Vector2.ZERO
	e.play_animation(&"idle")
	_do_teleport(e)


func physics_update(_delta: float) -> void:
	# Movement frozen during teleport — keep velocity zero.
	var e: PhantomWeaver = enemy as PhantomWeaver
	if e != null:
		e.velocity = Vector2.ZERO
		e.move_and_slide()


func _do_teleport(e: PhantomWeaver) -> void:
	var sprite: Sprite2D = e.get_node_or_null("%Sprite2D") as Sprite2D
	var destination: Vector2 = e.pick_teleport_destination()
	print("[PhantomWeaver] Teleport %s -> %s" % [e.global_position, destination])

	# TODO (VFX-03): Replace alpha tween with real teleport particle/shader effect.
	# Fade out.
	if is_instance_valid(sprite):
		var tween_out: Tween = e.create_tween()
		tween_out.tween_property(sprite, "modulate:a", 0.0, FADE_DURATION)
		await tween_out.finished
	if not is_instance_valid(e) or e.is_dead:
		return

	# Reposition.
	e.global_position = destination
	var nav: NavigationAgent2D = e.get_node_or_null("%NavigationAgent2D") as NavigationAgent2D
	if is_instance_valid(nav):
		nav.target_position = e.get_core_position()

	# TODO (VFX-03): Replace alpha tween with real teleport particle/shader effect.
	# Fade in.
	if is_instance_valid(sprite):
		var tween_in: Tween = e.create_tween()
		tween_in.tween_property(sprite, "modulate:a", 1.0, FADE_DURATION)
		await tween_in.finished
	if not is_instance_valid(e) or e.is_dead:
		return

	e._is_teleporting = false
	state_machine.transition_to(&"Scout")
