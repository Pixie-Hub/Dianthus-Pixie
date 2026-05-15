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

func transition_to(
	target_scene: String,
	target_entry_marker: StringName = &"",
	allow_during_defense: bool = false
) -> void:
	if _busy:
		return
	if GameManager.current_state == GameManager.GameState.DEFENSE and not allow_during_defense:
		return
	_busy = true
	await _fade_out()
	var player: Node = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		GameManager.player_data["position"] = player.global_position
		GameManager.player_data["last_zone"] = get_tree().current_scene.scene_file_path
		GameManager.player_data["weapon_slots"] = (player.get("weapon_slots") as Array).duplicate()
		GameManager.player_data["selected_weapon_slot"] = int(player.get("selected_weapon_slot"))
		GameManager.player_data["active_skill_id"] = str(player.get("active_skill_id"))
	GameManager.player_data["target_entry_marker"] = str(target_entry_marker)
	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	_place_player_at_entry_marker(target_entry_marker)
	await _fade_in()
	_busy = false


func _place_player_at_entry_marker(target_entry_marker: StringName) -> void:
	if target_entry_marker == &"":
		return
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var marker: Node2D = scene_root.find_child(str(target_entry_marker), true, false) as Node2D
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if marker == null or player == null:
		GameManager.player_data["target_entry_marker"] = ""
		return
	player.global_position = marker.global_position
	GameManager.player_data["position"] = marker.global_position
	GameManager.player_data["target_entry_marker"] = ""

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
