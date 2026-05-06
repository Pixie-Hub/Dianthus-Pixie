class_name BaseBuildSpot
extends Area2D

const INTERACTION_PROMPT_SCENE: PackedScene = preload("res://ui/components/interaction_prompt.tscn")
const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const PROMPT_STATUS_SUCCESS: int = 3

static var _candidate_spots: Array = []
static var _focused_spot: BaseBuildSpot = null

var _player_in_range: bool = false
var _player_body: Node2D = null
var _build_progress: float = 0.0
var _is_building: bool = false

@onready var _prompt_label: Label = %PromptLabel
@onready var _progress_bg: ColorRect = %ProgressBg
@onready var _progress_bar: ColorRect = %ProgressBar

var _interaction_prompt = null


func _ready() -> void:
	_setup_interaction_prompt()
	_hide_prompt()


func _process(delta: float) -> void:
	if not _player_in_range or not _has_interaction_focus() or not _is_building:
		return
	if not _can_interact():
		_cancel_active_interaction()
		_refresh_prompt()
		return
	_build_progress += delta / _get_build_time()
	_update_progress_bar()
	_show_prompt(
		_get_build_progress_title(),
		"Progress: %.0f%%" % (_build_progress * 100.0),
		"Hold E",
		"Release E to cancel",
		_get_build_accent_color(),
		PROMPT_STATUS_NORMAL,
		_build_progress
	)
	if _build_progress >= 1.0:
		_is_building = false
		_build_progress = 0.0
		_set_progress_visible(false)
		_on_interact_completed()


func _physics_process(_delta: float) -> void:
	if not _candidate_spots.is_empty():
		_update_focused_spot()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or not _has_interaction_focus():
		return
	if event.is_action_pressed("interact"):
		if _can_interact():
			_is_building = true
			_build_progress = 0.0
			_set_progress_visible(true)
			get_viewport().set_input_as_handled()
	elif event.is_action_released("interact"):
		if _is_building:
			_is_building = false
			_build_progress = 0.0
			_set_progress_visible(false)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_player_body = body
		_register_focus_candidate()
		_on_player_entered()
		_update_focused_spot()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_player_body = null
		_unregister_focus_candidate()
		_cancel_active_interaction()
		_on_player_exited()
		_hide_prompt()
		_update_focused_spot()


func _exit_tree() -> void:
	_unregister_focus_candidate()
	if _focused_spot == self:
		_focused_spot = null
		_update_focused_spot()


# --- Virtuals ---

func _can_interact() -> bool:
	return false


func _get_build_time() -> float:
	return 3.0


func _get_build_display_name() -> String:
	return ""


func _get_build_progress_title() -> String:
	return "Building %s" % _get_build_display_name()


func _get_build_accent_color() -> Color:
	return Color(1.0, 0.78, 0.28, 1.0)


func _on_interact_completed() -> void:
	pass


func _refresh_prompt() -> void:
	pass


func _on_player_entered() -> void:
	pass


func _on_player_exited() -> void:
	pass


# --- Shared focus helpers ---

func _register_focus_candidate() -> void:
	if not _candidate_spots.has(self):
		_candidate_spots.append(self)


func _unregister_focus_candidate() -> void:
	_candidate_spots.erase(self)


static func _update_focused_spot() -> void:
	var best_spot: BaseBuildSpot = null
	var best_distance_sq: float = INF
	var current_still_valid: bool = false
	var live_candidates: Array = []

	for candidate in _candidate_spots:
		var spot: BaseBuildSpot = candidate as BaseBuildSpot
		if spot == null or not is_instance_valid(spot) or not spot._player_in_range:
			continue
		var player: Node2D = spot._get_focus_player()
		if player == null:
			continue
		live_candidates.append(spot)
		if spot == _focused_spot:
			current_still_valid = true
		var distance_sq: float = spot.global_position.distance_squared_to(player.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_spot = spot

	_candidate_spots = live_candidates
	if best_spot == _focused_spot and current_still_valid:
		return

	var previous_spot: BaseBuildSpot = _focused_spot
	_focused_spot = best_spot
	if is_instance_valid(previous_spot):
		previous_spot._on_interaction_focus_lost()
	if is_instance_valid(_focused_spot):
		_focused_spot._on_interaction_focus_gained()


func _get_focus_player() -> Node2D:
	if is_instance_valid(_player_body):
		return _player_body
	if GameManager.player is Node2D:
		return GameManager.player as Node2D
	return null


func _has_interaction_focus() -> bool:
	return _focused_spot == self and _player_in_range


func _on_interaction_focus_gained() -> void:
	_refresh_prompt()


func _on_interaction_focus_lost() -> void:
	_cancel_active_interaction()
	_hide_prompt()


func _cancel_active_interaction() -> void:
	_is_building = false
	_build_progress = 0.0
	_set_progress_visible(false)


# --- Shared prompt helpers ---

func _setup_interaction_prompt() -> void:
	if is_instance_valid(_prompt_label):
		_prompt_label.visible = false
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = false
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = false
	_interaction_prompt = get_node_or_null("%InteractionPrompt")
	if _interaction_prompt == null:
		_interaction_prompt = INTERACTION_PROMPT_SCENE.instantiate()
		_interaction_prompt.name = "InteractionPrompt"
		add_child(_interaction_prompt)


func _show_prompt(title: String, body: String = "", key_text: String = "", hint: String = "", accent: Color = Color(1.0, 0.78, 0.28, 1.0), status: int = PROMPT_STATUS_NORMAL, progress: float = -1.0) -> void:
	if not _has_interaction_focus():
		_hide_prompt()
		return
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.show_interaction(title, body, key_text, hint, accent, status, progress)
		return
	if is_instance_valid(_prompt_label):
		var lines: PackedStringArray = PackedStringArray([title])
		if not body.is_empty():
			lines.append(body)
		if not hint.is_empty():
			lines.append(hint)
		_prompt_label.text = "\n".join(lines)
		_prompt_label.visible = true


func _hide_prompt() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.hide_prompt()
	if is_instance_valid(_prompt_label):
		_prompt_label.text = ""
		_prompt_label.visible = false
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = false
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = false


func _set_progress_visible(visible_flag: bool) -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.set_progress(0.0 if visible_flag else -1.0)
		return
	if is_instance_valid(_progress_bg):
		_progress_bg.visible = visible_flag
	if is_instance_valid(_progress_bar):
		_progress_bar.visible = visible_flag


func _update_progress_bar() -> void:
	if is_instance_valid(_interaction_prompt):
		_interaction_prompt.set_progress(_build_progress)
		return
	if not is_instance_valid(_progress_bar):
		return
	var bg_width: float = 32.0
	if is_instance_valid(_progress_bg):
		bg_width = _progress_bg.size.x
	_progress_bar.size.x = bg_width * clampf(_build_progress, 0.0, 1.0)


func _show_popup(text: String, color: Color = Color(1.0, 0.8, 0.3)) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(-50, -52)
	add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)
