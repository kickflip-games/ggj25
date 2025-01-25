class_name PlayerUi
extends VBoxContainer


@onready var _bar = $PowerupBar

const HEART_CHAR = '\u2764'
const EMPTY_HEART_CHAR = '\u2661'






func reset():
	update_score(0)
	update_health(Globals.MAX_HP)
	reset_bar()
	


func update_score(score:int):
	$ScoreLabel.text = str(score)

func update_health(health:int):
	var hearts_display = HEART_CHAR.repeat(health) + EMPTY_HEART_CHAR.repeat(Globals.MAX_HP - health)
	$HealthLabel.text = hearts_display
	play_hp_fx()


func reset_bar():
	_bar.max_value = Globals.POWERUP_THRESHOLD
	_bar.value = 0 

func update_bar(value):
	_bar.value = value


func play_combo_fx(combo_multiplier:int):
	print("TODO: play_combo_fx for UI")
	
func play_hp_fx():
	print("TODO: play_hp_fx for UI")
	
func play_powerup_mode_fx():
	print("TODO: play_powerup_mode_fx for UI")
