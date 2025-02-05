extends PanelContainer

class_name Hud

const WARNING_THRESHOLD = 10

@onready var time_label: Label = $HBoxContainer/TimeLabel
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var lives_label: Label = $HBoxContainer/LivesLabel

func _ready() -> void:
	update_time(Globals.remaining_time, true)
	update_lives(Globals.lives)
	update_score(Globals.score)
	Globals.level_time_changed.connect(update_time)
	Globals.player_lives_changed.connect(update_lives)
	Globals.score_changed.connect(update_score)

func update_time(time: int, no_sound: bool = false) -> void:
	time_label.text = "Time: " + str(time)
	
	if no_sound: return

	if time <= WARNING_THRESHOLD:
		time_label.add_theme_color_override("font_color", Color(1, 0, 0))

		if time == 1:
			SoundsPlayer.play_sound("timer_last_tick")
		else:
			SoundsPlayer.play_sound("timer_tick")
	else:
		time_label.add_theme_color_override("font_color", Color(1, 1, 1))

func update_score(score: int) -> void:
	score_label.text = "Score: " + str(score)

func update_lives(lives: int) -> void:
	lives_label.text = "Lives: " + str(lives)
