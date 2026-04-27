extends Node

const DAILY_COUNT: int = 2

var last_rolled_day: int = 0
var current_daily_ids: Array[StringName] = []


func roll_for_day(day: int) -> void:
	if day == last_rolled_day:
		return
	for id: StringName in QuestManager.get_active_quest_ids():
		if QuestManager.get_quest_type(id) == QuestData.Type.DAILY:
			QuestManager.silent_drop_quest(id)
	var pool: Array[QuestData] = QuestManager.get_quests_by_type(QuestData.Type.DAILY)
	pool.shuffle()
	current_daily_ids = []
	var count: int = mini(DAILY_COUNT, pool.size())
	for i: int in range(count):
		var q: QuestData = pool[i]
		if QuestManager.start_quest(q.quest_id):
			current_daily_ids.append(q.quest_id)
	last_rolled_day = day
	print("[DailyQuestRoller] Day %d — rolled %d daily quests: %s" % [
		day, current_daily_ids.size(), current_daily_ids])


func force_reroll() -> void:
	last_rolled_day = -1
	roll_for_day(DayNightCycle.day_count)
	print("[DailyQuestRoller] Force-rerolled daily quests.")


func serialize() -> Dictionary:
	var ids: Array = []
	for id: StringName in current_daily_ids:
		ids.append(str(id))
	return {
		"last_rolled_day": last_rolled_day,
		"current_daily_ids": ids,
	}


func deserialize(data: Variant) -> void:
	last_rolled_day = 0
	current_daily_ids = []
	if not data is Dictionary:
		return
	var d: Dictionary = data as Dictionary
	last_rolled_day = int(d.get("last_rolled_day", 0))
	var ids_raw: Variant = d.get("current_daily_ids", [])
	if ids_raw is Array:
		for id_str: Variant in (ids_raw as Array):
			current_daily_ids.append(StringName(str(id_str)))
	print("[DailyQuestRoller] Deserialized: last_rolled_day=%d  daily_ids=%s" % [
		last_rolled_day, current_daily_ids])
