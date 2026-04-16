extends CanvasLayer

var _overlay: ColorRect
var _tween: Tween
var _busy: bool = false

func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_fade_in()

func transition_to(target_scene: String) -> void:
	if _busy:
		return
	if GameManager.current_state == GameManager.GameState.DEFENSE:
		return
	_busy = true
	await _fade_out()
	var player: Node = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		GameManager.player_data["position"] = player.global_position
		GameManager.player_data["last_zone"] = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(target_scene)
	await _fade_in()
	_busy = false

func _fade_out() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, 0.5)
	await _tween.finished

func _fade_in() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 0.0, 0.5)
	await _tween.finished
