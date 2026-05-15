extends CanvasLayer

const NOTIFICATION_ITEM_SCENE: PackedScene = preload("res://ui/hud/hud_notification_item.tscn")
const STATUS_EFFECT_ITEM_SCENE: PackedScene = preload("res://ui/hud/active_status_effect_item.tscn")

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
@onready var _boss_panel: PanelContainer = %BossHPPanel
@onready var _boss_bar: ProgressBar = %BossHPBar
@onready var _boss_label: Label = %BossHPLabel
@onready var _forecast_panel: PanelContainer = %WatchtowerForecastPanel
@onready var _forecast_special_label: Label = %ForecastSpecialLabel
@onready var _forecast_lanes_label: Label = %ForecastLanesLabel
@onready var _forecast_threats_label: Label = %ForecastThreatsLabel
@onready var _forecast_count_label: Label = %ForecastCountLabel
@onready var _notification_container: VBoxContainer = %NotificationContainer
@onready var _status_effects_panel: Control = %ActiveStatusEffectsBar
@onready var _status_effects_container: HBoxContainer = %ActiveStatusEffectsContainer

const HOTBAR_SELECTED_COLOR: Color = Color(0.9, 0.75, 0.2, 1)
const HOTBAR_NORMAL_COLOR: Color = Color(0.3, 0.3, 0.3, 1)
const HOTBAR_LOCKED_COLOR: Color = Color(0.5, 0.15, 0.15, 1)

const WOOD_PANEL_BG: Color = Color(0.30, 0.22, 0.15, 0.85)
const WOOD_PANEL_BORDER: Color = Color(0.65, 0.50, 0.25, 1.0)
const WOOD_PANEL_BORDER_DANGER: Color = Color(0.85, 0.20, 0.15, 1.0)
const LOW_HP_THRESHOLD: float = 0.25

const RETURN_WARNING_THRESHOLD: float = 30.0
const MAX_VISIBLE_NOTIFICATIONS: int = 4
const STATUS_DISPLAY_REFRESH_INTERVAL: float = 0.2
const ITEM_NOTIFICATION_DURATION: float = 2.2
const CODEX_NOTIFICATION_DURATION: float = 3.6
const QUEST_UPDATE_DURATION: float = 3.0
const QUEST_COMPLETE_DURATION: float = 4.2
const UNLOCK_NOTIFICATION_DURATION: float = 3.4
const FORECAST_ENEMY_LABELS: Dictionary = {
	"shadowling": "Shadowling",
	"voidrunner": "Voidrunner",
	"stonehusk": "Stonehusk",
	"phantom_weaver": "Phantom Weaver",
	"swarm_larva": "Swarm Larva",
	"the_devourer": "The Devourer",
}

var _prev_player_hp: int = -1
var _prev_core_hp: int = -1
var _low_hp_tween: Tween = null
var _core_danger_tween: Tween = null
var _core_in_danger: bool = false
var _return_tween: Tween = null
var _confirm_visible: bool = false
var _active_boss: Node = null
var _forecast_spawner: WaveSpawner = null
var _notification_queue: Array[Dictionary] = []
var _visible_notifications: Array[Control] = []
var _item_notification_totals: Dictionary = {}
var _last_quest_progress_notifications: Dictionary = {}
var _status_player: Node = null
var _status_effect_items: Dictionary = {}
var _status_display_refresh_timer: float = 0.0


func _ready() -> void:
	GameManager.player_hp_changed.connect(_on_player_hp_changed)
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
	GameManager.colorblind_mode_changed.connect(_on_colorblind_changed)
	GameManager.player_energy_changed.connect(_on_player_energy_changed)
	GameManager.loadout_changed.connect(_on_loadout_changed)
	GameManager.player_registered.connect(_on_player_registered_hud)
	DayNightCycle.phase_changed.connect(_on_phase_changed_hud)
	NightDefenseManager.notification_requested.connect(_on_night_defense_notification_requested)
	_on_colorblind_changed(GameManager.colorblind_mode)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	_refresh_endless_label()
	InventoryManager.item_added.connect(_on_inventory_item_added_hud)
	CodexManager.plant_discovered.connect(_on_plant_discovered_hud)
	CodexManager.enemy_discovered.connect(_on_enemy_discovered_hud)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated_hud)
	QuestManager.quest_completed.connect(_on_quest_completed_hud)
	UnlockFlags.flag_set.connect(_on_unlock_flag_set_hud)
	_skip_day_button.pressed.connect(_on_skip_day_pressed)
	_skip_day_button.visible = not DayNightCycle.is_night()
	_skip_confirm_panel.visible = false
	_skip_confirm_yes.pressed.connect(_on_skip_confirm_yes)
	_skip_confirm_no.pressed.connect(_on_skip_confirm_no)
	GardenStructureManager.watchtower_constructed.connect(_on_watchtower_constructed)
	SaveManager.load_completed.connect(_on_hud_load_completed)
	_forecast_panel.visible = false
	_status_effects_panel.visible = false
	call_deferred("_connect_wave_spawner")
	call_deferred("_connect_status_player")
	call_deferred("_show_active_night_defense_notice")


