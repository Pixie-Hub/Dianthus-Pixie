extends Node

signal pause_state_changed(is_paused: bool)

var _holders: Dictionary = {}
var _last_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _process(_delta: float) -> void:
	_sync_pause_state()


func request_pause(owner: Object) -> void:
	if owner == null:
		return
	_holders[owner.get_instance_id()] = weakref(owner)
	set_process(true)
	get_tree().paused = true
	_emit_if_changed(true)


func release_pause(owner: Object) -> void:
	if owner != null:
		_holders.erase(owner.get_instance_id())
	_sync_pause_state()


func clear_all() -> void:
	_holders.clear()
	set_process(false)
	get_tree().paused = false
	_emit_if_changed(false)


func is_pause_requested() -> bool:
	_cleanup_holders()
	return not _holders.is_empty()


func _sync_pause_state() -> void:
	_cleanup_holders()
	var should_pause: bool = not _holders.is_empty()
	get_tree().paused = should_pause
	set_process(should_pause)
	_emit_if_changed(should_pause)


func _emit_if_changed(is_paused: bool) -> void:
	if is_paused != _last_paused:
		_last_paused = is_paused
		pause_state_changed.emit(is_paused)


func _cleanup_holders() -> void:
	for id in _holders.keys():
		var holder_ref: WeakRef = _holders[id] as WeakRef
		if holder_ref == null or holder_ref.get_ref() == null:
			_holders.erase(id)
