class_name WildSeedlingEvent
extends DaytimeEvent

const HOLD_DURATION: float = 4.0

var _hold_timer: float = 0.0
var _is_holding: bool = false

func _ready() -> void:
	event_id = &"wild_seedling"
	event_display_name = "Wild Seedling"
	event_color = Color(0.2, 0.85, 0.4, 1.0)
	super._ready()


func _on_player_enter() -> void:
	_update_prompt("Hold [E] to rescue seedling\nReward: Rare plant seed")


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
		_update_prompt("Rescuing seedling... %.0f%%\nRelease [E] to cancel" % (_hold_timer / HOLD_DURATION * 100.0))
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
		_update_prompt("Hold [E] to rescue seedling\nReward: Rare plant seed")


func _give_reward() -> void:
	var seed_id: String = _pick_seed()
	InventoryManager.add_item(seed_id, 1)
	var item_name: String = ItemDatabase.get_display_name(seed_id)
	_show_reward_popup("Received: %s" % item_name)
	QuestManager.report_event(&"item_collected", 1, {item_id = seed_id})


func _pick_seed() -> String:
	# Day gates match acquisition table in PLANT_CODEX.md.
	# Rare seeds (kecombrang, kunyit) unlock at Day 7+ (Ruins of Veld parity).
	# Mid-game seeds (melati, wijaya_kusuma, beringin) unlock at Day 3+ (Dusk Forest parity).
	const SEED_DAY_GATE: Dictionary = {
		"bougainvillea_seed": 1,
		"rafflesia_seed": 1,
		"melati_seed": 3,
		"wijaya_kusuma_seed": 3,
		"beringin_seed": 3,
		"kecombrang_seed": 7,
		"kunyit_seed": 7,
	}
	var day: int = DayNightCycle.day_count
	var eligible: Array[String] = []
	for s: String in SEED_DAY_GATE.keys():
		if day >= int(SEED_DAY_GATE[s]):
			eligible.append(s)
	if eligible.is_empty():
		eligible = ["bougainvillea_seed", "rafflesia_seed"]
	var undiscovered: Array[String] = []
	for s: String in eligible:
		if not CodexManager.is_plant_discovered(s.trim_suffix("_seed")):
			undiscovered.append(s)
	if not undiscovered.is_empty():
		return undiscovered[randi() % undiscovered.size()]
	return eligible[randi() % eligible.size()]


func _update_progress_bar(ratio: float) -> void:
	_set_prompt_progress(ratio)


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