func _process(_delta: float) -> void:
	if is_instance_valid(_active_boss) and _boss_panel.visible:
		var hp: int = _active_boss.current_hp
		var max_hp: int = _active_boss.max_hp
		_boss_bar.value = float(hp)
		_boss_label.text = "%d / %d" % [hp, max_hp]

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
	_update_status_effect_countdowns(_delta)


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


func _connect_wave_spawner() -> void:
	var spawner: Node = get_tree().get_first_node_in_group(&"wave_spawners")
	if spawner == null:
		return
	_forecast_spawner = spawner as WaveSpawner
	if spawner.has_signal(&"boss_spawned") and not spawner.boss_spawned.is_connected(_on_boss_spawned):
		spawner.boss_spawned.connect(_on_boss_spawned)
	if spawner.has_signal(&"boss_defeated") and not spawner.boss_defeated.is_connected(_on_boss_defeated):
		spawner.boss_defeated.connect(_on_boss_defeated)
	if spawner.has_signal(&"forecast_updated") and not spawner.forecast_updated.is_connected(_on_forecast_updated):
		spawner.forecast_updated.connect(_on_forecast_updated)
	_refresh_watchtower_forecast()


func _on_boss_spawned(boss: Node) -> void:
	_active_boss = boss
	if boss.has_signal(&"enemy_died"):
		boss.enemy_died.connect(_on_boss_enemy_died)
	_boss_bar.max_value = float(boss.max_hp)
	_boss_bar.value = float(boss.current_hp)
	_boss_label.text = "%d / %d" % [boss.current_hp, boss.max_hp]
	_boss_panel.visible = true


func _on_boss_enemy_died(_boss: Node) -> void:
	_boss_panel.visible = false
	_active_boss = null


func _on_boss_defeated() -> void:
	_boss_panel.visible = false
	_active_boss = null


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
	if not is_night:
		_boss_panel.visible = false
		_active_boss = null
	_refresh_watchtower_forecast()


func _on_night_defense_notification_requested(
		title: String,
		message: String,
		notification_type: String,
		key: String
) -> void:
	show_notification(title, message, notification_type, null, 5.0, key)


func _show_active_night_defense_notice() -> void:
	if not NightDefenseManager.active or NightDefenseManager.is_meadow_edge_loaded():
		return
	show_notification(
			"Night has fallen",
			"The Dianthus Core is under attack. Return before it is too late.",
			"danger",
			null,
			5.0,
			"night_defense:active:%d" % NightDefenseManager.night_day)


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
	var quest: QuestData = QuestManager.get_quest_data(quest_id)
	var title: String = quest.display_name if quest != null else _humanize_id(str(quest_id))
	show_quest_completed(title)
	if is_instance_valid(_tracked_quest_panel) \
			and not _tracked_quest_panel.get("_tutorial_mode") \
			and _tracked_quest_panel.get_tracked_quest_id() == quest_id:
		_tracked_quest_panel.untrack_quest()


func _refresh_endless_label() -> void:
	_endless_label.visible = GameManager.endless_mode


func _on_watchtower_constructed() -> void:
	_refresh_watchtower_forecast()


func _on_hud_load_completed(_success: bool) -> void:
	_refresh_watchtower_forecast()
	_connect_status_player()


func _on_forecast_updated(_forecast: Dictionary) -> void:
	_refresh_watchtower_forecast()


func _refresh_watchtower_forecast() -> void:
	if not is_instance_valid(_forecast_panel):
		return
	var should_show: bool = GardenStructureManager.watchtower_built \
			and DayNightCycle.is_day() \
			and is_instance_valid(_forecast_spawner) \
			and _forecast_spawner.has_next_wave_forecast()
	_forecast_panel.visible = should_show
	if not should_show:
		return
	var forecast: Dictionary = _forecast_spawner.get_next_wave_forecast()
	var day: int = int(forecast.get("day", DayNightCycle.day_count))
	if bool(forecast.get("is_boss", false)):
		_forecast_special_label.text = "Boss: %s" % str(forecast.get("special_label", "Unknown"))
	else:
		_forecast_special_label.text = "Night %d forecast" % day
	_forecast_lanes_label.text = "Lanes: %s" % _format_forecast_lanes(forecast)
	_forecast_threats_label.text = "Threats: %s" % _format_forecast_threats(forecast)
	_forecast_count_label.text = "Total: %d" % int(forecast.get("wave_total", 0))


