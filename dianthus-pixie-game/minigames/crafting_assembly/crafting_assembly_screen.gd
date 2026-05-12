extends CanvasLayer
class_name CraftingAssemblyScreen

signal finished(quality_tier: int, success: bool)

const SLOT_SCENE: PackedScene = preload("res://minigames/crafting_assembly/component_slot.tscn")
const DIFFICULTY_DURATIONS: Dictionary = {
	DifficultyManager.Tier.EASY: 12.0,
	DifficultyManager.Tier.NORMAL: 9.0,
	DifficultyManager.Tier.HARD: 6.5,
}
const COMPONENT_COLORS: Array[Color] = [
	Color(0.72, 0.28, 0.22, 1.0),
	Color(0.22, 0.52, 0.78, 1.0),
	Color(0.78, 0.66, 0.22, 1.0),
	Color(0.30, 0.62, 0.28, 1.0),
	Color(0.62, 0.34, 0.76, 1.0),
]
const FAIL_THRESHOLD: int = 30
const PERFECT_THRESHOLD: int = 90
const WRONG_ATTEMPT_PENALTY: float = 15.0

@onready var _recipe_hint_label: Label = %RecipeHintLabel
@onready var _target_row: HBoxContainer = %TargetRow
@onready var _component_row: HBoxContainer = %ComponentRow
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _score_label: Label = %ScoreLabel
@onready var _result_label: Label = %ResultLabel

var _recipe_id: String = ""
var _total_time: float = 9.0
var _remaining_time: float = 0.0
var _wrong_attempts: int = 0
var _correct_drops: int = 0
var _puzzle_active: bool = false
var _held_slot: CraftingAssemblyComponentSlot = null
var _focus_row: int = 1
var _focus_index: int = 0
var _target_slots: Array[CraftingAssemblyComponentSlot] = []
var _component_slots: Array[CraftingAssemblyComponentSlot] = []


func _ready() -> void:
	layer = 97
	process_mode = Node.PROCESS_MODE_ALWAYS
	_result_label.visible = false


func start_assembly(recipe_id: String) -> void:
	_recipe_id = recipe_id
	_recipe_hint_label.text = RecipeDatabase.get_display_name(recipe_id)
	_result_label.visible = false
	_wrong_attempts = 0
	_correct_drops = 0
	_held_slot = null
	_focus_row = 1
	_focus_index = 0
	_total_time = _get_duration_for_current_difficulty()
	_remaining_time = _total_time
	_timer_bar.max_value = _total_time
	_timer_bar.value = _total_time
	_setup_puzzle(recipe_id)
	_update_score_label()
	_update_focus()
	_puzzle_active = true
	SfxManager.play("screen_open")


func cancel() -> void:
	if not _puzzle_active:
		return
	_end_puzzle(true)


func _process(delta: float) -> void:
	if not _puzzle_active:
		return
	_remaining_time = maxf(_remaining_time - delta, 0.0)
	_timer_bar.value = _remaining_time
	_update_score_label()
	if _remaining_time <= 0.0:
		_end_puzzle(false)


func _unhandled_input(event: InputEvent) -> void:
	if not _puzzle_active:
		return
	if event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_accept_focused_slot()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left"):
		_move_focus(Vector2i(-1, 0))
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right"):
		_move_focus(Vector2i(1, 0))
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		_move_focus(Vector2i(0, -1))
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down"):
		_move_focus(Vector2i(0, 1))
		get_viewport().set_input_as_handled()


