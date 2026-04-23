extends CanvasLayer

@onready var _player_bar: ProgressBar = %PlayerHPBar
@onready var _player_label: Label = %PlayerHPLabel
@onready var _core_bar: ProgressBar = %CoreHPBar
@onready var _core_label: Label = %CoreHPLabel
@onready var _player_container: MarginContainer = %PlayerHPContainer
@onready var _core_container: MarginContainer = %CoreHPContainer
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

const HOTBAR_SELECTED_COLOR: Color = Color(0.9, 0.75, 0.2, 1)
const HOTBAR_NORMAL_COLOR: Color = Color(0.3, 0.3, 0.3, 1)
const HOTBAR_LOCKED_COLOR: Color = Color(0.5, 0.15, 0.15, 1)

var _prev_player_hp: int = -1
var _prev_core_hp: int = -1


func _ready() -> void:
	GameManager.player_hp_changed.connect(_on_player_hp_changed)
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
	GameManager.colorblind_mode_changed.connect(_on_colorblind_changed)
	GameManager.player_energy_changed.connect(_on_player_energy_changed)
	GameManager.loadout_changed.connect(_on_loadout_changed)
	DayNightCycle.phase_changed.connect(_on_phase_changed_hud)
	_on_colorblind_changed(GameManager.colorblind_mode)


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_player_bar.max_value = max_hp
	_player_bar.value = current_hp
	_player_label.text = "PLAYER HP  %d / %d" % [current_hp, max_hp]
	if _prev_player_hp >= 0 and current_hp < _prev_player_hp:
		_shake(_player_container)
	_prev_player_hp = current_hp


func _on_core_hp_changed(current_hp: int, max_hp: int) -> void:
	_core_bar.max_value = max_hp
	_core_bar.value = current_hp
	_core_label.text = "DIANTHUS CORE  %d / %d" % [current_hp, max_hp]
	if _prev_core_hp >= 0 and current_hp < _prev_core_hp:
		_shake(_core_container)
	_prev_core_hp = current_hp


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
	_skill_name.text = skill_id if not skill_id.is_empty() else "[Empty]"
	_apply_hotbar_border(_slot1_panel, selected_slot == 0)
	_apply_hotbar_border(_slot2_panel, selected_slot == 1)


func _on_phase_changed_hud(phase: String) -> void:
	var is_night: bool = (phase == "NIGHT")
	var tint: Color = HOTBAR_LOCKED_COLOR if is_night else Color.WHITE
	_slot1_panel.modulate = tint
	_slot2_panel.modulate = tint


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


func _shake(node: Control) -> void:
	var original_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
	tween.tween_property(node, "position", original_pos, 0.03)
