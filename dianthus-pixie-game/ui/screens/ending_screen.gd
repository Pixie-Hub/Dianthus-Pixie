extends CanvasLayer

const _ENDING_COPY: Dictionary = {
	"true": {
		"title": "TRUE ENDING — Bloom Eternal",
		"subtitle": "The Devourer falls. The garden breathes again.",
		"accent": Color(1.0, 0.85, 0.3, 1),
		"body": "Dianthus's full potential blossoms across the meadow. Light returns to every petal you tended. The Voidlord's shadow is no more, and a new dawn rests on the horizon.",
	},
	"survival": {
		"title": "SURVIVAL ENDING — Open Skies",
		"subtitle": "You held the line. The story is not yet finished.",
		"accent": Color(0.7, 0.7, 0.85, 1),
		"body": "Twenty nights survived. The garden endures, but Dianthus's deepest secrets remain sealed. Whispers from beyond linger — perhaps another seed will wake what this one could not.",
	},
	"discovery": {
		"title": "DISCOVERY ENDING — A New Bloom",
		"subtitle": "Dianthus has become more than a flower.",
		"accent": Color(0.55, 0.95, 0.55, 1),
		"body": "Through every cross-pollination and every catalogued bud, Dianthus has woken. It is no longer simply a plant — it walks with you now, breathing, learning, growing.",
	},
}

const CREDITS_TEXT: String = "Dianthus Pixie — Demo Build\nA garden defense story.\nEngine: Godot 4.x\nPlants, code, and pixels by the team."

@onready var _accent_bar: ColorRect = %AccentBar
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _credits_label: Label = %CreditsLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _endless_button: Button = %EndlessButton


func _ready() -> void:
	visible = false
	EndingManager.ending_triggered.connect(_on_ending)
	_continue_button.pressed.connect(_on_continue)
	_main_menu_button.pressed.connect(_on_main_menu)
	_endless_button.pressed.connect(_on_endless)


func _on_ending(ending_id: String) -> void:
	var copy: Dictionary = _ENDING_COPY.get(ending_id, _ENDING_COPY["survival"])
	_accent_bar.color = copy["accent"]
	_title_label.text = copy["title"]
	_subtitle_label.text = copy["subtitle"]
	_body_label.text = copy["body"]
	_stats_label.text = "Day reached: %d  •  Plants discovered: %d / %d" % [
		DayNightCycle.day_count,
		CodexManager.get_discovered_count(),
		CodexManager.get_total_count(),
	]
	_credits_label.text = CREDITS_TEXT
	_endless_button.visible = UnlockFlags.has_flag(StoryEndingFlags.unlock_endless_mode)
	SfxManager.play("ending_screen")
	get_tree().paused = true
	visible = true


func _on_continue() -> void:
	SfxManager.play("ui_button_click")
	get_tree().paused = false
	visible = false


func _on_main_menu() -> void:
	SfxManager.play("ui_button_click")
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")


func _on_endless() -> void:
	SfxManager.play("ui_button_click")
	SfxManager.play("endless_mode_activate")
	GameManager.endless_mode = true
	get_tree().paused = false
	visible = false
	print("[EndingScreen] Endless Mode activated.")
