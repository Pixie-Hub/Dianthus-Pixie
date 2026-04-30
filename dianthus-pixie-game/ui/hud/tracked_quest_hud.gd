class_name TrackedQuestHUD
extends Control
## TrackedQuestHUD
## Displays either a standard quest (via QuestManager tracking) or tutorial
## objectives (pushed by TutorialManager) in the HUD.
##
## Two modes:
##   Standard mode  — set via track_quest(id). Reads from QuestManager.get_progress().
##   Tutorial mode  — set via set_tutorial_mode(true) + set_tutorial_phase(...).

signal tracked_quest_changed(quest_id: StringName)

# ── Node refs ──────────────────────────────────────────────────────────────────
@onready var _title_label: Label = %QuestTitleLabel
@onready var _obj_labels: Array[Label] = [
	%Objective1Label,
	%Objective2Label,
	%Objective3Label,
	%Objective4Label,
]
@onready var _progress_bar: ProgressBar = %QuestProgressBar

# ── State ──────────────────────────────────────────────────────────────────────
var _tracked_id: StringName = &""
var _tutorial_mode: bool = false


func _ready() -> void:
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_failed.connect(_on_quest_failed)
	QuestManager.quest_tracked.connect(_on_quest_tracked)
	QuestManager.quest_untracked.connect(_on_quest_untracked)
	visible = false


# ── Public API — Standard Quest Tracking ──────────────────────────────────────

func track_quest(quest_id: StringName) -> void:
	if _tutorial_mode:
		return  # tutorial has priority
	if _tracked_id == quest_id:
		return
	_tracked_id = quest_id
	_tutorial_mode = false
	tracked_quest_changed.emit(quest_id)
	_refresh_standard()
	visible = true


func untrack_quest() -> void:
	if _tutorial_mode:
		return  # tutorial has priority
	_tracked_id = &""
	tracked_quest_changed.emit(&"")
	visible = false


func get_tracked_quest_id() -> StringName:
	return _tracked_id


func is_tracking() -> bool:
	return _tracked_id != &"" or _tutorial_mode


# ── Public API — Tutorial Mode ─────────────────────────────────────────────────

func set_tutorial_mode(enabled: bool) -> void:
	_tutorial_mode = enabled
	if not enabled:
		# Revert to standard tracking if a quest was pinned
		if _tracked_id != &"":
			_refresh_standard()
			visible = true
		else:
			visible = false


func set_tutorial_phase(
		phase_name: String,
		objectives: Array[String],
		completed: Array[bool]) -> void:
	if not _tutorial_mode:
		return
	_title_label.text = phase_name
	var total: int = objectives.size()
	var done_count: int = 0
	for i: int in range(_obj_labels.size()):
		var lbl: Label = _obj_labels[i]
		if i < total:
			lbl.visible = true
			var is_done: bool = completed[i] if i < completed.size() else false
			lbl.text = "%s %s" % ["[x]" if is_done else "[ ]", objectives[i]]
			lbl.modulate = Color(0.7, 0.9, 0.7, 1.0) if is_done else Color(0.85, 0.84, 0.78, 1.0)
			if is_done:
				done_count += 1
		else:
			lbl.visible = false
	_progress_bar.value = float(done_count) / float(maxi(total, 1))
	visible = true


# ── Internal ───────────────────────────────────────────────────────────────────

func _refresh_standard() -> void:
	if _tracked_id == &"":
		return
	var prog: Dictionary = QuestManager.get_progress(_tracked_id)
	if prog.is_empty():
		# Quest may be completed/failed already
		var q_data: QuestData = _get_quest_data(_tracked_id)
		_title_label.text = q_data.display_name if q_data != null else str(_tracked_id)
		for lbl: Label in _obj_labels:
			lbl.visible = false
		_progress_bar.value = 1.0
		return
	var q_data: QuestData = _get_quest_data(_tracked_id)
	_title_label.text = q_data.display_name if q_data != null else str(_tracked_id)
	var obj_ids: Array = prog.keys()
	var total: int = obj_ids.size()
	var done_count: int = 0
	for i: int in range(_obj_labels.size()):
		var lbl: Label = _obj_labels[i]
		if i < total:
			lbl.visible = true
			var entry: Dictionary = prog[obj_ids[i]]
			var current: int = int(entry.get("current", 0))
			var target: int = int(entry.get("target", 1))
			var desc: String = str(entry.get("description", obj_ids[i]))
			var is_done: bool = (current >= target)
			lbl.text = "%s %s (%d/%d)" % ["[x]" if is_done else "[ ]", desc, current, target]
			lbl.modulate = Color(0.7, 0.9, 0.7, 1.0) if is_done else Color(0.85, 0.84, 0.78, 1.0)
			if is_done:
				done_count += 1
		else:
			lbl.visible = false
	_progress_bar.value = float(done_count) / float(maxi(total, 1))


func _get_quest_data(id: StringName) -> QuestData:
	# Access internal registry via QuestManager's get_active_quests + completed
	var all_active: Array[QuestData] = QuestManager.get_active_quests()
	for q: QuestData in all_active:
		if q.quest_id == id:
			return q
	var all_completed: Array[QuestData] = QuestManager.get_completed_quests()
	for q: QuestData in all_completed:
		if q.quest_id == id:
			return q
	return null


func _on_quest_progress_updated(
		quest_id: StringName,
		_obj_id: StringName,
		_current: int,
		_target: int) -> void:
	if _tutorial_mode:
		return
	if quest_id == _tracked_id:
		_refresh_standard()


func _on_quest_completed(quest_id: StringName) -> void:
	if _tutorial_mode:
		return
	if quest_id == _tracked_id:
		untrack_quest()


func _on_quest_failed(quest_id: StringName, _reason: String) -> void:
	if _tutorial_mode:
		return
	if quest_id == _tracked_id:
		untrack_quest()


func _on_quest_tracked(quest_id: StringName) -> void:
	if _tutorial_mode:
		return  # tutorial has display priority
	_tracked_id = quest_id
	tracked_quest_changed.emit(quest_id)
	_refresh_standard()
	visible = true


func _on_quest_untracked() -> void:
	if _tutorial_mode:
		return
	_tracked_id = &""
	tracked_quest_changed.emit(&"")
	visible = false
