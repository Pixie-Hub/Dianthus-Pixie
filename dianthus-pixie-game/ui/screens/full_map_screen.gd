extends CanvasLayer

@onready var _title_label: Label = %TitleLabel
@onready var _map_view: Control = %FullMapView

var _is_open: bool = false


func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	call_deferred("_sync_zone_context")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map_toggle"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _is_open:
		return
	SfxManager.play("screen_open")
	_is_open = true
	visible = true
	_sync_zone_context()
	if _map_view.has_method("refresh_references"):
		_map_view.call("refresh_references")
	PauseManager.request_pause(self)


func close() -> void:
	if not _is_open:
		return
	SfxManager.play("screen_close")
	_is_open = false
	visible = false
	PauseManager.release_pause(self)


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func _exit_tree() -> void:
	if _is_open:
		PauseManager.release_pause(self)


func _sync_zone_context() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	if scene_root.has_method("get_map_bounds"):
		_map_view.set("world_bounds", scene_root.get_map_bounds())
	if scene_root.has_method("get_map_display_name"):
		_title_label.text = "%s MAP" % scene_root.get_map_display_name().to_upper()
