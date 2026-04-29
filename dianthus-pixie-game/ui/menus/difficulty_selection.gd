extends Control

signal difficulty_selected(tier_id: int)

@onready var _easy_btn: Button = %EasyButton
@onready var _normal_btn: Button = %NormalButton
@onready var _hard_btn: Button = %HardButton


func _ready() -> void:
	visible = false
	_easy_btn.pressed.connect(_on_easy_pressed)
	_normal_btn.pressed.connect(_on_normal_pressed)
	_hard_btn.pressed.connect(_on_hard_pressed)


func open() -> void:
	SfxManager.play("screen_open")
	visible = true


func close() -> void:
	SfxManager.play("screen_close")
	visible = false


func _on_easy_pressed() -> void:
	SfxManager.play("ui_button_click")
	DifficultyManager.set_tier(DifficultyManager.Tier.EASY)
	difficulty_selected.emit(DifficultyManager.Tier.EASY)
	close()


func _on_normal_pressed() -> void:
	SfxManager.play("ui_button_click")
	DifficultyManager.set_tier(DifficultyManager.Tier.NORMAL)
	difficulty_selected.emit(DifficultyManager.Tier.NORMAL)
	close()


func _on_hard_pressed() -> void:
	SfxManager.play("ui_button_click")
	DifficultyManager.set_tier(DifficultyManager.Tier.HARD)
	difficulty_selected.emit(DifficultyManager.Tier.HARD)
	close()
