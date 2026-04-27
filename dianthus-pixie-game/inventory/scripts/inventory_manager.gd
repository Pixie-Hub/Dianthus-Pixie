extends Node

signal inventory_changed
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal inventory_full

var max_slots: int = 30
# TODO: WORLD-06 — expand max_slots to 60 via Garden Storage upgrade.

var slots: Array[Dictionary] = []


func _ready() -> void:
	_init_slots()


func _init_slots() -> void:
	slots.clear()
	for i: int in range(max_slots):
		slots.append({})


# --- Public API ---

func add_item(item_id: String, amount: int = 1) -> int:
	var remaining: int = amount
	var max_stack: int = ItemDatabase.get_max_stack(item_id)

	# 1. Stack into existing slots that already hold this item.
	for i: int in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[i]
		if slot.is_empty() or slot.get("item_id", "") != item_id:
			continue
		var space: int = max_stack - int(slot.get("count", 0))
		if space <= 0:
			continue
		var to_add: int = min(remaining, space)
		slot["count"] += to_add
		remaining -= to_add
		SfxManager.play("item_stack")
		item_added.emit(item_id, to_add)

	# 2. Fill empty slots.
	for i: int in range(slots.size()):
		if remaining <= 0:
			break
		if not slots[i].is_empty():
			continue
		var to_add: int = min(remaining, max_stack)
		slots[i] = {"item_id": item_id, "count": to_add}
		remaining -= to_add
		SfxManager.play("item_pickup")
		item_added.emit(item_id, to_add)

	var added: int = amount - remaining
	if added > 0:
		inventory_changed.emit()
	if remaining > 0:
		SfxManager.play("inventory_full")
		inventory_full.emit()
	return remaining


func remove_item(item_id: String, amount: int = 1) -> bool:
	if get_total_count(item_id) < amount:
		return false
	var remaining: int = amount
	for i: int in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[i]
		if slot.is_empty() or slot.get("item_id", "") != item_id:
			continue
		var count: int = int(slot.get("count", 0))
		var to_remove: int = min(remaining, count)
		count -= to_remove
		remaining -= to_remove
		if count <= 0:
			slots[i] = {}
		else:
			slot["count"] = count
	inventory_changed.emit()
	item_removed.emit(item_id, amount - remaining)
	return true


func has_item(item_id: String, amount: int = 1) -> bool:
	return get_total_count(item_id) >= amount


func get_total_count(item_id: String) -> int:
	var total: int = 0
	for slot: Dictionary in slots:
		if slot.is_empty():
			continue
		if slot.get("item_id", "") == item_id:
			total += int(slot.get("count", 0))
	return total


func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	return slots[index]


func swap_slots(a: int, b: int) -> void:
	if a < 0 or a >= slots.size() or b < 0 or b >= slots.size():
		return
	var temp: Dictionary = slots[a].duplicate()
	slots[a] = slots[b].duplicate()
	slots[b] = temp
	inventory_changed.emit()


func clear_all() -> void:
	_init_slots()
	inventory_changed.emit()


# --- Serialization (for SaveManager) ---

func serialize() -> Array:
	return slots.duplicate(true)


func deserialize(data: Array) -> void:
	_init_slots()
	var count: int = min(data.size(), max_slots)
	for i: int in range(count):
		var entry: Variant = data[i]
		if entry is Dictionary and not (entry as Dictionary).is_empty():
			slots[i] = (entry as Dictionary).duplicate()
	inventory_changed.emit()
