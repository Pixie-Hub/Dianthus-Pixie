extends CanvasLayer

signal finished(success: bool)

const DIFFICULTY_DURATIONS: Dictionary = {
	DifficultyManager.Tier.EASY: 5.0,
	DifficultyManager.Tier.NORMAL: 4.5,
	DifficultyManager.Tier.HARD: 4.0,
}
const DIFFICULTY_TARGET_WIDTHS: Dictionary = {
	DifficultyManager.Tier.EASY: 0.34,
	DifficultyManager.Tier.NORMAL: 0.26,
	DifficultyManager.Tier.HARD: 0.18,
}
const INDICATOR_WIDTH: float = 4.0
const STARTING_INDICATOR_POSITION: float = 0.5
const RESULT_SUCCESS_COLOR: Color = Color(0.8, 1.0, 0.62, 1.0)
const RESULT_FAIL_COLOR: Color = Color(1.0, 0.25, 0.25, 1.0)

@export_range(0.1, 2.0, 0.05) var space_pull_speed: float = 0.9
@export_range(0.1, 2.0, 0.05) var release_slide_speed: float = 0.72
@export_range(0.1, 2.0, 0.05) var target_move_speed: float = 0.58
@export_range(0.1, 1.0, 0.05) var uncommon_target_move_speed_multiplier: float = 0.65

@onready var _prompt_label: Label = %PromptLabel
@onready var _balance_bar: Control = %BalanceBar
@onready var _target_zone: ColorRect = %TargetZone
@onready var _indicator_line: ColorRect = %IndicatorLine
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _result_label: Label = %ResultLabel

var _item_id: String = ""
var _amount: int = 1
var _duration: float = 4.5
var _remaining: float = 0.0
var _target_width: float = 0.26
var _target_left: float = 0.37
var _target_direction: float = 1.0
var _current_target_move_speed: float = 0.58
var _indicator_position: float = STARTING_INDICATOR_POSITION
var _active: bool = false


func _ready() -> void:
	_ensure_node_refs()
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _active:
		visible = false
		set_process(false)


func start_qte(item_id: String, amount: int) -> void:
	_ensure_node_refs()
	_item_id = item_id
	_amount = amount
	_duration = _get_duration_for_current_difficulty()
	_remaining = _duration
	_target_width = _get_target_width_for_current_difficulty()
	_target_left = (1.0 - _target_width) * 0.5
	_target_direction = 1.0
	_current_target_move_speed = _get_target_move_speed_for_item(_item_id)
	_indicator_position = STARTING_INDICATOR_POSITION
	_active = true
	visible = true
	_prompt_label.text = "Hold Space to balance %s" % ItemDatabase.get_display_name(_item_id)
	_result_label.text = ""
	_timer_bar.max_value = _duration
	_timer_bar.value = _duration
	_update_balance_bar()
	SfxManager.play("harvest_qte_prompt")
	PauseManager.request_pause(self)
	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return
	_remaining = maxf(_remaining - delta, 0.0)
	_timer_bar.value = _remaining
	_move_target(delta)
	_move_indicator(delta)
	_update_balance_bar()
	if _remaining <= 0.0:
		_complete(_is_indicator_in_target())


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()


func _complete(success: bool) -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	if success:
		_result_label.text = "Harvest secured!"
		_result_label.add_theme_color_override("font_color", RESULT_SUCCESS_COLOR)
		SfxManager.play("harvest_qte_success")
	else:
		_result_label.text = "Harvest reduced!"
		_result_label.add_theme_color_override("font_color", RESULT_FAIL_COLOR)
		SfxManager.play("harvest_qte_fail")
	PauseManager.release_pause(self)
	finished.emit(success)
	await get_tree().create_timer(0.25, true).timeout
	queue_free()


func _move_target(delta: float) -> void:
	var max_left: float = 1.0 - _target_width
	_target_left += _target_direction * _current_target_move_speed * delta
	if _target_left >= max_left:
		_target_left = max_left
		_target_direction = -1.0
	elif _target_left <= 0.0:
		_target_left = 0.0
		_target_direction = 1.0


func _move_indicator(delta: float) -> void:
	var movement: float = space_pull_speed if Input.is_key_pressed(KEY_SPACE) else -release_slide_speed
	_indicator_position = clampf(_indicator_position + movement * delta, 0.0, 1.0)


func _update_balance_bar() -> void:
	if _balance_bar == null or _target_zone == null or _indicator_line == null:
		return
	var bar_size: Vector2 = _balance_bar.size
	if bar_size.x <= 0.0 or bar_size.y <= 0.0:
		return
	var target_x: float = roundf(_target_left * bar_size.x)
	var target_width_px: float = roundf(_target_width * bar_size.x)
	_target_zone.position = Vector2(target_x, 0.0)
	_target_zone.size = Vector2(target_width_px, bar_size.y)

	var indicator_x: float = roundf(_indicator_position * bar_size.x - INDICATOR_WIDTH * 0.5)
	_indicator_line.position = Vector2(indicator_x, -3.0)
	_indicator_line.size = Vector2(INDICATOR_WIDTH, bar_size.y + 6.0)


func _is_indicator_in_target() -> bool:
	return _indicator_position >= _target_left and _indicator_position <= _target_left + _target_width


func _get_duration_for_current_difficulty() -> float:
	var tier_id: int = DifficultyManager.get_tier_id()
	return float(DIFFICULTY_DURATIONS.get(tier_id, DIFFICULTY_DURATIONS[DifficultyManager.Tier.NORMAL]))


func _get_target_width_for_current_difficulty() -> float:
	var tier_id: int = DifficultyManager.get_tier_id()
	return float(DIFFICULTY_TARGET_WIDTHS.get(tier_id, DIFFICULTY_TARGET_WIDTHS[DifficultyManager.Tier.NORMAL]))


func _get_target_move_speed_for_item(item_id: String) -> float:
	if ItemDatabase.get_rarity(item_id) == ItemDatabase.Rarity.UNCOMMON:
		return target_move_speed * uncommon_target_move_speed_multiplier
	return target_move_speed


func _ensure_node_refs() -> void:
	if _prompt_label == null:
		_prompt_label = get_node("Panel/MarginContainer/VBoxContainer/PromptLabel") as Label
	if _balance_bar == null:
		_balance_bar = get_node("Panel/MarginContainer/VBoxContainer/BalanceBar") as Control
	if _target_zone == null:
		_target_zone = get_node("Panel/MarginContainer/VBoxContainer/BalanceBar/TargetZone") as ColorRect
	if _indicator_line == null:
		_indicator_line = get_node("Panel/MarginContainer/VBoxContainer/BalanceBar/IndicatorLine") as ColorRect
	if _timer_bar == null:
		_timer_bar = get_node("Panel/MarginContainer/VBoxContainer/TimerBar") as ProgressBar
	if _result_label == null:
		_result_label = get_node("Panel/MarginContainer/VBoxContainer/ResultLabel") as Label


func _exit_tree() -> void:
	if _active:
		PauseManager.release_pause(self)
