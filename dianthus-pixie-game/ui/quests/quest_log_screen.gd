extends CanvasLayer

const TYPE_COLOR: Dictionary = {
	QuestData.Type.DAILY:     Color(0.95, 0.85, 0.3),
	QuestData.Type.PROGRESS:  Color(0.4, 0.75, 1.0),
	QuestData.Type.DISCOVERY: Color(0.6, 1.0, 0.55),
	QuestData.Type.STORY:     Color(1.0, 0.6, 0.85),
}

const TYPE_LABEL: Dictionary = {
	QuestData.Type.DAILY:     "[DAILY]",
	QuestData.Type.PROGRESS:  "[PROGRESS]",
	QuestData.Type.DISCOVERY: "[DISCOVERY]",
	QuestData.Type.STORY:     "[STORY]",
}

const TAB_SELECTED_COLOR: Color = Color(0.95, 0.85, 0.3)
const TAB_NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0, 0.55)

@onready var _quest_list: VBoxContainer = %QuestList
@onready var _active_btn: Button = %ActiveTabBtn
@onready var _completed_btn: Button = %CompletedTabBtn
@onready var _failed_btn: Button = %FailedTabBtn

var _current_tab: String = "active"


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	QuestManager.quest_started.connect(_refresh.unbind(1))
	QuestManager.quest_progress_updated.connect(_on_progress_updated)
	QuestManager.quest_completed.connect(_refresh.unbind(1))
	QuestManager.quest_failed.connect(_refresh.unbind(2))
	QuestManager.quest_rewards_granted.connect(_refresh.unbind(3))
	QuestManager.quest_tracked.connect(_refresh.unbind(1))
	QuestManager.quest_untracked.connect(_refresh)
	_active_btn.pressed.connect(_on_tab_active)
	_completed_btn.pressed.connect(_on_tab_completed)
	_failed_btn.pressed.connect(_on_tab_failed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_log_toggle"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	SfxManager.play("screen_open")
	visible = true
	PauseManager.request_pause(self)
	_update_tab_counts()
	_refresh()


func close() -> void:
	SfxManager.play("screen_close")
	visible = false
	PauseManager.release_pause(self)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


# ── Private ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	for child: Node in _quest_list.get_children():
		child.queue_free()
	_update_tab_counts()
	match _current_tab:
		"active":    _build_active()
		"completed": _build_completed()
		"failed":    _build_failed()


func _on_progress_updated(_quest_id: StringName, _obj_id: StringName, _current: int, _target: int) -> void:
	if visible:
		_refresh()


func _on_tab_active() -> void:
	SfxManager.play("ui_button_click")
	_current_tab = "active"
	_update_tab_highlight()
	_refresh()


func _on_tab_completed() -> void:
	SfxManager.play("ui_button_click")
	_current_tab = "completed"
	_update_tab_highlight()
	_refresh()


func _on_tab_failed() -> void:
	SfxManager.play("ui_button_click")
	_current_tab = "failed"
	_update_tab_highlight()
	_refresh()


func _update_tab_counts() -> void:
	var active_count: int = QuestManager.get_active_quests().size()
	var completed_count: int = QuestManager.get_completed_quests().size()
	var failed_count: int = QuestManager.get_failed_quests().size()
	_active_btn.text = "Active (%d)" % active_count
	_completed_btn.text = "Completed (%d)" % completed_count
	_failed_btn.text = "Failed (%d)" % failed_count
	_update_tab_highlight()


func _update_tab_highlight() -> void:
	_active_btn.modulate    = TAB_SELECTED_COLOR if _current_tab == "active"    else TAB_NORMAL_COLOR
	_completed_btn.modulate = TAB_SELECTED_COLOR if _current_tab == "completed" else TAB_NORMAL_COLOR
	_failed_btn.modulate    = TAB_SELECTED_COLOR if _current_tab == "failed"    else TAB_NORMAL_COLOR


func _build_active() -> void:
	var quests: Array[QuestData] = QuestManager.get_active_quests()
	if quests.is_empty():
		_add_empty_label("No active quests.")
		return

	var sorted: Array[QuestData] = []
	for qt: QuestData.Type in [QuestData.Type.STORY, QuestData.Type.DAILY,
			QuestData.Type.PROGRESS, QuestData.Type.DISCOVERY]:
		for q: QuestData in quests:
			if q.quest_type == qt:
				sorted.append(q)

	for q: QuestData in sorted:
		_add_active_row(q)


func _add_active_row(q: QuestData) -> void:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	# Header row
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)

	var name_lbl: Label = Label.new()
	name_lbl.text = q.display_name
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var type_lbl: Label = Label.new()
	type_lbl.text = TYPE_LABEL.get(q.quest_type, "")
	type_lbl.add_theme_font_size_override("font_size", 7)
	type_lbl.modulate = TYPE_COLOR.get(q.quest_type, Color.WHITE)

	# Track button
	var is_tracked: bool = QuestManager.is_tracking(q.quest_id)
	var track_btn: Button = Button.new()
	track_btn.text = "📌 Tracked" if is_tracked else "📌 Track"
	track_btn.add_theme_font_size_override("font_size", 7)
	track_btn.flat = not is_tracked
	track_btn.modulate = Color(0.95, 0.85, 0.3, 1.0) if is_tracked else Color.WHITE
	track_btn.pressed.connect(_on_track_button_pressed.bind(q.quest_id, panel))
	track_btn.name = "TrackButton_%s" % q.quest_id

	header.add_child(name_lbl)
	header.add_child(type_lbl)
	header.add_child(track_btn)

	# Time-limit countdown
	if q.time_limit_days > 0:
		var started: int = QuestManager.get_started_day(q.quest_id)
		var due_day: int = started + q.time_limit_days
		var remaining: int = maxi(0, due_day - DayNightCycle.day_count)
		var timer_lbl: Label = Label.new()
		timer_lbl.text = "  %d day%s left" % [remaining, "" if remaining == 1 else "s"]
		timer_lbl.add_theme_font_size_override("font_size", 7)
		timer_lbl.modulate = Color(1, 0.4, 0.4) if remaining <= 1 else Color(1, 1, 1)
		header.add_child(timer_lbl)

	vbox.add_child(header)

	# Description
	if q.description != "":
		var desc_lbl: Label = Label.new()
		desc_lbl.text = q.description
		desc_lbl.add_theme_font_size_override("font_size", 7)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.modulate = Color(0.8, 0.8, 0.8, 1.0)
		vbox.add_child(desc_lbl)

	# Objectives with progress bars
	var prog: Dictionary = QuestManager.get_progress(q.quest_id)
	if not prog.is_empty():
		var obj_box: VBoxContainer = VBoxContainer.new()
		obj_box.add_theme_constant_override("separation", 2)
		for obj_id: StringName in prog:
			var entry: Dictionary = prog[obj_id]
			var current: int = int(entry.get("current", 0))
			var target: int = int(entry.get("target", 1))
			var desc: String = str(entry.get("description", obj_id))

			var obj_vbox: VBoxContainer = VBoxContainer.new()
			obj_vbox.add_theme_constant_override("separation", 1)

			var obj_hbox: HBoxContainer = HBoxContainer.new()
			var obj_lbl: Label = Label.new()
			obj_lbl.text = desc
			obj_lbl.add_theme_font_size_override("font_size", 7)
			obj_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var count_lbl: Label = Label.new()
			count_lbl.text = "(%d / %d)" % [current, target]
			count_lbl.add_theme_font_size_override("font_size", 7)
			count_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)

			obj_hbox.add_child(obj_lbl)
			obj_hbox.add_child(count_lbl)

			var bar: ProgressBar = ProgressBar.new()
			bar.min_value = 0
			bar.max_value = target
			bar.value = current
			bar.custom_minimum_size = Vector2(0, 6)
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar.show_percentage = false

			obj_vbox.add_child(obj_hbox)
			obj_vbox.add_child(bar)
			obj_box.add_child(obj_vbox)

		vbox.add_child(obj_box)

	# Rewards line
	var reward_parts: Array[String] = []
	for item_id: String in q.reward_items:
		var amt: int = int(q.reward_items[item_id])
		if amt > 0:
			reward_parts.append("%s×%d" % [item_id, amt])
	for weapon_id: String in q.reward_weapons:
		reward_parts.append("+%s" % weapon_id)
	if not reward_parts.is_empty():
		var reward_lbl: Label = Label.new()
		reward_lbl.text = "Rewards: %s" % ", ".join(reward_parts)
		reward_lbl.add_theme_font_size_override("font_size", 7)
		reward_lbl.modulate = Color(0.9, 0.75, 0.2, 1.0)
		reward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(reward_lbl)

	panel.add_child(vbox)
	_quest_list.add_child(panel)
	_add_separator()


