extends CanvasLayer

@onready var _player_bar: ProgressBar = %PlayerHPBar
@onready var _player_label: Label = %PlayerHPLabel
@onready var _core_bar: ProgressBar = %CoreHPBar
@onready var _core_label: Label = %CoreHPLabel
@onready var _player_panel: PanelContainer = %PlayerVitalsPanel
@onready var _core_panel: PanelContainer = %CoreHPPanel
@onready var _player_hp_icon: Label = %PlayerHPIcon
@onready var _core_hp_icon: Label = %CoreHPIcon
@onready var _energy_bar: ProgressBar = %EnergyBar
@onready var _energy_label: Label = %EnergyLabel
@onready var _energy_icon: Label = %EnergyIcon
@onready var _slot1_panel: PanelContainer = %WeaponSlot1
@onready var _slot2_panel: PanelContainer = %WeaponSlot2
@onready var _slot1_name: Label = %Slot1NameLabel
@onready var _slot2_name: Label = %Slot2NameLabel
@onready var _skill_name: Label = %SkillNameLabel
@onready var _tracked_quest_panel: TrackedQuestHUD = %TrackedQuestPanel
@onready var _endless_label: Label = %EndlessLabel
@onready var _return_label: Label = %ReturnWarningLabel
@onready var _skip_day_button: Button = %SkipDayButton
@onready var _skip_confirm_panel: PanelContainer = %SkipConfirmPanel
@onready var _skip_confirm_yes: Button = %SkipConfirmYes
@onready var _skip_confirm_no: Button = %SkipConfirmNo

const HOTBAR_SELECTED_COLOR: Color = Color(0.9, 0.75, 0.2, 1)
const HOTBAR_NORMAL_COLOR: Color = Color(0.3, 0.3, 0.3, 1)
const HOTBAR_LOCKED_COLOR: Color = Color(0.5, 0.15, 0.15, 1)

const WOOD_PANEL_BG: Color = Color(0.30, 0.22, 0.15, 0.85)
const WOOD_PANEL_BORDER: Color = Color(0.65, 0.50, 0.25, 1.0)
const WOOD_PANEL_BORDER_DANGER: Color = Color(0.85, 0.20, 0.15, 1.0)
const LOW_HP_THRESHOLD: float = 0.25

const RETURN_WARNING_THRESHOLD: float = 30.0

var _prev_player_hp: int = -1
var _prev_core_hp: int = -1
var _low_hp_tween: Tween = null
var _core_danger_tween: Tween = null
var _core_in_danger: bool = false
var _return_tween: Tween = null
var _confirm_visible: bool = false


func _ready() -> void:
	GameManager.player_hp_changed.connect(_on_player_hp_changed)
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
	GameManager.colorblind_mode_changed.connect(_on_colorblind_changed)
	GameManager.player_energy_changed.connect(_on_player_energy_changed)
	GameManager.loadout_changed.connect(_on_loadout_changed)
	DayNightCycle.phase_changed.connect(_on_phase_changed_hud)
	_on_colorblind_changed(GameManager.colorblind_mode)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	_refresh_endless_label()
	QuestManager.quest_completed.connect(_on_quest_completed_hud)
	_skip_day_button.pressed.connect(_on_skip_day_pressed)
	_skip_day_button.visible = not DayNightCycle.is_night()
	_skip_confirm_panel.visible = false
	_skip_confirm_yes.pressed.connect(_on_skip_confirm_yes)
	_skip_confirm_no.pressed.connect(_on_skip_confirm_no)


