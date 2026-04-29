extends Node

signal phase_started(phase_id: StringName)
signal phase_completed(phase_id: StringName)
signal objective_updated(objective_id: StringName, completed: bool)
signal tutorial_visibility_changed(enabled: bool)

enum TutorialState {
	NOT_STARTED,
	DAY_1_MOVEMENT,
	DAY_1_MOVEMENT_COMPLETE,
	DISABLED,
}

const PROGRESS_PATH: String = "user://tutorial_progress.cfg"
const PHASE_DAY_1_MOVEMENT: StringName = &"tutorial_day1_movement"
const MOVEMENT_REQUIRED_SECONDS: float = 5.0
const TIMELINE_ACCESS_03: String = "access_03_tutorial"
const LABEL_DAY_1_MOVEMENT: String = "day_1_movement"

var tutorial_enabled: bool = true
var current_state: int = TutorialState.NOT_STARTED
var movement_seconds: float = 0.0
var moved_enough: bool = false
var inventory_opened: bool = false
var resource_collected: bool = false

var _reported_movement: bool = false
var _hud_layer: CanvasLayer = null
var _panel: PanelContainer = null
var _phase_label: Label = null
var _move_label: Label = null
var _inventory_label: Label = null
var _resource_label: Label = null
var _progress_bar: ProgressBar = null
var _core_glow_active: bool = false
var _progress_save_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_progress()
	InventoryManager.item_added.connect(_on_item_added)
	SaveManager.load_completed.connect(_on_load_completed)
	call_deferred("_sync_active_phase_with_scene")


func _process(delta: float) -> void:
	if current_state == TutorialState.NOT_STARTED:
		_try_start_day_1_movement()
	elif current_state == TutorialState.DAY_1_MOVEMENT:
		_update_movement_progress(delta)
		_progress_save_timer += delta
		if _progress_save_timer >= 1.0:
			_progress_save_timer = 0.0
			_save_progress()
		_refresh_phase_1_ui()
		_check_phase_1_complete()


func reset_progress_for_new_game() -> void:
	var keep_enabled: bool = tutorial_enabled
	tutorial_enabled = keep_enabled
	current_state = TutorialState.NOT_STARTED if tutorial_enabled else TutorialState.DISABLED
	movement_seconds = 0.0
	moved_enough = false
	inventory_opened = false
	resource_collected = false
	_reported_movement = false
	_save_progress()
	_hide_hud()
	_set_core_tutorial_glow(false)
	_set_pickup_hints(false)
	call_deferred("_sync_active_phase_with_scene")


func set_tutorial_enabled(enabled: bool) -> void:
	if tutorial_enabled == enabled:
		return
	tutorial_enabled = enabled
	if not tutorial_enabled:
		current_state = TutorialState.DISABLED
		_hide_hud()
		_set_core_tutorial_glow(false)
		_set_pickup_hints(false)
	elif current_state == TutorialState.DISABLED:
		current_state = TutorialState.NOT_STARTED
		call_deferred("_sync_active_phase_with_scene")
	_save_progress()
	tutorial_visibility_changed.emit(enabled)


func skip_tutorial() -> void:
	set_tutorial_enabled(false)
	phase_completed.emit(PHASE_DAY_1_MOVEMENT)


func is_phase_1_active() -> bool:
	return current_state == TutorialState.DAY_1_MOVEMENT


func is_phase_1_complete() -> bool:
	return current_state == TutorialState.DAY_1_MOVEMENT_COMPLETE


func report_inventory_opened() -> void:
	if current_state != TutorialState.DAY_1_MOVEMENT:
		return
	if inventory_opened:
		return
	inventory_opened = true
	QuestManager.report_event(&"inventory_opened", 1, {})
	objective_updated.emit(&"open_inventory", true)
	_pulse_inventory_panel()
	_save_progress()
	_refresh_phase_1_ui()
	_check_phase_1_complete()


func notify_scene_ready() -> void:
	call_deferred("_sync_active_phase_with_scene")