func _on_track_button_pressed(quest_id: StringName, _panel: PanelContainer) -> void:
	SfxManager.play("ui_button_click")
	if QuestManager.is_tracking(quest_id):
		QuestManager.untrack_quest()
	else:
		QuestManager.track_quest(quest_id)
	_refresh()


func _build_completed() -> void:
	var quests: Array[QuestData] = QuestManager.get_completed_quests()
	if quests.is_empty():
		_add_empty_label("No completed quests.")
		return
	for q: QuestData in quests:
		_add_compact_row(q, true, "")


func _build_failed() -> void:
	var entries: Array[Dictionary] = QuestManager.get_failed_quests()
	if entries.is_empty():
		_add_empty_label("No failed quests.")
		return
	for entry: Dictionary in entries:
		var q: QuestData = entry.get("quest") as QuestData
		var reason: String = str(entry.get("reason", ""))
		if q != null:
			_add_compact_row(q, false, reason)


func _add_compact_row(q: QuestData, completed: bool, reason: String) -> void:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var name_lbl: Label = Label.new()
	name_lbl.text = q.display_name
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var status_lbl: Label = Label.new()
	status_lbl.add_theme_font_size_override("font_size", 7)
	if completed:
		status_lbl.text = "✓ Completed"
		status_lbl.modulate = Color(0.4, 0.9, 0.4)
	else:
		status_lbl.text = "✗ Failed: %s" % reason if reason != "" else "✗ Failed"
		status_lbl.modulate = Color(0.9, 0.3, 0.3)

	hbox.add_child(name_lbl)
	hbox.add_child(status_lbl)
	panel.add_child(hbox)
	_quest_list.add_child(panel)
	_add_separator()


func _add_empty_label(text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.modulate = Color(0.5, 0.5, 0.5, 1.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.add_child(lbl)


func _add_separator() -> void:
	var sep: HSeparator = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.12)
	_quest_list.add_child(sep)