func _process(_delta: float) -> void:
	var is_night: bool = DayNightCycle.is_night()
	var remaining: float = DayNightCycle.get_time_remaining()
	var should_show: bool = not is_night and remaining <= RETURN_WARNING_THRESHOLD
	if should_show and not _return_label.visible:
		_return_label.visible = true
		_start_return_pulse()
	elif not should_show and _return_label.visible:
		_return_label.visible = false
		_stop_return_pulse()

	if Input.is_action_just_pressed("skip_day") and not is_night:
		_on_skip_day_pressed()
	if _confirm_visible and Input.is_action_just_pressed("ui_cancel"):
		_on_skip_confirm_no()


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_player_bar.max_value = max_hp
	var tween_hp: Tween = create_tween()
	tween_hp.tween_property(_player_bar, "value", float(current_hp), 0.15)
	_player_label.text = "HP  %d / %d" % [current_hp, max_hp]
	if _prev_player_hp >= 0 and current_hp < _prev_player_hp:
		_shake(_player_panel)
	_prev_player_hp = current_hp
	var ratio: float = float(current_hp) / float(max(max_hp, 1))
	if ratio <= LOW_HP_THRESHOLD:
		_start_low_hp_pulse()
	else:
		_stop_low_hp_pulse()


func _on_core_hp_changed(current_hp: int, max_hp: int) -> void:
	_core_bar.max_value = max_hp
	_core_bar.value = current_hp
	_core_label.text = "CORE  %d / %d" % [current_hp, max_hp]
	if _prev_core_hp >= 0 and current_hp < _prev_core_hp:
		_shake(_core_panel)
	_prev_core_hp = current_hp
	var ratio: float = float(current_hp) / float(max(max_hp, 1))
	if ratio <= LOW_HP_THRESHOLD and not _core_in_danger:
		_core_in_danger = true
		_start_core_danger_pulse()
	elif ratio > LOW_HP_THRESHOLD and _core_in_danger:
		_core_in_danger = false
		_stop_core_danger_pulse()


func _on_player_energy_changed(current_energy: int, max_energy: int) -> void:
	_energy_bar.max_value = max_energy
	var tween: Tween = create_tween()
	tween.tween_property(_energy_bar, "value", float(current_energy), 0.15)
	_energy_label.text = "ENERGY  %d / %d" % [current_energy, max_energy]


func _on_colorblind_changed(enabled: bool) -> void:
	_player_hp_icon.visible = enabled
	_core_hp_icon.visible = enabled
	_energy_icon.visible = enabled


func _on_loadout_changed(weapon_slots: Array, skill_id: String, selected_slot: int) -> void:
	_slot1_name.text = _hotbar_label(weapon_slots[0] if weapon_slots.size() > 0 else "")
	_slot2_name.text = _hotbar_label(weapon_slots[1] if weapon_slots.size() > 1 else "")
	_skill_name.text = AbilityManager.ABILITIES.get(skill_id, {}).get("display_name", skill_id) if not skill_id.is_empty() else "[Empty]"
	_apply_hotbar_border(_slot1_panel, selected_slot == 0)
	_apply_hotbar_border(_slot2_panel, selected_slot == 1)


func _on_phase_changed_hud(phase: String) -> void:
	var is_night: bool = (phase == "NIGHT")
	var tint: Color = HOTBAR_LOCKED_COLOR if is_night else Color.WHITE
	_slot1_panel.modulate = tint
	_slot2_panel.modulate = tint
	if is_night:
		_return_label.visible = false
		_stop_return_pulse()
	_skip_day_button.visible = not is_night
	_on_skip_confirm_no()


func _on_skip_day_pressed() -> void:
	if DayNightCycle.is_night():
		return
	if _confirm_visible:
		_on_skip_confirm_no()
		return
	_confirm_visible = true
	_skip_confirm_panel.visible = true
	_skip_day_button.disabled = true


func _on_skip_confirm_yes() -> void:
	_confirm_visible = false
	_skip_confirm_panel.visible = false
	_skip_day_button.disabled = false
	print("[HUD] Skip to Night confirmed.")
	DayNightCycle.debug_skip_phase()


func _on_skip_confirm_no() -> void:
	_confirm_visible = false
	_skip_confirm_panel.visible = false
	_skip_day_button.disabled = false


func _start_return_pulse() -> void:
	if is_instance_valid(_return_tween):
		return
	_return_tween = create_tween().set_loops()
	_return_tween.tween_property(_return_label, "modulate", Color(1.0, 0.3, 0.0, 1.0), 0.4)
	_return_tween.tween_property(_return_label, "modulate", Color.WHITE, 0.4)


