extends Node

signal flag_set(flag_name: String)

var _flags: Dictionary = {}


func set_flag(flag_name: String) -> void:
	if _flags.get(flag_name, false):
		return
	_flags[flag_name] = true
	flag_set.emit(flag_name)
	print("[UnlockFlags] Set: %s" % flag_name)


func has_flag(flag_name: String) -> bool:
	return _flags.get(flag_name, false)


func clear_flag(flag_name: String) -> void:
	_flags.erase(flag_name)


func serialize() -> Dictionary:
	return _flags.duplicate()


func deserialize(data: Variant) -> void:
	_flags = {}
	if not data is Dictionary:
		return
	for k: String in (data as Dictionary):
		if (data as Dictionary)[k]:
			_flags[k] = true
	print("[UnlockFlags] Deserialized: %d flags active." % _flags.size())
