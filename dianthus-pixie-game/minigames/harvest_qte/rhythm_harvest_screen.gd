extends CanvasLayer

signal finished(hits: int)

const TOTAL_CIRCLES: int = 3
const TARGET_RADIUS: float = 16.0
const APPROACH_START_RADIUS: float = 48.0
const HIT_TOLERANCE: float = 4.0
const CIRCLE_SEGMENTS: int = 32

const DIFFICULTY_SHRINK_SPEEDS: Dictionary = {
	DifficultyManager.Tier.EASY: 38.0,
	DifficultyManager.Tier.NORMAL: 52.0,
	DifficultyManager.Tier.HARD: 70.0,
}

const RESULT_PERFECT_COLOR: Color = Color(0.8, 1.0, 0.62, 1.0)
const RESULT_NORMAL_COLOR: Color = Color(1.0, 0.85, 0.4, 1.0)
const RESULT_FAIL_COLOR: Color = Color(1.0, 0.25, 0.25, 1.0)

const TARGET_COLOR: Color = Color(0.9, 0.72, 0.24, 0.85)
const APPROACH_COLOR: Color = Color(1.0, 0.93, 0.72, 0.9)
const HIT_FLASH_COLOR: Color = Color(0.8, 1.0, 0.62, 1.0)
const MISS_FLASH_COLOR: Color = Color(1.0, 0.25, 0.25, 1.0)

var _item_id: String = ""
var _amount: int = 1
var _shrink_speed: float = 52.0
var _active: bool = false
var _current_circle: int = 0
var _hits: int = 0
var _approach_radius: float = APPROACH_START_RADIUS
var _waiting_next: bool = false
var _flash_timer: float = 0.0
var _flash_color: Color = Color.TRANSPARENT
var _show_result: bool = false
var _result_timer: float = 0.0

var _circle_draw: Control = null
var _prompt_label: Label = null
var _result_label: Label = null
var _progress_label: Label = null


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _active:
		visible = false
		set_process(false)


func start_qte(item_id: String, amount: int) -> void:
	_item_id = item_id
	_amount = amount
	_shrink_speed = _get_shrink_speed()
	_current_circle = 0
	_hits = 0
	_active = true
	_waiting_next = false
	_show_result = false
	_flash_timer = 0.0
	visible = true

	_build_ui()
	_start_circle()

	SfxManager.play("harvest_qte_prompt")
	PauseManager.request_pause(self)
	set_process(true)


func _build_ui() -> void:
	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.color = Color(0.0, 0.0, 0.0, 0.36)
	add_child(dimmer)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -100.0
	panel.offset_top = -70.0
	panel.offset_right = 100.0
	panel.offset_bottom = 70.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.08, 0.94)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.9, 0.72, 0.24, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_prompt_label = Label.new()
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72, 1.0))
	_prompt_label.add_theme_font_size_override("font_size", 10)
	_prompt_label.text = "Press Space on the beat!"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_prompt_label)

	_circle_draw = Control.new()
	_circle_draw.name = "CircleDraw"
	_circle_draw.custom_minimum_size = Vector2(120.0, 100.0)
	_circle_draw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_circle_draw.connect("draw", _on_circle_draw)
	vbox.add_child(_circle_draw)

	_progress_label = Label.new()
	_progress_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1.0))
	_progress_label.add_theme_font_size_override("font_size", 8)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_progress_label)
	_update_progress_label()

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 9)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)


func _start_circle() -> void:
	_approach_radius = APPROACH_START_RADIUS
	_waiting_next = false
	_flash_timer = 0.0
	_update_progress_label()
	if _circle_draw != null:
		_circle_draw.queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return

	if _show_result:
		_result_timer -= delta
		if _result_timer <= 0.0:
			_finish()
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _circle_draw != null:
			_circle_draw.queue_redraw()
		if _flash_timer <= 0.0:
			_advance_circle()
		return

	if _waiting_next:
		return

	_approach_radius = maxf(_approach_radius - _shrink_speed * delta, 0.0)
	if _circle_draw != null:
		_circle_draw.queue_redraw()

	if _approach_radius <= 0.0:
		_register_miss()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _waiting_next or _show_result:
		if event is InputEventKey and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_check_hit()


