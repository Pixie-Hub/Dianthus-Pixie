class_name BaseBuildSpot
extends Area2D

const INTERACTION_PROMPT_SCENE: PackedScene = preload("res://ui/components/interaction_prompt.tscn")
const PROMPT_STATUS_NORMAL: int = 0
const PROMPT_STATUS_DISABLED: int = 2
const PROMPT_STATUS_SUCCESS: int = 3

var _player_in_range: bool = false
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
	if not _player_in_range or not _is_building:
		return
	if not _can_interact():
		_is_building = false
		_build_progress = 0.0
		_set_progress_visible(false)
		_refresh_prompt()
		return
	_build_progress += delta / _get_build_time()
	_update_progress_bar()
	_show_prompt(
		"Building %s" % _get_build_display_name(),
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


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
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
		_on_player_entered()
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if _is_building:
			_is_building = false
			_build_progress = 0.0
			_set_progress_visible(false)
		_on_player_exited()
		_hide_prompt()


# --- Virtuals ---

func _can_interact() -> bool:
	return false


func _get_build_time() -> float:
	return 3.0


func _get_build_display_name() -> String:
	return ""


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