func _stop_return_pulse() -> void:
	if is_instance_valid(_return_tween):
		_return_tween.kill()
	_return_tween = null
	_return_label.modulate = Color.WHITE


func _start_low_hp_pulse() -> void:
	if is_instance_valid(_low_hp_tween):
		return
	_low_hp_tween = create_tween().set_loops()
	_low_hp_tween.tween_property(_player_panel, "modulate", Color(1, 0.5, 0.5, 1), 0.5)
	_low_hp_tween.tween_property(_player_panel, "modulate", Color.WHITE, 0.5)


func _stop_low_hp_pulse() -> void:
	if is_instance_valid(_low_hp_tween):
		_low_hp_tween.kill()
	_low_hp_tween = null
	_player_panel.modulate = Color.WHITE


func _start_core_danger_pulse() -> void:
	if is_instance_valid(_core_danger_tween):
		return
	_core_danger_tween = create_tween().set_loops()
	_core_danger_tween.tween_property(_core_panel, "modulate", Color(1.3, 0.5, 0.5, 1), 0.4)
	_core_danger_tween.tween_property(_core_panel, "modulate", Color.WHITE, 0.4)


func _stop_core_danger_pulse() -> void:
	if is_instance_valid(_core_danger_tween):
		_core_danger_tween.kill()
	_core_danger_tween = null
	_core_panel.modulate = Color.WHITE


func _hotbar_label(weapon_id: String) -> String:
	if weapon_id.is_empty():
		return "[Empty]"
	var data: WeaponData = CraftingManager.get_weapon_data(weapon_id)
	if data != null and not data.weapon_name.is_empty():
		return data.weapon_name
	return weapon_id.capitalize().replace("_", " ")


func _apply_hotbar_border(panel: PanelContainer, selected: bool) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = HOTBAR_SELECTED_COLOR if selected else HOTBAR_NORMAL_COLOR
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_right = 2
	sb.corner_radius_bottom_left = 2
	panel.add_theme_stylebox_override("panel", sb)


func _make_wood_stylebox(border_color: Color = WOOD_PANEL_BORDER) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = WOOD_PANEL_BG
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 2
	return sb


func _on_game_state_changed(_state: String) -> void:
	_refresh_endless_label()


func _on_quest_completed_hud(quest_id: StringName) -> void:
	if is_instance_valid(_tracked_quest_panel) \
			and not _tracked_quest_panel.get("_tutorial_mode") \
			and _tracked_quest_panel.get_tracked_quest_id() == quest_id:
		_tracked_quest_panel.untrack_quest()


func _refresh_endless_label() -> void:
	_endless_label.visible = GameManager.endless_mode


func _shake(node: Control) -> void:
	var original_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
	tween.tween_property(node, "position", original_pos, 0.03)


# ── Public: tracked quest API ─────────────────────────────────────────────────

func track_quest(quest_id: StringName) -> void:
	if is_instance_valid(_tracked_quest_panel):
		_tracked_quest_panel.track_quest(quest_id)


func untrack_quest() -> void:
	if is_instance_valid(_tracked_quest_panel):
		_tracked_quest_panel.untrack_quest()


func get_tracked_quest() -> StringName:
	if is_instance_valid(_tracked_quest_panel):
		return _tracked_quest_panel.get_tracked_quest_id()
	return &""


func is_tracking_quest() -> bool:
	if is_instance_valid(_tracked_quest_panel):
		return _tracked_quest_panel.is_tracking()
	return false


func show_tutorial_mode(phase_name: String, objectives: Array[String], completed: Array[bool]) -> void:
	if is_instance_valid(_tracked_quest_panel):
		_tracked_quest_panel.set_tutorial_mode(true)
		_tracked_quest_panel.set_tutorial_phase(phase_name, objectives, completed)


func hide_tutorial_mode() -> void:
	if is_instance_valid(_tracked_quest_panel):
		_tracked_quest_panel.set_tutorial_mode(false)
