extends CanvasLayer

const SLOT_SELECTED_COLOR: Color = Color(0.9, 0.75, 0.2, 1)
const SLOT_NORMAL_COLOR: Color = Color(0.3, 0.3, 0.3, 1)
const LOCKED_COLOR: Color = Color(0.7, 0.15, 0.15, 1)
const ABILITY_EQUIPPED_COLOR: Color = Color(0.2, 0.8, 0.5, 1)

const ABILITY_DISPLAY_NAMES: Dictionary = {
	"dash": "Dash",
	"heal_pulse": "Heal Pulse",
	"thorn_burst": "Thorn Burst",
}

@onready var _slot1_panel: PanelContainer = %Slot1
@onready var _slot2_panel: PanelContainer = %Slot2
@onready var _owned_list: VBoxContainer = %OwnedList
@onready var _ability_list: VBoxContainer = %AbilityList
@onready var _skill_slot: PanelContainer = %SkillSlot
@onready var _lock_label: Label = %LockLabel
@onready var _slot1_label: Label = %Slot1WeaponLabel
@onready var _slot2_label: Label = %Slot2WeaponLabel
@onready var _skill_label: Label = %SkillLabel
@onready var _cost_label: Label = %CostLabel

var _pending_assign_slot: int = -1
var _is_night: bool = false


func _ready() -> void:
	visible = false
	layer = 94
	process_mode = PROCESS_MODE_ALWAYS
	GameManager.loadout_changed.connect(_on_loadout_changed)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	CraftingManager.ability_crafted.connect(_on_ability_crafted)
	_is_night = DayNightCycle.is_night()


func open() -> void:
	SfxManager.play("screen_open")
	visible = true
	PauseManager.request_pause(self)
	_is_night = DayNightCycle.is_night()
	_refresh()


func close() -> void:
	SfxManager.play("screen_close")
	visible = false
	PauseManager.release_pause(self)
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
	_skill_label.text = AbilityManager.ABILITIES.get(skill, {}).get("display_name", skill) if not skill.is_empty() else "[Empty]"
	_cost_label.text = "%dE" % int(AbilityManager.ABILITIES.get(skill, {}).get("energy_cost", 0)) if not skill.is_empty() else "\u2014"

	_apply_slot_border(_slot1_panel, sel == 0)
	_apply_slot_border(_slot2_panel, sel == 1)

	_lock_label.visible = _is_night
	_build_owned_list(slots)
	_build_ability_list(skill)


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


func _build_ability_list(equipped_skill: String) -> void:
	for child: Node in _ability_list.get_children():
		child.queue_free()

	var owned: Array = CraftingManager.get_owned_ability_ids()
	if owned.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "No abilities owned. Craft them at the bench."
		none_label.add_theme_font_size_override("font_size", 6)
		_ability_list.add_child(none_label)
		return

	for aid: String in owned:
		var row: HBoxContainer = HBoxContainer.new()
		var is_equipped: bool = (aid == equipped_skill)

		var name_label: Label = Label.new()
		name_label.text = AbilityManager.ABILITIES.get(aid, {}).get("display_name", aid.capitalize())
		name_label.add_theme_font_size_override("font_size", 6)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_equipped:
			name_label.modulate = ABILITY_EQUIPPED_COLOR
		row.add_child(name_label)

		var cost_lbl: Label = Label.new()
		cost_lbl.text = "%dE" % int(AbilityManager.ABILITIES.get(aid, {}).get("energy_cost", 0))
		cost_lbl.add_theme_font_size_override("font_size", 6)
		cost_lbl.modulate = Color(0.2, 0.7, 0.9, 1.0)
		row.add_child(cost_lbl)

		var equip_btn: Button = Button.new()
		equip_btn.add_theme_font_size_override("font_size", 6)
		if is_equipped:
			equip_btn.text = "[Equipped]"
			equip_btn.disabled = true
		else:
			equip_btn.text = "Equip"
			equip_btn.disabled = _is_night
			var ability_id: String = aid
			equip_btn.pressed.connect(func() -> void: _equip_ability(ability_id))
		row.add_child(equip_btn)

		_ability_list.add_child(row)


func _equip_ability(ability_id: String) -> void:
	if _is_night:
		print("[LoadoutScreen] Loadout locked during Night.")
		return
	SfxManager.play("ui_button_click")
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("set_active_skill"):
		GameManager.player.set_active_skill(ability_id)
	_refresh()


func _on_ability_crafted(_ability_id: String) -> void:
	if visible:
		_refresh()


func _assign_weapon(slot: int, weapon_id: String) -> void:
	if _is_night:
		print("[LoadoutScreen] Loadout locked during Night.")
		return
	SfxManager.play("ui_button_click")
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
