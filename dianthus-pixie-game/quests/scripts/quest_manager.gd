extends Node

const QUEST_DIR := "res://quests/data/"

signal quest_started(quest_id: StringName)
signal quest_progress_updated(quest_id: StringName, objective_id: StringName, current: int, target: int)
signal quest_completed(quest_id: StringName)
signal quest_failed(quest_id: StringName, reason: String)
signal quest_rewards_granted(quest_id: StringName, items: Dictionary, weapons: Array)

var _registry: Dictionary = {}
var _active: Dictionary = {}
var _completed: Dictionary = {}
var _failed: Dictionary = {}


func _ready() -> void:
	_scan_registry()
	_connect_event_sources()
	_connect_dialogic()
	for q: QuestData in _registry.values():
		if q.auto_start and not is_completed(q.quest_id):
			start_quest(q.quest_id)


# ── Public API ────────────────────────────────────────────────────────────────

func start_quest(id: StringName) -> bool:
	if not _registry.has(id):
		push_warning("[QuestManager] Unknown quest id: %s" % id)
		return false
	if _active.has(id) or _completed.has(id):
		return false
	var q: QuestData = _registry[id]
	var prog: Dictionary = {}
	for obj: QuestObjective in q.objectives:
		prog[obj.objective_id] = 0
	_active[id] = {"progress": prog, "started_day": DayNightCycle.day_count}
	quest_started.emit(id)
	SfxManager.play("quest_accepted")
	print("[QuestManager] Started: %s" % id)
	return true


func complete_quest(id: StringName) -> void:
	if not _active.has(id):
		return
	var q: QuestData = _registry.get(id)
	if q == null:
		return
	_active.erase(id)
	_completed[id] = true
	quest_completed.emit(id)
	SfxManager.play("quest_completed")
	_grant_rewards(q)
	print("[QuestManager] Completed: %s" % id)
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic != null and q.dialogic_timeline_on_complete != "":
		dialogic.start(q.dialogic_timeline_on_complete)
	if q.next_quest_id != &"" and _registry.has(q.next_quest_id):
		start_quest(q.next_quest_id)


func fail_quest(id: StringName, reason: String) -> void:
	if not _active.has(id):
		return
	var q: QuestData = _registry.get(id)
	var is_story_timeout: bool = q != null \
		and q.quest_type == QuestData.Type.STORY \
		and reason == "time_limit"
	if is_story_timeout:
		for flag: String in q.failure_unlock_flags:
			UnlockFlags.set_flag(flag)
		print("[QuestManager] Story-quest soft-fail: %s — alt-ending flags set" % id)
	_active.erase(id)
	_failed[id] = reason
	quest_failed.emit(id, reason)
	SfxManager.play("quest_failed")
	print("[QuestManager] Failed: %s  reason: %s" % [id, reason])
	if q == null:
		return
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic != null and q.dialogic_timeline_on_fail != "":
		dialogic.start(q.dialogic_timeline_on_fail)
	if is_story_timeout and q.failure_next_quest_id != &"" and _registry.has(q.failure_next_quest_id):
		start_quest(q.failure_next_quest_id)


func is_active(id: StringName) -> bool:
	return _active.has(id)


func is_completed(id: StringName) -> bool:
	return _completed.has(id)


func get_active_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for id: StringName in _active:
		if _registry.has(id):
			result.append(_registry[id] as QuestData)
	return result


func get_completed_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for id: StringName in _completed:
		if _registry.has(id):
			result.append(_registry[id] as QuestData)
	return result


func get_progress(id: StringName) -> Dictionary:
	if not _active.has(id):
		return {}
	var q: QuestData = _registry.get(id)
	if q == null:
		return {}
	var prog: Dictionary = _active[id].get("progress", {})
	var result: Dictionary = {}
	for obj: QuestObjective in q.objectives:
		result[obj.objective_id] = {
			"current": prog.get(obj.objective_id, 0),
			"target": obj.target_count,
			"description": obj.description,
		}
	return result


func get_started_day(id: StringName) -> int:
	return int(_active.get(id, {}).get("started_day", 0))


func get_failed_quests() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in _failed:
		if _registry.has(id):
			out.append({"quest": _registry[id], "reason": _failed[id]})
	return out


func get_active_quest_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in _active:
		result.append(id)
	return result


func get_quest_type(id: StringName) -> QuestData.Type:
	var q: QuestData = _registry.get(id)
	if q == null:
		return QuestData.Type.DAILY
	return q.quest_type