func _sync_active_phase_with_scene() -> void:
	if not tutorial_enabled:
		return
	if current_state == TutorialState.DAY_1_MOVEMENT:
		if not is_instance_valid(GameManager.player):
			return
		_show_hud()
		_set_core_tutorial_glow(true)
		_set_pickup_hints(true)
		if not QuestManager.is_active(PHASE_DAY_1_MOVEMENT) and not QuestManager.is_completed(PHASE_DAY_1_MOVEMENT):
			QuestManager.start_quest(PHASE_DAY_1_MOVEMENT)
		return
	_try_start_day_1_movement()


func _try_start_day_1_movement() -> void:
	if not tutorial_enabled:
		return
	if current_state != TutorialState.NOT_STARTED:
		return
	if DayNightCycle.day_count != 1 or not DayNightCycle.is_day():
		return
	if not is_instance_valid(GameManager.player):
		return
	current_state = TutorialState.DAY_1_MOVEMENT
	_save_progress()
	_show_hud()
	_set_core_tutorial_glow(true)
	_set_pickup_hints(true)
	phase_started.emit(PHASE_DAY_1_MOVEMENT)
	QuestManager.start_quest(PHASE_DAY_1_MOVEMENT)
	_start_dialogic_label(LABEL_DAY_1_MOVEMENT)


func _start_dialogic_label(label_name: String) -> void:
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic == null:
		push_warning("[TutorialManager] Dialogic singleton not found.")
		return
	if dialogic.get("current_timeline") != null:
		return
	dialogic.start(TIMELINE_ACCESS_03, label_name)


func _update_movement_progress(delta: float) -> void:
	if moved_enough:
		return
	if not is_instance_valid(GameManager.player):
		return
	var velocity_raw: Variant = GameManager.player.get("velocity")
	if not velocity_raw is Vector2:
		return
	var velocity: Vector2 = velocity_raw
	if velocity.length() <= 1.0:
		return
	movement_seconds = min(movement_seconds + delta, MOVEMENT_REQUIRED_SECONDS)
	if movement_seconds >= MOVEMENT_REQUIRED_SECONDS:
		moved_enough = true
		if not _reported_movement:
			_reported_movement = true
			QuestManager.report_event(&"tutorial_movement_complete", 1, {})
		objective_updated.emit(&"move_5_seconds", true)
		_save_progress()


func _on_item_added(_item_id: String, _amount: int) -> void:
	if current_state != TutorialState.DAY_1_MOVEMENT:
		return
	if resource_collected:
		return
	resource_collected = true
	objective_updated.emit(&"collect_resource", true)
	_save_progress()
	_refresh_phase_1_ui()
	_check_phase_1_complete()


func _check_phase_1_complete() -> void:
	if current_state != TutorialState.DAY_1_MOVEMENT:
		return
	if not (moved_enough and inventory_opened and resource_collected):
		return
	current_state = TutorialState.DAY_1_MOVEMENT_COMPLETE
	_set_core_tutorial_glow(false)
	_set_pickup_hints(false)
	_save_progress()
	_refresh_phase_1_ui()
	phase_completed.emit(PHASE_DAY_1_MOVEMENT)
	if QuestManager.is_active(PHASE_DAY_1_MOVEMENT):
		QuestManager.complete_quest(PHASE_DAY_1_MOVEMENT)
	await get_tree().create_timer(1.5).timeout
	if current_state == TutorialState.DAY_1_MOVEMENT_COMPLETE:
		_hide_hud()


func _show_hud() -> void:
	if is_instance_valid(_hud_layer):
		_hud_layer.visible = true
		_refresh_phase_1_ui()
		return
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "TutorialHUD"
	_hud_layer.layer = 89
	_hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud_layer)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 8.0
	_panel.offset_top = 8.0
	_panel.offset_right = 218.0
	_panel.offset_bottom = 108.0
	_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.9, 0.75, 0.2, 1.0)))
	_hud_layer.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_phase_label = Label.new()
	_phase_label.text = "First Steps"
	_phase_label.add_theme_font_size_override("font_size", 10)
	_phase_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78, 1.0))
	vbox.add_child(_phase_label)

	_move_label = _make_objective_label()
	_inventory_label = _make_objective_label()
	_resource_label = _make_objective_label()
	vbox.add_child(_move_label)
	vbox.add_child(_inventory_label)
	vbox.add_child(_resource_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0.0, 6.0)
	vbox.add_child(_progress_bar)
	_refresh_phase_1_ui()