func _format_forecast_lanes(forecast: Dictionary) -> String:
	var labels: Array[String] = []
	var lanes: Array = forecast.get("lanes", [])
	for lane: Variant in lanes:
		if not lane is Dictionary:
			continue
		var lane_data: Dictionary = lane as Dictionary
		var count: int = int(lane_data.get("count", 0))
		if count <= 0 and not bool(forecast.get("is_boss", false)):
			continue
		labels.append("%s %d" % [str(lane_data.get("name", "Lane")), max(1, count)])
	if labels.is_empty():
		return "None"
	return ", ".join(labels)


func _on_player_registered_hud(player: Node) -> void:
	_connect_status_player(player)


func _connect_status_player(player: Node = null) -> void:
	var next_player: Node = player if player != null else GameManager.player
	if next_player == _status_player:
		_refresh_status_effects_from_player()
		return
	_disconnect_status_player()
	_clear_status_effect_items()
	_status_player = next_player
	if not is_instance_valid(_status_player):
		return
	if _status_player.has_signal("status_effect_added"):
		_status_player.status_effect_added.connect(_on_status_effect_added)
	if _status_player.has_signal("status_effect_updated"):
		_status_player.status_effect_updated.connect(_on_status_effect_updated)
	if _status_player.has_signal("status_effect_removed"):
		_status_player.status_effect_removed.connect(_on_status_effect_removed)
	if _status_player.has_signal("status_effect_expired"):
		_status_player.status_effect_expired.connect(_on_status_effect_expired)
	_refresh_status_effects_from_player()


func _disconnect_status_player() -> void:
	if not is_instance_valid(_status_player):
		_status_player = null
		return
	if _status_player.has_signal("status_effect_added") and _status_player.status_effect_added.is_connected(_on_status_effect_added):
		_status_player.status_effect_added.disconnect(_on_status_effect_added)
	if _status_player.has_signal("status_effect_updated") and _status_player.status_effect_updated.is_connected(_on_status_effect_updated):
		_status_player.status_effect_updated.disconnect(_on_status_effect_updated)
	if _status_player.has_signal("status_effect_removed") and _status_player.status_effect_removed.is_connected(_on_status_effect_removed):
		_status_player.status_effect_removed.disconnect(_on_status_effect_removed)
	if _status_player.has_signal("status_effect_expired") and _status_player.status_effect_expired.is_connected(_on_status_effect_expired):
		_status_player.status_effect_expired.disconnect(_on_status_effect_expired)
	_status_player = null


func _refresh_status_effects_from_player() -> void:
	if not is_instance_valid(_status_player):
		_clear_status_effect_items()
		return
	if not _status_player.has_method("get_active_status_effects"):
		_clear_status_effect_items()
		return
	for effect: Dictionary in _status_player.get_active_status_effects():
		_upsert_status_effect_item(effect)
	_refresh_status_effect_panel_visibility()


func _on_status_effect_added(effect: Dictionary) -> void:
	_upsert_status_effect_item(effect)


func _on_status_effect_updated(effect: Dictionary) -> void:
	_upsert_status_effect_item(effect)


func _on_status_effect_removed(effect_id: String) -> void:
	_remove_status_effect_item(effect_id)


func _on_status_effect_expired(effect_id: String) -> void:
	_remove_status_effect_item(effect_id)


func _upsert_status_effect_item(effect: Dictionary) -> void:
	var effect_id: String = str(effect.get("id", ""))
	if effect_id.is_empty():
		return
	var item: Control = _status_effect_items.get(effect_id, null)
	if not is_instance_valid(item):
		item = STATUS_EFFECT_ITEM_SCENE.instantiate() as Control
		_status_effects_container.add_child(item)
		_status_effect_items[effect_id] = item
		item.call("configure", effect)
	else:
		item.call("update_effect", effect)
	_refresh_status_effect_panel_visibility()


func _remove_status_effect_item(effect_id: String) -> void:
	var item: Control = _status_effect_items.get(effect_id, null)
	_status_effect_items.erase(effect_id)
	if is_instance_valid(item):
		item.queue_free()
	_refresh_status_effect_panel_visibility()