func get_quests_by_type(type: QuestData.Type) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for q: QuestData in _registry.values():
		if q.quest_type == type:
			result.append(q)
	return result


func silent_drop_quest(id: StringName) -> void:
	if not _active.has(id):
		return
	_active.erase(id)
	print("[QuestManager] Silently dropped daily quest: %s" % id)


func report_event(event_id: StringName, amount: int = 1, context: Dictionary = {}) -> void:
	for quest_id: StringName in _active.keys():
		var q: QuestData = _registry.get(quest_id)
		if q == null:
			continue
		var prog: Dictionary = _active[quest_id].get("progress", {})
		var all_done: bool = true
		for obj: QuestObjective in q.objectives:
			if obj.event_id == event_id and _matches_filter(obj.filter, context):
				var new_val: int = mini(prog.get(obj.objective_id, 0) + amount, obj.target_count)
				prog[obj.objective_id] = new_val
				quest_progress_updated.emit(quest_id, obj.objective_id, new_val, obj.target_count)
			if prog.get(obj.objective_id, 0) < obj.target_count:
				all_done = false
		if all_done and q.objectives.size() > 0:
			complete_quest(quest_id)
			return


# ── Serialization ─────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var active_data: Dictionary = {}
	for id: StringName in _active:
		var prog: Dictionary = _active[id].get("progress", {})
		var prog_str: Dictionary = {}
		for k: StringName in prog:
			prog_str[str(k)] = prog[k]
		active_data[str(id)] = {
			"progress": prog_str,
			"started_day": _active[id].get("started_day", 1),
		}
	var completed_data: Dictionary = {}
	for id: StringName in _completed:
		completed_data[str(id)] = true
	var failed_data: Dictionary = {}
	for id: StringName in _failed:
		failed_data[str(id)] = _failed[id]
	return {
		"active": active_data,
		"completed": completed_data,
		"failed": failed_data,
	}


func deserialize(data: Dictionary) -> void:
	_active = {}
	_completed = {}
	_failed = {}
	var active_raw: Variant = data.get("active", {})
	if active_raw is Dictionary:
		for id_str: String in (active_raw as Dictionary):
			var entry: Variant = (active_raw as Dictionary)[id_str]
			if entry is Dictionary:
				var prog_raw: Variant = (entry as Dictionary).get("progress", {})
				var prog: Dictionary = {}
				if prog_raw is Dictionary:
					for k: String in (prog_raw as Dictionary):
						prog[StringName(k)] = int((prog_raw as Dictionary)[k])
				_active[StringName(id_str)] = {
					"progress": prog,
					"started_day": (entry as Dictionary).get("started_day", 1),
				}
	var completed_raw: Variant = data.get("completed", {})
	if completed_raw is Dictionary:
		for id_str: String in (completed_raw as Dictionary):
			_completed[StringName(id_str)] = true
	var failed_raw: Variant = data.get("failed", {})
	if failed_raw is Dictionary:
		for id_str: String in (failed_raw as Dictionary):
			_failed[StringName(id_str)] = str((failed_raw as Dictionary)[id_str])
	print("[QuestManager] Deserialized: %d active, %d completed, %d failed" % [
		_active.size(), _completed.size(), _failed.size()])


# ── Internal ──────────────────────────────────────────────────────────────────

func _scan_registry() -> void:
	_registry.clear()
	_scan_dir(QUEST_DIR)
	print("[QuestManager] Registry: %d quests found." % _registry.size())


func _scan_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		if dir.current_is_dir() and entry_name != "." and entry_name != "..":
			_scan_dir(path + entry_name + "/")
		elif entry_name.ends_with(".tres"):
			var res: Resource = load(path + entry_name)
			if res is QuestData:
				var qd: QuestData = res as QuestData
				if qd.quest_id != &"":
					_registry[qd.quest_id] = qd
		entry_name = dir.get_next()
	dir.list_dir_end()


func _connect_event_sources() -> void:
	InventoryManager.item_added.connect(_on_item_added)
	DayNightCycle.phase_changed.connect(_on_phase_changed)
	BreedingManager.breed_succeeded.connect(_on_breed_succeeded)
	BreedingManager.combo_attempted.connect(_on_combo_attempted)
	CodexManager.plant_discovered.connect(_on_plant_discovered)
	CraftingManager.weapon_crafted.connect(_on_weapon_crafted)
	call_deferred("_connect_scene_nodes")


func _connect_scene_nodes() -> void:
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		_connect_enemy_signals(enemy)
	get_tree().node_added.connect(_on_node_added_to_tree)


