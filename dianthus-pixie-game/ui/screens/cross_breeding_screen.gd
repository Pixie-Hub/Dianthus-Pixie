extends CanvasLayer
class_name CrossBreedingScreen

const SLOT_EMPTY_BG: Color = Color(0.12, 0.08, 0.04, 1.0)
const SLOT_EMPTY_BORDER: Color = Color(0.45, 0.35, 0.15, 1.0)
const SLOT_FILLED_BG: Color = Color(0.15, 0.18, 0.09, 1.0)
const SLOT_FILLED_BORDER: Color = Color(0.45, 0.62, 0.22, 1.0)
const COMBO_KNOWN_COLOR: Color = Color(0.95, 0.90, 0.80, 1.0)
const COMBO_UNKNOWN_COLOR: Color = Color(0.45, 0.40, 0.33, 1.0)
const PICKER_BTN_BG: Color = Color(0.16, 0.10, 0.05, 1.0)
const PICKER_BTN_BORDER: Color = Color(0.38, 0.28, 0.12, 1.0)
const PICKER_BTN_HOVER_BG: Color = Color(0.28, 0.19, 0.09, 1.0)
const PICKER_BTN_HOVER_BORDER: Color = Color(1.0, 0.80, 0.25, 1.0)
const BREED_DELAY: float = 1.5
const MAX_BENCH_DISTANCE: float = 48.0
const MINIGAME_SCENE: String = "res://minigames/plant_experimentation/plant_experimentation_screen.tscn"


static var skip_breeding_minigame: bool = false

@onready var _slot_a_label: Label = %SlotALabel
@onready var _slot_b_label: Label = %SlotBLabel
@onready var _output_label: Label = %OutputLabel
@onready var _combo_list: VBoxContainer = %ComboList
@onready var _breed_button: Button = %BreedButton
@onready var _slot_a_panel: PanelContainer = %SlotA
@onready var _slot_b_panel: PanelContainer = %SlotB
@onready var _item_picker_panel: PanelContainer = %ItemPickerPanel
@onready var _item_picker_list: VBoxContainer = %ItemPickerList

var _slot_a_item: String = ""
var _slot_b_item: String = ""
var _picking_for_slot: String = ""
var _is_breeding: bool = false
var _breed_timer: float = 0.0
var _bench_pos: Vector2 = Vector2(-99999.0, -99999.0)
var _breed_progress: ProgressBar = null
var _minigame_active: bool = false


func _ready() -> void:
	layer = 92
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_breed_button.pressed.connect(_on_breed_pressed)
	BreedingManager.breed_succeeded.connect(_on_breed_succeeded)
	BreedingManager.breed_failed.connect(_on_breed_failed)
	BreedingManager.combo_discovered.connect(_on_combo_discovered)
	_item_picker_panel.visible = false
	_slot_a_panel.gui_input.connect(_on_slot_a_clicked)
	_slot_b_panel.gui_input.connect(_on_slot_b_clicked)
	var switch_btn: Button = find_child("SwitchToCraftingBtn", true, false) as Button
	if switch_btn != null:
		switch_btn.pressed.connect(_on_switch_to_crafting)
	_breed_progress = ProgressBar.new()
	_breed_progress.min_value = 0.0
	_breed_progress.max_value = BREED_DELAY
	_breed_progress.value = 0.0
	_breed_progress.custom_minimum_size = Vector2(0, 8)
	_breed_progress.visible = false
	call_deferred("_insert_breed_progress")


func _insert_breed_progress() -> void:
	if not is_instance_valid(_breed_button) or not is_instance_valid(_breed_progress):
		return
	var parent: Control = _breed_button.get_parent() as Control
	if parent == null:
		return
	parent.add_child(_breed_progress)
	parent.move_child(_breed_progress, _breed_button.get_index() + 1)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _item_picker_panel.visible:
			_item_picker_panel.visible = false
		else:
			close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _is_breeding or not visible:
		return
	if _bench_pos.x > -99998.0 and is_instance_valid(GameManager.player):
		var dist: float = GameManager.player.global_position.distance_to(_bench_pos)
		if dist > MAX_BENCH_DISTANCE:
			_cancel_breeding()
			_show_breed_feedback("Too far!")
			return
	_breed_timer += delta
	if is_instance_valid(_breed_progress):
		_breed_progress.value = _breed_timer
	if _breed_timer >= BREED_DELAY:
		_finish_breeding()


func open() -> void:
	SfxManager.play("screen_open")
	visible = true
	var bench: Node = get_tree().current_scene.find_child("BreedingBench", true, false)
	if bench is Node2D:
		_bench_pos = (bench as Node2D).global_position
	else:
		_bench_pos = Vector2(-99999.0, -99999.0)
	_refresh_slots()
	_refresh_combo_list()