func _clear_status_effect_items() -> void:
	for item: Variant in _status_effect_items.values():
		if is_instance_valid(item):
			(item as Node).queue_free()
	_status_effect_items.clear()
	_refresh_status_effect_panel_visibility()


func _refresh_status_effect_panel_visibility() -> void:
	_status_effects_panel.visible = not _status_effect_items.is_empty()


func _update_status_effect_countdowns(delta: float) -> void:
	if _status_effect_items.is_empty():
		return
	_status_display_refresh_timer -= delta
	if _status_display_refresh_timer > 0.0:
		return
	_status_display_refresh_timer = STATUS_DISPLAY_REFRESH_INTERVAL
	for item: Variant in _status_effect_items.values():
		if is_instance_valid(item):
			(item as Control).call("tick_display", STATUS_DISPLAY_REFRESH_INTERVAL)


func _format_forecast_threats(forecast: Dictionary) -> String:
	var labels: Array[String] = []
	var totals: Dictionary = forecast.get("enemy_totals", {})
	for entry: Dictionary in WaveSpawner.ENEMY_POOL:
		var enemy_type: String = str(entry.get("type", ""))
		var count: int = int(totals.get(enemy_type, 0))
		if count > 0:
			labels.append("%s x%d" % [FORECAST_ENEMY_LABELS.get(enemy_type, enemy_type.capitalize()), count])
	var boss_count: int = int(totals.get("the_devourer", 0))
	if boss_count > 0:
		labels.append("%s x%d" % [FORECAST_ENEMY_LABELS["the_devourer"], boss_count])
	if labels.is_empty():
		return "None"
	return ", ".join(labels)


func _shake(node: Control) -> void:
	var original_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
	tween.tween_property(node, "position", original_pos, 0.03)


# -- Public: notification API ------------------------------------------------

func show_notification(
		title: String,
		message: String = "",
		notification_type: String = "unlock",
		icon: Texture2D = null,
		duration: float = -1.0,
		key: String = ""
) -> void:
	var resolved_duration: float = duration if duration > 0.0 else _get_notification_duration(notification_type)
	var entry: Dictionary = {
		"title": title,
		"message": message,
		"type": notification_type,
		"icon": icon,
		"duration": resolved_duration,
		"key": key,
	}
	if not key.is_empty() and _refresh_visible_notification(entry):
		return
	if not key.is_empty() and _refresh_queued_notification(entry):
		return
	_notification_queue.append(entry)
	_pump_notification_queue()


func show_item_collected(item_name: String, amount: int, icon: Texture2D = null) -> void:
	var title: String = "+%d %s" % [amount, item_name]
	show_notification(title, "Added to inventory", "item", icon, ITEM_NOTIFICATION_DURATION)


func show_codex_unlocked(entry_name: String, entry_type: String, icon: Texture2D = null) -> void:
	var type_key: String = "codex_enemy" if entry_type.to_lower() == "enemy" else "codex_plant"
	show_notification(
			"New %s Codex Entry" % entry_type,
			entry_name,
			type_key,
			icon,
			CODEX_NOTIFICATION_DURATION,
			"codex:%s:%s" % [entry_type.to_lower(), entry_name])


func show_quest_completed(quest_title: String) -> void:
	show_notification("Quest Completed", quest_title, "quest_complete", null, QUEST_COMPLETE_DURATION)


func show_quest_updated(quest_title: String, progress_text: String) -> void:
	show_notification("Quest Updated", "%s: %s" % [quest_title, progress_text], "quest_update", null, QUEST_UPDATE_DURATION)


func show_important_unlock(unlock_name: String) -> void:
	show_notification("Unlocked", unlock_name, "unlock", null, UNLOCK_NOTIFICATION_DURATION, "unlock:%s" % unlock_name)