func _check_hit() -> void:
	var diff: float = absf(_approach_radius - TARGET_RADIUS)
	if diff <= HIT_TOLERANCE:
		_hits += 1
		_flash_color = HIT_FLASH_COLOR
		SfxManager.play("harvest_qte_success")
	else:
		_flash_color = MISS_FLASH_COLOR
		SfxManager.play("harvest_qte_fail")
	_waiting_next = true
	_flash_timer = 0.35
	if _circle_draw != null:
		_circle_draw.queue_redraw()


func _register_miss() -> void:
	_flash_color = MISS_FLASH_COLOR
	SfxManager.play("harvest_qte_fail")
	_waiting_next = true
	_flash_timer = 0.35
	if _circle_draw != null:
		_circle_draw.queue_redraw()


func _advance_circle() -> void:
	_current_circle += 1
	if _current_circle >= TOTAL_CIRCLES:
		_show_final_result()
	else:
		_start_circle()


func _show_final_result() -> void:
	_show_result = true
	_result_timer = 0.6
	_update_progress_label()
	if _hits == TOTAL_CIRCLES:
		_result_label.text = "Perfect Harvest!"
		_result_label.add_theme_color_override("font_color", RESULT_PERFECT_COLOR)
	elif _hits >= 1:
		_result_label.text = "Harvest Secured"
		_result_label.add_theme_color_override("font_color", RESULT_NORMAL_COLOR)
	else:
		_result_label.text = "Harvest Lost!"
		_result_label.add_theme_color_override("font_color", RESULT_FAIL_COLOR)
	if _circle_draw != null:
		_circle_draw.queue_redraw()


func _finish() -> void:
	_active = false
	set_process(false)
	PauseManager.release_pause(self)
	finished.emit(_hits)
	queue_free()


func _update_progress_label() -> void:
	if _progress_label == null:
		return
	var done: int = mini(_current_circle, TOTAL_CIRCLES)
	_progress_label.text = "%d / %d  |  Hits: %d" % [done + 1 if done < TOTAL_CIRCLES else done, TOTAL_CIRCLES, _hits]


func _on_circle_draw() -> void:
	if _circle_draw == null:
		return
	var center: Vector2 = _circle_draw.size * 0.5

	if _show_result:
		return

	if _flash_timer > 0.0:
		_draw_circle_outline(_circle_draw, center, TARGET_RADIUS + 2.0, _flash_color, 3.0)
		return

	_draw_filled_circle(_circle_draw, center, TARGET_RADIUS, TARGET_COLOR)
	if _approach_radius > 0.0:
		_draw_circle_outline(_circle_draw, center, _approach_radius, APPROACH_COLOR, 2.5)


func _draw_filled_circle(ctrl: Control, center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(CIRCLE_SEGMENTS + 1):
		var angle: float = TAU * float(i) / float(CIRCLE_SEGMENTS)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(points.size())
	colors.fill(color)
	ctrl.draw_polygon(points, colors)


func _draw_circle_outline(ctrl: Control, center: Vector2, radius: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(CIRCLE_SEGMENTS + 1):
		var angle: float = TAU * float(i) / float(CIRCLE_SEGMENTS)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	for i: int in range(points.size() - 1):
		ctrl.draw_line(points[i], points[i + 1], color, width, true)


func _get_shrink_speed() -> float:
	var tier_id: int = DifficultyManager.get_tier_id()
	return float(DIFFICULTY_SHRINK_SPEEDS.get(tier_id, DIFFICULTY_SHRINK_SPEEDS[DifficultyManager.Tier.NORMAL]))


func _exit_tree() -> void:
	if _active:
		PauseManager.release_pause(self)
