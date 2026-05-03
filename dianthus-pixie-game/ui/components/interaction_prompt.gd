class_name InteractionPrompt
extends PanelContainer

enum Status { NORMAL, WARNING, DISABLED, SUCCESS }

const DEFAULT_ACCENT: Color = Color(1.0, 0.78, 0.28, 1.0)
const WARNING_ACCENT: Color = Color(1.0, 0.45, 0.25, 1.0)
const DISABLED_ACCENT: Color = Color(0.68, 0.68, 0.68, 1.0)
const SUCCESS_ACCENT: Color = Color(0.45, 0.95, 0.58, 1.0)

@onready var _accent_bar: ColorRect = %AccentBar
@onready var _key_badge: PanelContainer = %KeyBadge
@onready var _key_label: Label = %KeyLabel
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _hint_label: Label = %HintLabel
@onready var _progress_bg: ColorRect = %ProgressBg
@onready var _progress_fill: ColorRect = %ProgressFill

var _shown_once: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide_prompt()


func show_interaction(title: String, body: String = "", key_text: String = "", hint: String = "", accent: Color = DEFAULT_ACCENT, status: int = Status.NORMAL, progress: float = -1.0) -> void:
	var display_accent: Color = _resolve_accent(accent, status)
	_apply_accent(display_accent)

	_title_label.text = title
	_body_label.text = body
	_body_label.visible = not body.is_empty()
	_hint_label.text = hint
	_hint_label.visible = not hint.is_empty()
	_key_label.text = key_text
	_key_badge.visible = not key_text.is_empty()
	_title_label.modulate = Color(1.0, 1.0, 1.0, 1.0) if status != Status.DISABLED else Color(0.75, 0.75, 0.75, 1.0)

	set_progress(progress)
	_show_panel()


func show_message(text: String, accent: Color = DEFAULT_ACCENT, status: int = Status.NORMAL, progress: float = -1.0) -> void:
	if text.strip_edges().is_empty():
		hide_prompt()
		return

	var parsed: Dictionary = _parse_message(text)
	var parsed_status: int = status
	if parsed_status == Status.NORMAL:
		parsed_status = _infer_status(text)
	show_interaction(
		parsed.get("title", ""),
		parsed.get("body", ""),
		parsed.get("key", ""),
		parsed.get("hint", ""),
		accent,
		parsed_status,
		progress
	)


func set_progress(ratio: float) -> void:
	if ratio < 0.0:
		_progress_bg.visible = false
		return

	var clamped: float = clampf(ratio, 0.0, 1.0)
	_progress_bg.visible = clamped > 0.0 and clamped < 1.0
	var width: float = maxf(_progress_bg.size.x, _progress_bg.custom_minimum_size.x)
	var height: float = maxf(_progress_bg.size.y, _progress_bg.custom_minimum_size.y)
	_progress_fill.size = Vector2(width * clamped, height)


func hide_prompt() -> void:
	visible = false
	_progress_bg.visible = false
	_shown_once = false


func _show_panel() -> void:
	if visible:
		return
	visible = true
	if _shown_once:
		return
	_shown_once = true
	modulate.a = 0.0
	scale = Vector2(0.96, 0.96)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.08)


func _parse_message(text: String) -> Dictionary:
	var lines: PackedStringArray = text.split("\n", false)
	var first_line: String = lines[0].strip_edges() if not lines.is_empty() else text.strip_edges()
	var key_and_title: Dictionary = _extract_key_and_title(first_line)
	var body_lines: PackedStringArray = PackedStringArray()
	for i: int in range(1, lines.size()):
		var line: String = lines[i].strip_edges()
		if not line.is_empty():
			body_lines.append(line)

	var body: String = ""
	var hint: String = ""
	if not body_lines.is_empty():
		body = body_lines[0]
		if body_lines.size() > 1:
			var hint_lines: PackedStringArray = PackedStringArray()
			for i: int in range(1, body_lines.size()):
				hint_lines.append(body_lines[i])
			hint = "  ".join(hint_lines)

	return {
		"key": key_and_title.get("key", ""),
		"title": key_and_title.get("title", first_line),
		"body": body,
		"hint": hint,
	}


func _extract_key_and_title(line: String) -> Dictionary:
	var open_index: int = line.find("[")
	var close_index: int = line.find("]", open_index + 1)
	if open_index == -1 or close_index == -1:
		return {"key": "", "title": line}

	var before: String = line.substr(0, open_index).strip_edges()
	var key: String = line.substr(open_index + 1, close_index - open_index - 1).strip_edges()
	var after: String = line.substr(close_index + 1).strip_edges()
	if before.to_lower() == "hold" and not key.to_lower().begins_with("hold"):
		key = "Hold %s" % key
		if after.to_lower().begins_with("to "):
			after = after.substr(3).strip_edges()

	var title_parts: PackedStringArray = PackedStringArray()
	if not before.is_empty() and before.to_lower() != "hold":
		title_parts.append(before)
	if not after.is_empty():
		title_parts.append(after)
	var title: String = " ".join(title_parts).strip_edges()
	return {"key": key, "title": title if not title.is_empty() else line}


func _infer_status(text: String) -> int:
	var lower_text: String = text.to_lower()
	if lower_text.contains("not enough") or lower_text.contains("failed"):
		return Status.DISABLED
	if lower_text.contains("warning") or lower_text.contains("don't leave") or lower_text.contains("stand still"):
		return Status.WARNING
	if lower_text.contains("built") or lower_text.contains("received"):
		return Status.SUCCESS
	return Status.NORMAL


func _resolve_accent(accent: Color, status: int) -> Color:
	match status:
		Status.WARNING:
			return WARNING_ACCENT
		Status.DISABLED:
			return DISABLED_ACCENT
		Status.SUCCESS:
			return SUCCESS_ACCENT
		_:
			return accent


func _apply_accent(accent: Color) -> void:
	_accent_bar.color = accent
	_progress_fill.color = accent
	_key_label.add_theme_color_override("font_color", accent)
