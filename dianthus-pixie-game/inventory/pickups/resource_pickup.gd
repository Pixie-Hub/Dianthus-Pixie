extends Area2D

@export var item_id: String = "petal_shard"
@export var amount: int = 1

var _color_rect: ColorRect = null


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_create_visual()


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
	if not body.is_in_group("player") and not (body is CharacterBody2D and body.name == "Player"):
		return
	var overflow: int = InventoryManager.add_item(item_id, amount)
	if overflow > 0:
		_show_popup("Inventory Full!", Color(1.0, 0.4, 0.4))
	else:
		var display: String = ItemDatabase.get_display_name(item_id)
		_show_popup("+%d %s" % [amount, display], Color(1.0, 1.0, 0.6))
		queue_free()


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