func _hide_hud() -> void:
	if is_instance_valid(_hud_layer):
		_hud_layer.visible = false


func _make_objective_label() -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.85, 0.84, 0.78, 1.0))
	return label


func _refresh_phase_1_ui() -> void:
	if not is_instance_valid(_hud_layer):
		return
	_move_label.text = "%s Move for %.0fs" % [_checkmark(moved_enough), MOVEMENT_REQUIRED_SECONDS]
	_inventory_label.text = "%s Open inventory [I]" % _checkmark(inventory_opened)
	_resource_label.text = "%s Collect a resource" % _checkmark(resource_collected)
	var completed_count: int = (1 if moved_enough else 0) \
		+ (1 if inventory_opened else 0) \
		+ (1 if resource_collected else 0)
	_progress_bar.value = float(completed_count) / 3.0
	if current_state == TutorialState.DAY_1_MOVEMENT_COMPLETE:
		_phase_label.text = "First Steps Complete"
	else:
		_phase_label.text = "First Steps"


func _checkmark(done: bool) -> String:
	return "[x]" if done else "[ ]"


func _make_panel_style(border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.08, 0.88)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _pulse_inventory_panel() -> void:
	if not is_instance_valid(get_tree().current_scene):
		return
	var screen: Node = get_tree().current_scene.find_child("InventoryScreen", true, false)
	if screen == null:
		return
	var panel: PanelContainer = screen.find_child("Panel", true, false) as PanelContainer
	if panel == null:
		return
	var style: StyleBoxFlat = _make_panel_style(Color(0.9, 0.75, 0.2, 1.0))
	panel.add_theme_stylebox_override("panel", style)
	var tween: Tween = panel.create_tween().set_loops(3)
	tween.tween_property(style, "border_color", Color(1.0, 0.95, 0.45, 1.0), 0.22)
	tween.tween_property(style, "border_color", Color(0.55, 0.42, 0.24, 1.0), 0.22)


func _set_core_tutorial_glow(enabled: bool) -> void:
	if _core_glow_active == enabled:
		return
	_core_glow_active = enabled
	if is_instance_valid(GameManager.dianthus_core) and GameManager.dianthus_core.has_method("set_tutorial_glow_active"):
		GameManager.dianthus_core.set_tutorial_glow_active(enabled)


func _set_pickup_hints(enabled: bool) -> void:
	for pickup: Node in get_tree().get_nodes_in_group(&"pickups"):
		if pickup.has_method("set_tutorial_hint_active"):
			pickup.set_tutorial_hint_active(enabled)


func _on_load_completed(_success: bool) -> void:
	_load_progress()
	call_deferred("_sync_active_phase_with_scene")


func _save_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("tutorial", "enabled", tutorial_enabled)
	config.set_value("tutorial", "state", current_state)
	config.set_value("phase_1", "movement_seconds", movement_seconds)
	config.set_value("phase_1", "moved_enough", moved_enough)
	config.set_value("phase_1", "inventory_opened", inventory_opened)
	config.set_value("phase_1", "resource_collected", resource_collected)
	config.save(PROGRESS_PATH)


func _load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PROGRESS_PATH) != OK:
		return
	tutorial_enabled = bool(config.get_value("tutorial", "enabled", true))
	current_state = int(config.get_value("tutorial", "state", TutorialState.NOT_STARTED))
	movement_seconds = float(config.get_value("phase_1", "movement_seconds", 0.0))
	moved_enough = bool(config.get_value("phase_1", "moved_enough", false))
	inventory_opened = bool(config.get_value("phase_1", "inventory_opened", false))
	resource_collected = bool(config.get_value("phase_1", "resource_collected", false))
	_reported_movement = moved_enough
	if not tutorial_enabled:
		current_state = TutorialState.DISABLED
