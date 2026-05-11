class_name QuestData
extends Resource

enum Type { DAILY, PROGRESS, DISCOVERY, STORY }

@export var quest_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var quest_type: Type = Type.DAILY
@export var objectives: Array[QuestObjective] = []
@export var reward_items: Dictionary = {}
@export var reward_weapons: Array[String] = []
@export var reward_unlock_flags: Array[String] = []
@export var time_limit_days: int = 0
@export var dialogic_timeline_on_start: String = ""
@export var dialogic_timeline_on_complete: String = ""
@export var dialogic_timeline_on_fail: String = ""
@export var next_quest_id: StringName = &""
@export var auto_start: bool = false
@export var failure_unlock_flags: Array[String] = []
@export var failure_next_quest_id: StringName = &""