func close() -> void:
	SfxManager.play("screen_close")
	_cancel_breeding()
	visible = false
	_item_picker_panel.visible = false


func _on_slot_a_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_picking_for_slot = "a"
		_open_item_picker()


func _on_slot_b_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_picking_for_slot = "b"
		_open_item_picker()


func _open_item_picker() -> void:
	SfxManager.play("screen_open")
	for child in _item_picker_list.get_children():
		child.queue_free()
	var has_items: bool = false
	for i: int in range(InventoryManager.get_max_slots()):
		var slot: Dictionary = InventoryManager.get_slot(i)
		if slot.is_empty():
			continue
		var item_id: String = str(slot.get("item_id", ""))
		var count: int = int(slot.get("count", 0))
		if item_id.is_empty() or count <= 0:
			continue
		has_items = true
		var btn: Button = Button.new()
		btn.text = "%s x%d" % [ItemDatabase.get_display_name(item_id), count]
		btn.add_theme_font_size_override("font_size", 9)
		btn.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80, 1.0))
		var btn_normal: StyleBoxFlat = StyleBoxFlat.new()
		btn_normal.bg_color = PICKER_BTN_BG
		btn_normal.border_width_left = 1
		btn_normal.border_width_right = 1
		btn_normal.border_width_bottom = 1
		btn_normal.border_color = PICKER_BTN_BORDER
		btn_normal.corner_radius_top_left = 2
		btn_normal.corner_radius_top_right = 2
		btn_normal.corner_radius_bottom_right = 2
		btn_normal.corner_radius_bottom_left = 2
		var btn_hover: StyleBoxFlat = StyleBoxFlat.new()
		btn_hover.bg_color = PICKER_BTN_HOVER_BG
		btn_hover.border_width_left = 1
		btn_hover.border_width_right = 1
		btn_hover.border_width_bottom = 1
		btn_hover.border_color = PICKER_BTN_HOVER_BORDER
		btn_hover.corner_radius_top_left = 2
		btn_hover.corner_radius_top_right = 2
		btn_hover.corner_radius_bottom_right = 2
		btn_hover.corner_radius_bottom_left = 2
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_normal)
		var capture_id: String = item_id
		btn.pressed.connect(func() -> void: _select_item(capture_id))
		_item_picker_list.add_child(btn)
	if not has_items:
		var lbl: Label = Label.new()
		lbl.text = "(No items)"
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.50, 0.45, 0.38, 1.0))
		_item_picker_list.add_child(lbl)
	_item_picker_panel.visible = true


func _select_item(item_id: String) -> void:
	SfxManager.play("ui_button_click")
	if _picking_for_slot == "a":
		_slot_a_item = item_id
	else:
		_slot_b_item = item_id
	_item_picker_panel.visible = false
	_picking_for_slot = ""
	_refresh_slots()


func _refresh_slots() -> void:
	_slot_a_label.text = ItemDatabase.get_display_name(_slot_a_item) if not _slot_a_item.is_empty() else "?"
	_slot_b_label.text = ItemDatabase.get_display_name(_slot_b_item) if not _slot_b_item.is_empty() else "?"
	_update_slot_style(_slot_a_panel, not _slot_a_item.is_empty())
	_update_slot_style(_slot_b_panel, not _slot_b_item.is_empty())
	_refresh_output()


func _update_slot_style(panel: PanelContainer, filled: bool) -> void:
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = SLOT_FILLED_BG if filled else SLOT_EMPTY_BG
	style.border_color = SLOT_FILLED_BORDER if filled else SLOT_EMPTY_BORDER


func _refresh_output() -> void:
	if _slot_a_item.is_empty() or _slot_b_item.is_empty():
		_output_label.text = "?"
		_breed_button.disabled = true
		return
	var combo_id: String = BreedingManager.find_combo(_slot_a_item, _slot_b_item)
	if not combo_id.is_empty() and BreedingManager.is_discovered(combo_id):
		_output_label.text = BreedingManager.get_display_name(combo_id)
	else:
		_output_label.text = "?"
	_breed_button.disabled = not BreedingManager.can_breed(_slot_a_item, _slot_b_item)


