extends CanvasLayer

signal finished(success: bool)

const DIFFICULTY_WINDOWS: Dictionary = {
	DifficultyManager.Tier.EASY: 1.6,
	DifficultyManager.Tier.NORMAL: 1.2,
	DifficultyManager.Tier.HARD: 0.85,
}

@onready var _prompt_label: Label = %PromptLabel
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _result_label: Label = %ResultLabel

var _item_id: String = ""
var _amount: int = 1
var _duration: float = 1.2
var _remaining: float = 0.0
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
	_duration = _get_window_for_current_difficulty()
	_remaining = _duration
	_active = true
	visible = true
	_prompt_label.text = "Press E to harvest %s!" % ItemDatabase.get_display_name(_item_id)
	_result_label.text = ""
	_timer_bar.max_value = _duration
	_timer_bar.value = _duration
	SfxManager.play("harvest_qte_prompt")
	PauseManager.request_pause(self)
	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return
	_remaining = maxf(_remaining - delta, 0.0)
	_timer_bar.value = _remaining
	if _remaining <= 0.0:
		_complete(false)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_complete(true)


func _complete(success: bool) -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	if success:
		_result_label.text = "Harvest secured!"
		SfxManager.play("harvest_qte_success")
	else:
		_result_label.text = "Harvest reduced!"
		SfxManager.play("harvest_qte_fail")
	PauseManager.release_pause(self)
	finished.emit(success)
	await get_tree().create_timer(0.25, true).timeout
	queue_free()


func _get_window_for_current_difficulty() -> float:
	var tier_id: int = DifficultyManager.get_tier_id()
	return float(DIFFICULTY_WINDOWS.get(tier_id, DIFFICULTY_WINDOWS[DifficultyManager.Tier.NORMAL]))


func _ensure_node_refs() -> void:
	if _prompt_label == null:
		_prompt_label = get_node("Panel/MarginContainer/VBoxContainer/PromptLabel") as Label
	if _timer_bar == null:
		_timer_bar = get_node("Panel/MarginContainer/VBoxContainer/TimerBar") as ProgressBar
	if _result_label == null:
		_result_label = get_node("Panel/MarginContainer/VBoxContainer/ResultLabel") as Label


func _exit_tree() -> void:
	if _active:
		PauseManager.release_pause(self)
