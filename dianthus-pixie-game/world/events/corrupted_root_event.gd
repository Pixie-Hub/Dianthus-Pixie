class_name CorruptedRootEvent
extends DaytimeEvent

signal spawn_sealed(direction_position: Vector2)

const ROOT_HP: int = 50
const ATTACK_RANGE: float = 20.0
const ATTACK_DAMAGE: int = 12
const DAMAGE_FLASH_DURATION: float = 0.12

var _current_hp: int = ROOT_HP
var _attack_cooldown: float = 0.0
const ATTACK_COOLDOWN_TIME: float = 1.2

@onready var _hp_bar: ColorRect = %HpBar
@onready var _hp_bar_bg: ColorRect = %HpBarBg


func _ready() -> void:
	event_id = &"corrupted_root"
	event_display_name = "Corrupted Root"
	event_color = Color(0.35, 0.1, 0.5, 1.0)
	super._ready()


func _on_activated() -> void:
	_current_hp = ROOT_HP
	_update_hp_bar()


func _on_player_enter() -> void:
	_update_prompt("[E] Destroy Root (HP: %d)" % _current_hp)


func _on_player_exit() -> void:
	_update_prompt("")


func _process(delta: float) -> void:
	if not _is_active or _is_complete:
		return
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _player_in_range and _is_active:
		_update_prompt("[E] Destroy Root (HP: %d)" % _current_hp)


func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_deal_damage()
		get_viewport().set_input_as_handled()


func _deal_damage() -> void:
	var player: Node = GameManager.player
	if not is_instance_valid(player):
		return
	var weapon_damage: int = 8
	if player.has_method("get") and player.get("_current_weapon") != null:
		var w: WeaponData = player.get("_current_weapon") as WeaponData
		if w != null:
			weapon_damage = w.damage
	_current_hp = max(_current_hp - weapon_damage, 0)
	_update_hp_bar()
	_flash_damage()
	SfxManager.play_at("enemy_hit", global_position, 0.1)

	if _attack_cooldown <= 0.0 and is_instance_valid(player) and player.has_method("take_damage"):
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= ATTACK_RANGE + 12.0:
			player.take_damage(ATTACK_DAMAGE)
			_attack_cooldown = ATTACK_COOLDOWN_TIME

	if _current_hp <= 0:
		_finish_event()


func _flash_damage() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color(1.0, 0.3, 0.3, 1.0), DAMAGE_FLASH_DURATION)
	tween.tween_property(_visual, "modulate", Color.WHITE, DAMAGE_FLASH_DURATION)


func _give_reward() -> void:
	spawn_sealed.emit(global_position)
	_show_reward_popup("Spawn point sealed tonight!")


func _update_hp_bar() -> void:
	if not is_instance_valid(_hp_bar):
		return
	var ratio: float = float(_current_hp) / float(ROOT_HP)
	_hp_bar.size.x = _hp_bar_bg.size.x * ratio


func _show_reward_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	label.position = Vector2(-60, -40)
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-60, -32)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(label.queue_free)