func _setup_puzzle(recipe_id: String) -> void:
	_clear_row(_target_row)
	_clear_row(_component_row)
	_target_slots.clear()
	_component_slots.clear()

	var materials: Dictionary = RecipeDatabase.get_materials(recipe_id)
	var material_ids: Array[String] = []
	for item_id: String in materials:
		material_ids.append(item_id)

	var target_ids: Array[String] = material_ids.duplicate()
	if DifficultyManager.get_tier_id() == DifficultyManager.Tier.HARD:
		target_ids.shuffle()
	for item_id: String in target_ids:
		var target_slot: CraftingAssemblyComponentSlot = SLOT_SCENE.instantiate() as CraftingAssemblyComponentSlot
		_target_row.add_child(target_slot)
		target_slot.configure(
			CraftingAssemblyComponentSlot.ROLE_TARGET,
			item_id,
			_abbreviate_item(item_id),
			_color_for_item(item_id)
		)
		target_slot.gui_input.connect(_on_slot_gui_input.bind(target_slot))
		_target_slots.append(target_slot)

	var component_ids: Array[String] = material_ids.duplicate()
	component_ids.shuffle()
	if component_ids.size() == material_ids.size() and component_ids.size() > 1 and component_ids == material_ids:
		var first: String = component_ids.pop_front()
		component_ids.append(first)
	for item_id: String in component_ids:
		_add_component_slot(item_id, false)

	if DifficultyManager.get_tier_id() == DifficultyManager.Tier.HARD:
		_add_component_slot("__decoy__", true)


func _add_component_slot(item_id: String, is_decoy: bool) -> void:
	var slot: CraftingAssemblyComponentSlot = SLOT_SCENE.instantiate() as CraftingAssemblyComponentSlot
	_component_row.add_child(slot)
	var label: String = "??" if is_decoy else _abbreviate_item(item_id)
	var color: Color = Color(0.90, 0.16, 0.18, 1.0) if is_decoy else _color_for_item(item_id)
	slot.configure(CraftingAssemblyComponentSlot.ROLE_COMPONENT, item_id, label, color, is_decoy)
	slot.gui_input.connect(_on_slot_gui_input.bind(slot))
	_component_slots.append(slot)


func _on_slot_gui_input(event: InputEvent, slot: CraftingAssemblyComponentSlot) -> void:
	if not _puzzle_active:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			return
		_select_slot(slot)
		get_viewport().set_input_as_handled()


func _select_slot(slot: CraftingAssemblyComponentSlot) -> void:
	if slot.role == CraftingAssemblyComponentSlot.ROLE_COMPONENT:
		if slot.locked:
			return
		_held_slot = slot
		SfxManager.play("ui_button_click")
		_set_focus_to_slot(slot)
		_update_focus()
		return
	if slot.role == CraftingAssemblyComponentSlot.ROLE_TARGET and _held_slot != null:
		_attempt_drop(slot)


func _accept_focused_slot() -> void:
	var slot: CraftingAssemblyComponentSlot = _get_focused_slot()
	if slot != null:
		_select_slot(slot)


func _attempt_drop(target_slot: CraftingAssemblyComponentSlot) -> void:
	if target_slot.filled:
		return
	if _held_slot == null:
		return
	if not _held_slot.is_decoy and _held_slot.material_id == target_slot.material_id:
		target_slot.mark_filled()
		_held_slot.mark_removed()
		_held_slot = null
		_correct_drops += 1
		SfxManager.play("harvest_qte_success")
		if _correct_drops >= _target_slots.size():
			_end_puzzle(false)
	else:
		_wrong_attempts += 1
		SfxManager.play("harvest_qte_fail")
		target_slot.flash_wrong()
		if _held_slot.is_decoy:
			_held_slot.mark_removed()
			_held_slot = null
	_update_score_label()


func _end_puzzle(cancelled: bool) -> void:
	if not _puzzle_active:
		return
	_puzzle_active = false
	var score: float = 0.0 if cancelled else _calculate_score()
	var quality_tier: int = 0
	var success: bool = score >= FAIL_THRESHOLD
	if not success:
		quality_tier = -1
	elif score >= PERFECT_THRESHOLD:
		quality_tier = 1
	else:
		quality_tier = 0
	_show_result(quality_tier, score, success)
	if success:
		SfxManager.play("crafting_success")
		if quality_tier == 1:
			SfxManager.play("combo_discovered") # TODO: SFX - dedicated Perfect assembly cue.
	else:
		SfxManager.play("crafting_fail")
	await get_tree().create_timer(0.4).timeout
	finished.emit(quality_tier, success)
	SfxManager.play("screen_close")
	queue_free()


