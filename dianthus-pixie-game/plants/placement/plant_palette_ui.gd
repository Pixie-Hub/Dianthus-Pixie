extends CanvasLayer

const PlantPaletteSlotScene: PackedScene = preload("res://plants/placement/plant_palette_slot.tscn")

var _manager: Node = null
var _texture_cache: Dictionary = {}
var _refresh_queued: bool = false
@onready var _panel: PanelContainer = %PalettePanel
@onready var _scroll: ScrollContainer = %PaletteScroll
@onready var _hbox: HBoxContainer = %PlantSlotList


func setup(manager: Node) -> void:
	_manager = manager
	InventoryManager.inventory_changed.connect(queue_refresh)


func _ready() -> void:
	visible = false


func _position_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var panel_size: Vector2 = _panel.size
	if panel_size == Vector2.ZERO:
		return
	_panel.position = Vector2(
		(640.0 - panel_size.x) / 2.0,
		360.0 - panel_size.y - 4.0
	)


func refresh() -> void:
	_refresh_queued = false
	if not is_instance_valid(_hbox):
		return
	if not is_instance_valid(_manager):
		return
	for child: Node in _hbox.get_children():
		_hbox.remove_child(child)
		child.queue_free()

	for seed_id: String in _manager.SEED_TO_SCENE.keys():
		for quality: int in range(ItemDatabase.QUALITY_NAMES.size()):
			var count: int = InventoryManager.get_total_count(seed_id, quality)
			if count <= 0:
				continue
			_add_seed_slot(seed_id, quality, count)

	var slot_count: int = _hbox.get_child_count()
	var content_width: float = slot_count * (40 + 4) + 8.0
	_scroll.custom_minimum_size.x = min(content_width, 320.0)

	await get_tree().process_frame
	_position_panel()


func _add_seed_slot(seed_id: String, quality: int, count: int) -> void:
	var slot: PlantPaletteSlot = PlantPaletteSlotScene.instantiate() as PlantPaletteSlot
	var texture: Texture2D = _get_seed_texture(seed_id)
	var selected: bool = seed_id == _manager.selected_seed_id and quality == _manager.selected_seed_quality
	_hbox.add_child(slot)
	slot.bind_slot(seed_id, quality, count, texture, selected)
	slot.slot_clicked.connect(_on_slot_clicked)


func _seed_to_plant_id(seed_id: String) -> String:
	return seed_id.trim_suffix("_seed")


func _get_seed_texture(seed_id: String) -> Texture2D:
	if _texture_cache.has(seed_id):
		return _texture_cache[seed_id] as Texture2D

	var plant_id: String = _seed_to_plant_id(seed_id)
	var sprite_path: String = PlantRegistry.get_sprite_path(plant_id)
	if not sprite_path.is_empty():
		var sprite: Texture2D = load(sprite_path) as Texture2D
		if sprite != null:
			_texture_cache[seed_id] = sprite
			return sprite

	var icon_path: String = ItemDatabase.get_icon_path(seed_id)
	if not icon_path.is_empty():
		var icon: Texture2D = load(icon_path) as Texture2D
		if icon != null:
			_texture_cache[seed_id] = icon
		return icon
	return null


func _on_slot_clicked(seed_id: String, quality: int) -> void:
	if is_instance_valid(_manager):
		_manager.select_seed(seed_id, quality)
		queue_refresh()


func show_palette() -> void:
	visible = true
	queue_refresh()


func hide_palette() -> void:
	visible = false


func queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("refresh")
