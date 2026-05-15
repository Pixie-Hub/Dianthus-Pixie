extends CanvasLayer

@onready var _bar: ProgressBar = %ProgressBar
@onready var _label: Label = %Label

var _prev_hp: int = -1

func _ready() -> void:
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
	if GameManager.core_current_hp >= 0:
		_on_core_hp_changed(GameManager.core_current_hp, GameManager.core_max_hp)

func _on_core_hp_changed(current_hp: int, max_hp: int) -> void:
	_bar.max_value = max_hp
	_bar.value = current_hp
	_label.text = "DIANTHUS CORE  %d / %d" % [current_hp, max_hp]
	if _prev_hp >= 0 and current_hp < _prev_hp:
		_shake()
	_prev_hp = current_hp

func _shake() -> void:
	var node: Control = _bar.get_parent().get_parent()
	var original_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
	tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
	tween.tween_property(node, "position", original_pos, 0.03)
