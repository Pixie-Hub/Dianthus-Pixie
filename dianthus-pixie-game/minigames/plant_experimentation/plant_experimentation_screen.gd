extends CanvasLayer
class_name PlantExperimentationScreen

signal finished(quality_tier: int, success: bool)

const QUALITY_LABELS: Array[String] = ["Biasa", "Superior", "Masterwork"]
const QUALITY_COLORS: Array[Color] = [
	Color(0.95, 0.90, 0.80, 1.0),
	Color(0.30, 0.85, 0.45, 1.0),
	Color(1.0, 0.80, 0.25, 1.0),
]
const NODE_COLORS: Array[Color] = [
	Color(0.85, 0.20, 0.20, 1.0),
	Color(0.20, 0.55, 0.90, 1.0),
	Color(0.90, 0.82, 0.18, 1.0),
]
const NODE_RADIUS: float = 14.0
const WIRE_WIDTH: float = 3.0
const TIER_THRESHOLDS: Array[int] = [30, 65, 90]

@onready var _node_area: Control = %NodeArea
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _score_label: Label = %ScoreLabel
@onready var _result_label: Label = %ResultLabel
@onready var _combo_hint_label: Label = %ComboHintLabel

var _total_time: float = 9.0
var _remaining_time: float = 0.0
var _sources: Array[Dictionary] = []
var _sinks: Array[Dictionary] = []
var _connections: Dictionary = {}
var _wrong_attempts: int = 0
var _dragging_source: int = -1
var _drag_end: Vector2 = Vector2.ZERO
var _puzzle_active: bool = false
var _result_shown: bool = false
var _combo_id: String = ""


func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_node_area.draw.connect(_on_node_area_draw)


func start_puzzle(combo_id: String, input_a_id: String, input_b_id: String) -> void:
	_combo_id = combo_id
	_combo_hint_label.text = "%s + %s" % [input_a_id.replace("_", " "), input_b_id.replace("_", " ")]
	_result_label.visible = false
	_score_label.text = "Score: -"

	match DifficultyManager.get_tier_label().to_lower():
		"easy":
			_total_time = 12.0
		"hard":
			_total_time = 6.5
		_:
			_total_time = 9.0

	_remaining_time = _total_time
	_timer_bar.max_value = _total_time
	_timer_bar.value = _total_time

	_setup_nodes()
	_puzzle_active = true
	SfxManager.play("breeding_start")


func _setup_nodes() -> void:
	_sources.clear()
	_sinks.clear()
	_connections.clear()
	_dragging_source = -1
	_wrong_attempts = 0

	var area_size: Vector2 = _node_area.size
	if area_size == Vector2.ZERO:
		area_size = Vector2(360.0, 140.0)

	var source_x: float = NODE_RADIUS + 20.0
	var sink_x: float = area_size.x - NODE_RADIUS - 20.0
	var color_indices: Array[int] = [0, 1, 2]

	for i: int in range(3):
		var y: float = (area_size.y / 4.0) * (i + 1)
		_sources.append({
			"pos": Vector2(source_x, y),
			"color_idx": i,
			"connected": false,
		})

	var sink_order: Array[int] = color_indices.duplicate()
	sink_order.shuffle()
	for i: int in range(3):
		var y: float = (area_size.y / 4.0) * (i + 1)
		_sinks.append({
			"pos": Vector2(sink_x, y),
			"color_idx": sink_order[i],
			"matched": false,
		})

	_node_area.queue_redraw()


func _process(delta: float) -> void:
	if not _puzzle_active:
		return
	_remaining_time -= delta
	_timer_bar.value = _remaining_time
	if _remaining_time <= 0.0:
		_remaining_time = 0.0
		_end_puzzle()


func _end_puzzle() -> void:
	if not _puzzle_active:
		return
	_puzzle_active = false

	var correct: int = _connections.size()
	var total: float = 3.0
	var score: float = clampf(
		(correct / total) * 100.0
		+ (_remaining_time / _total_time) * 20.0
		- float(_wrong_attempts) * 15.0,
		0.0, 100.0
	)

	var tier: int
	var success: bool = true
	if score < TIER_THRESHOLDS[0]:
		tier = -1
		success = false
	elif score < TIER_THRESHOLDS[1]:
		tier = 0
	elif score < TIER_THRESHOLDS[2]:
		tier = 1
	else:
		tier = 2

	_show_result(tier, score, success)

	if success:
		if tier == 0:
			SfxManager.play("breeding_success")
		elif tier >= 1:
			SfxManager.play("crafting_success")
	else:
		SfxManager.play("breeding_critical_fail")

	await get_tree().create_timer(0.4).timeout
	finished.emit(tier, success)
	queue_free()


