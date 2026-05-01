class_name DianthusResonanceEvent
extends DaytimeEvent

const CHANNEL_DURATION: float = 6.0
const SHIELD_AMOUNT: int = 40

var _channel_timer: float = 0.0
var _is_channeling: bool = false

@onready var _progress_bar: ColorRect = %ProgressBar
@onready var _progress_bg: ColorRect = %ProgressBg


func _ready() -> void:
	event_id = &"dianthus_resonance"
	event_display_name = "Resonance Bloom"
	event_color = Color(1.0, 0.55, 0.8, 1.0)
	super._ready()


func _on_player_enter() -> void:
	_update_prompt("Hold [E] to channel bloom (6s)")


func _on_player_exit() -> void:
	_cancel_channel()
	_update_prompt("")


func _process(delta: float) -> void:
	if not _is_active or _is_complete:
		return
	if _is_channeling:
		if not _player_in_range or not Input.is_action_pressed("interact"):
			_cancel_channel()
			return
		if _is_moving():
			_cancel_channel()
			_update_prompt("Stand still to channel! Hold [E]")
			return
		_channel_timer += delta
		_update_progress_bar(_channel_timer / CHANNEL_DURATION)
		_update_prompt("Channeling... %.0f%%" % (_channel_timer / CHANNEL_DURATION * 100.0))
		if _channel_timer >= CHANNEL_DURATION:
			_finish_event()


func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not _is_channeling:
		_is_channeling = true
		_channel_timer = 0.0
		_update_progress_bar(0.0)
	elif event.is_action_released("interact") and _is_channeling:
		_cancel_channel()


func _is_moving() -> bool:
	var player: Node = GameManager.player
	if not is_instance_valid(player):
		return false
	if player.has_method("get") and player.get("velocity") != null:
		return (player.get("velocity") as Vector2).length() > 4.0
	return false


func _cancel_channel() -> void:
	_is_channeling = false
	_channel_timer = 0.0
	_update_progress_bar(0.0)
	if _player_in_range:
		_update_prompt("Hold [E] to channel bloom (6s)")


func _give_reward() -> void:
	var core: Node = GameManager.dianthus_core
	if is_instance_valid(core) and core.has_method("heal"):
		core.heal(SHIELD_AMOUNT)
	_show_reward_popup("Core shielded (+%d HP tonight)!" % SHIELD_AMOUNT)
	SfxManager.play("core_heal")


func _update_progress_bar(ratio: float) -> void:
	if not is_instance_valid(_progress_bar) or not is_instance_valid(_progress_bg):
		return
	_progress_bar.size.x = _progress_bg.size.x * clampf(ratio, 0.0, 1.0)
	_progress_bar.visible = ratio > 0.0
	_progress_bg.visible = ratio > 0.0


func _show_reward_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.8, 1.0))
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-64, -32)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(label.queue_free)