func _show_result(quality_tier: int, score: float, success: bool) -> void:
	_result_label.visible = true
	_score_label.text = "Score: %.0f" % score
	if not success:
		_result_label.text = "Assembly failed. Materials consumed."
		_result_label.modulate = Color(0.85, 0.25, 0.25, 1.0)
	elif quality_tier == 1:
		_result_label.text = "Perfect assembly! Weapon quality +10%."
		_result_label.modulate = Color(1.0, 0.80, 0.25, 1.0)
	else:
		_result_label.text = "Standard assembly complete."
		_result_label.modulate = Color(0.95, 0.90, 0.80, 1.0)


func _calculate_score() -> float:
	var total_targets: int = max(_target_slots.size(), 1)
	var base: float = (float(_correct_drops) / float(total_targets)) * 100.0
	var time_bonus: float = (_remaining_time / _total_time) * 20.0 if _total_time > 0.0 else 0.0
	var errors: float = float(_wrong_attempts) * WRONG_ATTEMPT_PENALTY
	return clampf(base + time_bonus - errors, 0.0, 100.0)


func _update_score_label() -> void:
	_score_label.text = "Score: %.0f" % _calculate_score()


func _move_focus(delta: Vector2i) -> void:
	_focus_row = clampi(_focus_row + delta.y, 0, 1)
	var row_size: int = _target_slots.size() if _focus_row == 0 else _component_slots.size()
	_focus_index = clampi(_focus_index + delta.x, 0, max(row_size - 1, 0))
	_update_focus()


func _update_focus() -> void:
	for slot: CraftingAssemblyComponentSlot in _target_slots:
		slot.set_focus_state(false)
	for slot: CraftingAssemblyComponentSlot in _component_slots:
		slot.set_focus_state(false)
	var focused: CraftingAssemblyComponentSlot = _get_focused_slot()
	if focused != null:
		focused.set_focus_state(true)


func _get_focused_slot() -> CraftingAssemblyComponentSlot:
	var row: Array[CraftingAssemblyComponentSlot] = _target_slots if _focus_row == 0 else _component_slots
	if row.is_empty():
		return null
	_focus_index = clampi(_focus_index, 0, row.size() - 1)
	return row[_focus_index]


func _set_focus_to_slot(slot: CraftingAssemblyComponentSlot) -> void:
	var target_idx: int = _target_slots.find(slot)
	if target_idx >= 0:
		_focus_row = 0
		_focus_index = target_idx
		return
	var component_idx: int = _component_slots.find(slot)
	if component_idx >= 0:
		_focus_row = 1
		_focus_index = component_idx


func _clear_row(row: Control) -> void:
	for child: Node in row.get_children():
		child.queue_free()


func _get_duration_for_current_difficulty() -> float:
	var tier_id: int = DifficultyManager.get_tier_id()
	return float(DIFFICULTY_DURATIONS.get(tier_id, DIFFICULTY_DURATIONS[DifficultyManager.Tier.NORMAL]))


func _color_for_item(item_id: String) -> Color:
	var idx: int = absi(hash(item_id)) % COMPONENT_COLORS.size()
	return COMPONENT_COLORS[idx]


func _abbreviate_item(item_id: String) -> String:
	var parts: PackedStringArray = item_id.split("_")
	var letters: PackedStringArray = PackedStringArray()
	for part: String in parts:
		if not part.is_empty():
			letters.append(part.substr(0, 1).to_upper())
	return "".join(letters).substr(0, 3)


func _exit_tree() -> void:
	_puzzle_active = false