func _show_result(tier: int, score: float, success: bool) -> void:
	_result_label.visible = true
	_score_label.text = "Score: %.0f" % score
	if not success:
		_result_label.text = "Failure! Inputs lost."
		_result_label.modulate = Color(0.85, 0.25, 0.25, 1.0)
	else:
		_result_label.text = "Result: %s (%.0f%%)" % [QUALITY_LABELS[tier], score]
		_result_label.modulate = QUALITY_COLORS[tier]


func _input(event: InputEvent) -> void:
	if not _puzzle_active:
		return
	if event.is_action_pressed("ui_cancel"):
		_end_puzzle()
		get_viewport().set_input_as_handled()
		return

	var local_event: InputEvent = _node_area.make_input_local(event)

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		var local_pos: Vector2 = _node_area.get_local_mouse_position()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_area_mouse_down(local_pos)
			else:
				_on_area_mouse_up(local_pos)
	elif event is InputEventMouseMotion:
		if _dragging_source >= 0:
			_drag_end = _node_area.get_local_mouse_position()
			_node_area.queue_redraw()

	if local_event != event:
		pass


func _on_area_mouse_down(pos: Vector2) -> void:
	for i: int in range(_sources.size()):
		var src: Dictionary = _sources[i]
		if src["connected"]:
			continue
		if pos.distance_to(src["pos"]) <= NODE_RADIUS:
			_dragging_source = i
			_drag_end = pos
			_node_area.queue_redraw()
			return


func _on_area_mouse_up(pos: Vector2) -> void:
	if _dragging_source < 0:
		return
	var src_idx: int = _dragging_source
	_dragging_source = -1

	for j: int in range(_sinks.size()):
		var snk: Dictionary = _sinks[j]
		if snk["matched"]:
			continue
		if pos.distance_to(snk["pos"]) <= NODE_RADIUS:
			var src_color: int = _sources[src_idx]["color_idx"]
			var snk_color: int = snk["color_idx"]
			if src_color == snk_color:
				_sources[src_idx]["connected"] = true
				_sinks[j]["matched"] = true
				_connections[src_idx] = j
				SfxManager.play("harvest_qte_success")
				_node_area.queue_redraw()
				if _connections.size() >= 3:
					_end_puzzle()
			else:
				_wrong_attempts += 1
				SfxManager.play("harvest_qte_fail")
				_flash_wrong(j)
				_node_area.queue_redraw()
			return

	_node_area.queue_redraw()


func _flash_wrong(sink_idx: int) -> void:
	_sinks[sink_idx]["flash"] = true
	_node_area.queue_redraw()
	await get_tree().create_timer(0.25).timeout
	if sink_idx < _sinks.size():
		_sinks[sink_idx].erase("flash")
		_node_area.queue_redraw()


func _on_node_area_draw() -> void:
	var area: Control = _node_area
	# Draw completed wires
	for src_idx: int in _connections:
		var snk_idx: int = _connections[src_idx]
		var src_pos: Vector2 = _sources[src_idx]["pos"]
		var snk_pos: Vector2 = _sinks[snk_idx]["pos"]
		var col: int = _sources[src_idx]["color_idx"]
		area.draw_line(src_pos, snk_pos, NODE_COLORS[col], WIRE_WIDTH)

	# Draw drag wire
	if _dragging_source >= 0:
		var src_pos: Vector2 = _sources[_dragging_source]["pos"]
		area.draw_line(src_pos, _drag_end, Color(1.0, 1.0, 1.0, 0.6), WIRE_WIDTH)

	# Draw source nodes
	for i: int in range(_sources.size()):
		var src: Dictionary = _sources[i]
		var col: Color = NODE_COLORS[src["color_idx"]]
		if src["connected"]:
			col = col.darkened(0.35)
		area.draw_circle(src["pos"], NODE_RADIUS, col)
		area.draw_arc(src["pos"], NODE_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.6), 1.5)
		area.draw_string(ThemeDB.fallback_font, src["pos"] + Vector2(-4, 4), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.8))

	# Draw sink nodes
	for j: int in range(_sinks.size()):
		var snk: Dictionary = _sinks[j]
		var col: Color = NODE_COLORS[snk["color_idx"]]
		if snk["matched"]:
			col = col.darkened(0.35)
		elif snk.get("flash", false):
			col = Color(1.0, 0.2, 0.2, 1.0)
		area.draw_circle(snk["pos"], NODE_RADIUS, col)
		area.draw_arc(snk["pos"], NODE_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.6), 1.5)


func _exit_tree() -> void:
	_puzzle_active = false