func _refresh_combo_list() -> void:
	for child in _combo_list.get_children():
		child.queue_free()
	for combo_id: String in BreedingManager.get_all_combo_ids():
		var combo: Dictionary = BreedingManager.get_combo(combo_id)
		var discovered: bool = BreedingManager.is_discovered(combo_id)
		var lbl: Label = Label.new()
		lbl.add_theme_font_size_override("font_size", 9)
		if discovered:
			var ia: String = ItemDatabase.get_display_name(str(combo.get("input_a", "")))
			var ib: String = ItemDatabase.get_display_name(str(combo.get("input_b", "")))
			lbl.text = "%s + %s → %s" % [ia, ib, str(combo.get("display_name", combo_id))]
			lbl.add_theme_color_override("font_color", COMBO_KNOWN_COLOR)
		else:
			lbl.text = "??? + ??? → ???"
			lbl.add_theme_color_override("font_color", COMBO_UNKNOWN_COLOR)
		_combo_list.add_child(lbl)


func _on_breed_pressed() -> void:
	if _slot_a_item.is_empty() or _slot_b_item.is_empty():
		return
	if _is_breeding:
		_cancel_breeding()
		return
	if not BreedingManager.can_breed(_slot_a_item, _slot_b_item):
		return
	# Determine if we should skip the minigame.
	var tutorial_done: bool = UnlockFlags.has_flag("flag_tutorial_complete")
	var should_skip: bool = tutorial_done and CrossBreedingScreen.skip_breeding_minigame
	if should_skip:
		# Skip path: 1.5 s progress bar → Biasa.
		_is_breeding = true
		_breed_timer = 0.0
		if is_instance_valid(_breed_progress):
			_breed_progress.value = 0.0
			_breed_progress.visible = true
		_breed_button.text = "CANCEL"
		_breed_button.disabled = false
	else:
		# Minigame path.
		_minigame_active = true
		_breed_button.disabled = true
		var combo_id: String = BreedingManager.find_combo(_slot_a_item, _slot_b_item)
		var mgScene: PackedScene = load(MINIGAME_SCENE) as PackedScene
		if mgScene == null:
			push_warning("[CrossBreeding] Could not load PlantExperimentationScreen scene.")
			_minigame_active = false
			return
		var mg: Node = mgScene.instantiate()
		get_tree().root.add_child(mg)
		if mg.has_method("start_puzzle"):
			mg.start_puzzle(combo_id, _slot_a_item, _slot_b_item)
		if mg.has_signal("finished"):
			mg.finished.connect(_on_experiment_finished, CONNECT_ONE_SHOT)


func _cancel_breeding() -> void:
	if not _is_breeding:
		return
	_is_breeding = false
	_breed_timer = 0.0
	if is_instance_valid(_breed_progress):
		_breed_progress.visible = false
		_breed_progress.value = 0.0
	_breed_button.text = "BREED"
	_breed_button.disabled = _slot_a_item.is_empty() or _slot_b_item.is_empty() or not BreedingManager.can_breed(_slot_a_item, _slot_b_item)


func _finish_breeding(quality_tier: int = 0) -> void:
	_is_breeding = false
	_breed_timer = 0.0
	if is_instance_valid(_breed_progress):
		_breed_progress.visible = false
	BreedingManager.breed(_slot_a_item, _slot_b_item, quality_tier)


func _on_experiment_finished(quality: int, success: bool) -> void:
	_minigame_active = false
	_breed_button.disabled = false
	if success:
		BreedingManager.breed(_slot_a_item, _slot_b_item, quality)
	else:
		# Failure: consume both inputs without producing a seed.
		if InventoryManager.has_item(_slot_a_item, 1):
			InventoryManager.remove_item(_slot_a_item, 1)
		if InventoryManager.has_item(_slot_b_item, 1):
			InventoryManager.remove_item(_slot_b_item, 1)
		_show_breed_feedback("Failed!")
		_slot_a_item = ""
		_slot_b_item = ""
		_refresh_slots()


func _on_breed_succeeded(_combo_id: String, result_item_id: String, _quality_tier: int) -> void:
	_output_label.text = ItemDatabase.get_display_name(result_item_id)
	_show_breed_feedback("Success!")
	_slot_a_item = ""
	_slot_b_item = ""
	_refresh_slots()
	_refresh_combo_list()


func _on_breed_failed(_reason: String) -> void:
	_show_breed_feedback("Failed!")
	_output_label.add_theme_color_override("font_color", Color(0.85, 0.30, 0.25, 1.0))
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void: _output_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80, 1.0)))
	_slot_a_item = ""
	_slot_b_item = ""
	_refresh_slots()


func _on_combo_discovered(_combo_id: String) -> void:
	_refresh_combo_list()


func _show_breed_feedback(msg: String) -> void:
	_breed_button.text = msg
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void: _breed_button.text = "BREED")


func _on_switch_to_crafting() -> void:
	close()
	var screen: Node = get_tree().current_scene.find_child("CraftingScreen", true, false)
	if screen != null and screen.has_method("open"):
		screen.open()
