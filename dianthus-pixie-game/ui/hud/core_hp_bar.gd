extends CanvasLayer

@onready var _bar: ProgressBar = %ProgressBar
@onready var _label: Label = %Label


func _ready() -> void:
	GameManager.core_hp_changed.connect(_on_core_hp_changed)


func _on_core_hp_changed(current_hp: int, max_hp: int) -> void:
	_bar.max_value = max_hp
	_bar.value = current_hp
	_label.text = "DIANTHUS CORE  %d / %d" % [current_hp, max_hp]
