class_name WildSeedlingEvent
extends DaytimeEvent

const HOLD_DURATION: float = 4.0

var _hold_timer: float = 0.0
var _is_holding: bool = false

@onready var _progress_bar: ColorRect = %ProgressBar
@onready var _progress_bg: ColorRect = %ProgressBg


func _ready() -> void:
	event_id = &"wild_seedling"
	event_display_name = "Wild Seedling"
	event_color = Color(0.2, 0.85, 0.4, 1.0)
	super._ready()


func _on_player_enter() -> void:
	_update_prompt("Hold [E] to rescue seedling (4s)")


func _on_player_exit() -> void:
	_cancel_hold()
	_update_prompt("")


func _process(delta: float) -> void:
	if not _is_active or _is_complete:
		return
	if _is_holding:
		if not _player_in_range or not Input.is_action_pressed("interact"):
			_cancel_hold()
			return
		_hold_timer += delta
		_update_progress_bar(_hold_timer / HOLD_DURATION)
		_update_prompt("Hold [E] ... %.0f%%" % (_hold_timer / HOLD_DURATION * 100.0))
		if _hold_timer >= HOLD_DURATION:
			_finish_event()


func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not _is_holding:
		_is_holding = true
		_hold_timer = 0.0
		_update_progress_bar(0.0)
	elif event.is_action_released("interact") and _is_holding:
		_cancel_hold()


func _cancel_hold() -> void:
	_is_holding = false
	_hold_timer = 0.0
	_update_progress_bar(0.0)
	if _player_in_range:
		_update_prompt("Hold [E] to rescue seedling (4s)")


func _give_reward() -> void:
	var seed_id: String = _pick_seed()
	InventoryManager.add_item(seed_id, 1)
	var item_name: String = ItemDatabase.get_display_name(seed_id)
	_show_reward_popup("Received: %s" % item_name)
	QuestManager.report_event(&"item_collected", {item_id = seed_id, amount = 1})


func _pick_seed() -> String:
	var all_seeds: Array[String] = [
		"bougainvillea_seed", "rafflesia_seed", "melati_seed",
		"wijaya_kusuma_seed", "beringin_seed", "kecombrang_seed", "kunyit_seed",
	]
	var undiscovered: Array[String] = []
	for s: String in all_seeds:
		var plant_id: String = s.trim_suffix("_seed")
		if not CodexManager.is_plant_discovered(plant_id):
			undiscovered.append(s)
	if not undiscovered.is_empty():
		return undiscovered[randi() % undiscovered.size()]
	return all_seeds[randi() % all_seeds.size()]


func _update_progress_bar(ratio: float) -> void:
	if not is_instance_valid(_progress_bar) or not is_instance_valid(_progress_bg):
		return
	_progress_bar.size.x = _progress_bg.size.x * clampf(ratio, 0.0, 1.0)
	_progress_bar.visible = ratio > 0.0
	_progress_bg.visible = ratio > 0.0


func _show_reward_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-48, -32)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(label.queue_free)
