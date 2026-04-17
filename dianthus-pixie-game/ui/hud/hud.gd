extends CanvasLayer

@onready var _player_bar: ProgressBar = %PlayerHPBar
@onready var _player_label: Label = %PlayerHPLabel
@onready var _core_bar: ProgressBar = %CoreHPBar
@onready var _core_label: Label = %CoreHPLabel
@onready var _player_container: MarginContainer = %PlayerHPContainer
@onready var _core_container: MarginContainer = %CoreHPContainer

var _prev_player_hp: int = -1
var _prev_core_hp: int = -1


func _ready() -> void:
	GameManager.player_hp_changed.connect(_on_player_hp_changed)
	GameManager.core_hp_changed.connect(_on_core_hp_changed)


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


func _shake(node: Control) -> void:
	var original_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
	tween.tween_property(node, "position", original_pos, 0.03)