func _on_inventory_item_added_hud(item_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var key: String = "item:%s" % item_id
	var total: int = int(_item_notification_totals.get(key, 0)) + amount
	_item_notification_totals[key] = total
	var icon: Texture2D = _load_item_icon(item_id)
	var display_name: String = ItemDatabase.get_display_name(item_id)
	show_notification(
			"+%d %s" % [total, display_name],
			"Added to inventory",
			"item",
			icon,
			ITEM_NOTIFICATION_DURATION,
			key)


func _on_plant_discovered_hud(plant_id: String) -> void:
	show_codex_unlocked(PlantRegistry.get_display_name(plant_id), "Plant")


func _on_enemy_discovered_hud(enemy_id: String) -> void:
	show_codex_unlocked(EnemyRegistry.get_display_name(enemy_id), "Enemy")


func _on_quest_progress_updated_hud(quest_id: StringName, objective_id: StringName, current: int, target: int) -> void:
	if target <= 0:
		return
	var progress_key: String = "%s:%s" % [quest_id, objective_id]
	var previous: int = int(_last_quest_progress_notifications.get(progress_key, -1))
	if current <= previous:
		return
	if current < target and previous >= 0:
		var step: int = maxi(1, int(ceil(float(target) * 0.25)))
		if current - previous < step:
			return
	_last_quest_progress_notifications[progress_key] = current
	var quest: QuestData = QuestManager.get_quest_data(quest_id)
	var quest_title: String = quest.display_name if quest != null else _humanize_id(str(quest_id))
	var objective_text: String = _get_objective_description(quest, objective_id)
	var progress_text: String = "%s (%d/%d)" % [objective_text, current, target]
	show_notification(
			"Objective Complete" if current >= target else "Quest Updated",
			"%s: %s" % [quest_title, progress_text],
			"quest_update",
			null,
			QUEST_UPDATE_DURATION,
			"quest:%s:%s" % [quest_id, objective_id])


func _on_unlock_flag_set_hud(flag_name: String) -> void:
	if flag_name.begins_with("seen_") or flag_name.begins_with("tutorial_"):
		return
	show_important_unlock(_humanize_id(flag_name.trim_prefix("unlock_")))


func _refresh_visible_notification(entry: Dictionary) -> bool:
	var key: String = str(entry.get("key", ""))
	for notification: Control in _visible_notifications:
		if is_instance_valid(notification) and str(notification.get("notification_key")) == key:
			notification.call(
					"refresh",
					str(entry.get("title", "")),
					str(entry.get("message", "")),
					str(entry.get("type", "unlock")),
					entry.get("icon", null),
					float(entry.get("duration", UNLOCK_NOTIFICATION_DURATION)))
			return true
	return false


func _refresh_queued_notification(entry: Dictionary) -> bool:
	var key: String = str(entry.get("key", ""))
	for i: int in range(_notification_queue.size()):
		if str(_notification_queue[i].get("key", "")) == key:
			_notification_queue[i] = entry
			return true
	return false


func _pump_notification_queue() -> void:
	_prune_invalid_notifications()
	while _visible_notifications.size() < MAX_VISIBLE_NOTIFICATIONS and not _notification_queue.is_empty():
		var entry: Dictionary = _notification_queue.pop_front()
		var notification: Control = NOTIFICATION_ITEM_SCENE.instantiate() as Control
		notification.set("notification_key", str(entry.get("key", "")))
		_notification_container.add_child(notification)
		_visible_notifications.append(notification)
		notification.call(
				"configure",
				str(entry.get("title", "")),
				str(entry.get("message", "")),
				str(entry.get("type", "unlock")),
				entry.get("icon", null))
		notification.connect("dismissed", _on_notification_dismissed)
		notification.call("begin", float(entry.get("duration", UNLOCK_NOTIFICATION_DURATION)))


func _on_notification_dismissed(notification: Control) -> void:
	_visible_notifications.erase(notification)
	var key: String = str(notification.get("notification_key"))
	if key.begins_with("item:"):
		_item_notification_totals.erase(key)
	_pump_notification_queue()


func _prune_invalid_notifications() -> void:
	var valid: Array[Control] = []
	for notification: Control in _visible_notifications:
		if is_instance_valid(notification):
			valid.append(notification)
	_visible_notifications = valid


func _get_notification_duration(notification_type: String) -> float:
	match notification_type:
		"item":
			return ITEM_NOTIFICATION_DURATION
		"codex_plant", "codex_enemy":
			return CODEX_NOTIFICATION_DURATION
		"quest_complete":
			return QUEST_COMPLETE_DURATION
		"quest_update":
			return QUEST_UPDATE_DURATION
		_:
			return UNLOCK_NOTIFICATION_DURATION


func _load_item_icon(item_id: String) -> Texture2D:
	var icon_path: String = ItemDatabase.get_icon_path(item_id)
	if icon_path.is_empty():
		return null
	return load(icon_path) as Texture2D


func _get_objective_description(quest: QuestData, objective_id: StringName) -> String:
	if quest == null:
		return _humanize_id(str(objective_id))
	for objective: QuestObjective in quest.objectives:
		if objective.objective_id == objective_id:
			return objective.description
	return _humanize_id(str(objective_id))


func _humanize_id(id: String) -> String:
	return id.replace("_", " ").capitalize()


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
