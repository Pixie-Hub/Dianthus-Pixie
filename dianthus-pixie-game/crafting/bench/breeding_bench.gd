extends StaticBody2D

@onready var _prompt_label: Label = $PromptLabel
@onready var _interaction_zone: Area2D = $InteractionZone

var _player_in_range: bool = false


func _ready() -> void:
	collision_layer = CollisionLayers.INTERACTABLE
	collision_mask = 0
	_prompt_label.visible = false
	_interaction_zone.body_entered.connect(_on_body_entered)
	_interaction_zone.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		if DayNightCycle.is_night():
			print("[BreedingBench] Cannot craft at night.")
			return
		var screen: Node = get_tree().current_scene.find_child("CrossBreedingScreen", true, false)
		if screen != null and screen.has_method("open"):
			screen.open()
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = true
		_prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_in_range = false
		_prompt_label.visible = false
