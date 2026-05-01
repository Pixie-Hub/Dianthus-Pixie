extends Area2D

const HARVEST_QTE_SCENE: PackedScene = preload("res://minigames/harvest_qte/harvest_qte_screen.tscn")

@export var item_id: String = "petal_shard"
@export var amount: int = 1

var _color_rect: ColorRect = null
var _tutorial_hint: Node2D = null
var _tutorial_hint_tween: Tween = null
var _pickup_pending: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_create_visual()
	if TutorialManager.is_phase_1_active():
		set_tutorial_hint_active(true)


func _create_visual() -> void:
	var icon_path: String = ItemDatabase.get_icon_path(item_id)
	if not icon_path.is_empty():
		var tex: Texture2D = load(icon_path) as Texture2D
		if tex != null:
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(0.5, 0.5)
			add_child(sprite)
			return
	_color_rect = ColorRect.new()
	_color_rect.size = Vector2(8.0, 8.0)
	_color_rect.position = Vector2(-4.0, -4.0)
	_color_rect.color = ItemDatabase.get_rarity_color(item_id)
	add_child(_color_rect)


func _on_body_entered(body: Node2D) -> void:
	if _pickup_pending:
		return
	if not body.is_in_group("player") and not (body is CharacterBody2D and body.name == "Player"):
		return
	_pickup_pending = true
	if _should_start_harvest_qte():
		_start_harvest_qte()
	else:
		_grant_pickup(amount, false)


func _should_start_harvest_qte() -> bool:
	var rarity: int = ItemDatabase.get_rarity(item_id)
	return rarity == ItemDatabase.Rarity.UNCOMMON or rarity == ItemDatabase.Rarity.RARE


func _start_harvest_qte() -> void:
	var qte_screen: Node = HARVEST_QTE_SCENE.instantiate()
	get_tree().current_scene.add_child(qte_screen)
	qte_screen.connect("finished", _on_harvest_qte_finished)
	qte_screen.call("start_qte", item_id, amount)


func _on_harvest_qte_finished(success: bool) -> void:
	var granted_amount: int = amount if success else int(floor(float(amount) * 0.5))
	_grant_pickup(granted_amount, not success)


func _grant_pickup(granted_amount: int, reduced_reward: bool) -> void:
	var overflow: int = InventoryManager.add_item(item_id, granted_amount)
	if overflow > 0:
		_show_popup("Inventory Full!", Color(1.0, 0.4, 0.4))
		_pickup_pending = false
	else:
		var display: String = ItemDatabase.get_display_name(item_id)
		if reduced_reward:
			_show_popup("+%d %s (Reduced Harvest)" % [granted_amount, display], Color(1.0, 0.7, 0.25))
		else:
			_show_popup("+%d %s" % [granted_amount, display], Color(1.0, 1.0, 0.6))
		set_tutorial_hint_active(false)
		queue_free()


func set_tutorial_hint_active(active: bool) -> void:
	if active:
		if is_instance_valid(_tutorial_hint):
			return
		_tutorial_hint = Node2D.new()
		_tutorial_hint.name = "TutorialHint"
		add_child(_tutorial_hint)

		var ring: Line2D = Line2D.new()
		ring.width = 1.5
		ring.default_color = Color(1.0, 0.9, 0.25, 0.9)
		ring.closed = true
		for i: int in range(18):
			var angle: float = TAU * float(i) / 18.0
			ring.add_point(Vector2(cos(angle), sin(angle)) * 12.0)
		_tutorial_hint.add_child(ring)

		var arrow: Label = Label.new()
		arrow.text = "^"
		arrow.position = Vector2(-3.0, -24.0)
		arrow.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25, 1.0))
		arrow.add_theme_font_size_override("font_size", 10)
		_tutorial_hint.add_child(arrow)

		_tutorial_hint_tween = create_tween().set_loops()
		_tutorial_hint_tween.tween_property(_tutorial_hint, "position:y", -3.0, 0.45)
		_tutorial_hint_tween.tween_property(_tutorial_hint, "position:y", 1.0, 0.45)
		return
	if is_instance_valid(_tutorial_hint_tween):
		_tutorial_hint_tween.kill()
	_tutorial_hint_tween = null
	if is_instance_valid(_tutorial_hint):
		_tutorial_hint.queue_free()
	_tutorial_hint = null


func _show_popup(text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.position = Vector2(-24, -16)
	label.z_index = 10
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-24, -16)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 20.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)
