extends CanvasLayer

const SLOT_SELECTED_COLOR: Color = Color(0.9, 0.75, 0.2, 1)
const SLOT_NORMAL_COLOR: Color = Color(0.3, 0.3, 0.3, 1)
const LOCKED_COLOR: Color = Color(0.7, 0.15, 0.15, 1)

@onready var _slot1_panel: PanelContainer = %Slot1
@onready var _slot2_panel: PanelContainer = %Slot2
@onready var _owned_list: VBoxContainer = %OwnedList
@onready var _lock_label: Label = %LockLabel
@onready var _slot1_label: Label = %Slot1WeaponLabel
@onready var _slot2_label: Label = %Slot2WeaponLabel
@onready var _skill_label: Label = %SkillLabel

var _pending_assign_slot: int = -1
var _is_night: bool = false


func _ready() -> void:
	visible = false
	layer = 94
	process_mode = PROCESS_MODE_ALWAYS
	GameManager.loadout_changed.connect(_on_loadout_changed)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	_is_night = DayNightCycle.is_night()


func open() -> void:
	visible = true
	get_tree().paused = true
	_is_night = DayNightCycle.is_night()
	_refresh()


func close() -> void:
	visible = false
	get_tree().paused = false
	_pending_assign_slot = -1


func _refresh() -> void:
	if not is_instance_valid(GameManager.player):
		return
	var p: Node = GameManager.player
	var slots: Array = p.weapon_slots
	var sel: int = p.selected_weapon_slot
	var skill: String = p.active_skill_id

	_slot1_label.text = _weapon_display(slots[0])
	_slot2_label.text = _weapon_display(slots[1])
	_skill_label.text = skill if not skill.is_empty() else "[Empty]"

	_apply_slot_border(_slot1_panel, sel == 0)
	_apply_slot_border(_slot2_panel, sel == 1)

	_lock_label.visible = _is_night
	_build_owned_list(slots)


func _build_owned_list(_current_slots: Array) -> void:
	for child: Node in _owned_list.get_children():
		child.queue_free()

	var owned: Array = CraftingManager.get_owned_weapon_ids()
	if owned.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "No weapons owned."
		none_label.add_theme_font_size_override("font_size", 6)
		_owned_list.add_child(none_label)
		return

	for wid: String in owned:
		var row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = Label.new()
		name_label.text = _weapon_display(wid)
		name_label.add_theme_font_size_override("font_size", 6)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var btn1: Button = Button.new()
		btn1.text = "→1"
		btn1.add_theme_font_size_override("font_size", 6)
		btn1.disabled = _is_night
		btn1.pressed.connect(func() -> void: _assign_weapon(0, wid))
		row.add_child(btn1)

		var btn2: Button = Button.new()
		btn2.text = "→2"
		btn2.add_theme_font_size_override("font_size", 6)
		btn2.disabled = _is_night
		btn2.pressed.connect(func() -> void: _assign_weapon(1, wid))
		row.add_child(btn2)

		_owned_list.add_child(row)


func _assign_weapon(slot: int, weapon_id: String) -> void:
	if _is_night:
		print("[LoadoutScreen] Loadout locked during Night.")
		return
	if is_instance_valid(GameManager.player):
		GameManager.player.equip_weapon(slot, weapon_id)
	_refresh()


func _on_loadout_changed(_weapon_slots: Array, _skill_id: String, _selected_slot: int) -> void:
	if visible:
		_refresh()


func _on_phase_changed(phase: String) -> void:
	_is_night = (phase == "NIGHT")
	if visible:
		_refresh()


func _weapon_display(weapon_id: String) -> String:
	if weapon_id.is_empty():
		return "[Empty]"
	var data: WeaponData = CraftingManager.get_weapon_data(weapon_id)
	if data != null and not data.weapon_name.is_empty():
		return data.weapon_name
	return weapon_id.capitalize().replace("_", " ")


func _unhandled_input(_event: InputEvent) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("loadout_toggle"):
		close()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return


func _apply_slot_border(panel: PanelContainer, selected: bool) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.12, 1)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = SLOT_SELECTED_COLOR if selected else SLOT_NORMAL_COLOR
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_right = 2
	sb.corner_radius_bottom_left = 2
	panel.add_theme_stylebox_override("panel", sb)