func _on_node_added_to_tree(node: Node) -> void:
	if node.has_signal("enemy_died"):
		call_deferred("_connect_enemy_signals", node)


func _connect_enemy_signals(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_signal("enemy_died"):
		if not enemy.is_connected("enemy_died", _on_enemy_died_for_quest):
			enemy.connect("enemy_died", _on_enemy_died_for_quest)


func _on_enemy_died_for_quest(enemy: Node) -> void:
	var enemy_type: String = ""
	var scr: Script = enemy.get_script() as Script
	if scr != null:
		enemy_type = scr.resource_path.get_file().get_basename()
	report_event(&"enemy_killed", 1, {"enemy_type": enemy_type})


func _connect_dialogic() -> void:
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic == null:
		push_warning("[QuestManager] Dialogic singleton not found — story quest hooks disabled.")
		return
	if dialogic.has_signal("signal_event"):
		dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(arg: Variant) -> void:
	var s: String = str(arg)
	var parts: PackedStringArray = s.split(":", false, 1)
	if parts.size() != 2:
		return
	var cmd: String = parts[0]
	var qid: StringName = StringName(parts[1])
	match cmd:
		"quest_start":    start_quest(qid)
		"quest_complete": complete_quest(qid)
		"quest_fail":     fail_quest(qid, "dialogic")


func _grant_rewards(q: QuestData) -> void:
	for item_id: String in q.reward_items:
		var amount: int = int(q.reward_items[item_id])
		if amount > 0:
			InventoryManager.add_item(item_id, amount)
	for weapon_id: String in q.reward_weapons:
		CraftingManager.owned_weapons[weapon_id] = true
	for flag: String in q.reward_unlock_flags:
		UnlockFlags.set_flag(flag)
	quest_rewards_granted.emit(q.quest_id, q.reward_items, q.reward_weapons)
	print("[QuestManager] Rewards granted for %s — items=%s  weapons=%s  flags=%s" % [
		q.quest_id, q.reward_items, q.reward_weapons, q.reward_unlock_flags])


func _matches_filter(filter: Dictionary, context: Dictionary) -> bool:
	for key: String in filter:
		if not context.has(key):
			return false
		if str(context[key]) != str(filter[key]):
			return false
	return true


func _on_item_added(item_id: String, amount: int) -> void:
	report_event(&"item_collected", amount, {"item_id": item_id})


func _on_phase_changed(phase: String) -> void:
	if phase == "DAY":
		DailyQuestRoller.roll_for_day(DayNightCycle.day_count)
		report_event(&"day_survived", 1, {"day": DayNightCycle.day_count})
		_check_time_limits()
		_maybe_start_story_chain()


func _check_time_limits() -> void:
	for quest_id: StringName in _active.keys():
		var q: QuestData = _registry.get(quest_id)
		if q == null or q.time_limit_days <= 0:
			continue
		if q.quest_type == QuestData.Type.DAILY:
			continue
		var started_day: int = _active[quest_id].get("started_day", DayNightCycle.day_count)
		var elapsed_days: int = DayNightCycle.day_count - started_day
		if elapsed_days >= q.time_limit_days:
			fail_quest(quest_id, "time_limit")


func _on_breed_succeeded(combo_id: String, output_seed_id: String) -> void:
	report_event(&"plant_bred", 1, {"plant_id": output_seed_id, "combo_id": combo_id})


func _on_plant_discovered(plant_id: String) -> void:
	report_event(&"plant_discovered", 1, {"plant_id": plant_id})


func _on_weapon_crafted(weapon_id: String) -> void:
	report_event(&"weapon_crafted", 1, {"weapon_id": weapon_id})


func _on_combo_attempted(combo_id: String, success: bool) -> void:
	report_event(&"combo_attempted", 1, {"combo_id": combo_id, "success": str(success)})


func _maybe_start_story_chain() -> void:
	if UnlockFlags.has_flag(StoryEndingFlags.flag_story_chain_started):
		return
	if DayNightCycle.day_count < 2:
		return
	if _registry.has(&"story_01_whispers"):
		start_quest(&"story_01_whispers")


func _on_voidlord_defeated() -> void:
	# TODO: DIFF-03 — call this from Voidlord boss _die()
	report_event(&"voidlord_defeated", 1, {})


func _on_devourer_defeated() -> void:
	# TODO: ENEMY-05 — call this from Devourer boss _die()
	report_event(&"devourer_defeated", 1, {})
