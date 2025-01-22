class_name PlayerUi
extends VBoxContainer



const HEART_CHAR = '\u2764'
const EMPTY_HEART_CHAR = '\u2661'


func reset():
	update_score(0)
	update_health(Globals.MAX_HP)


func update_score(score:int):
	$ScoreLabel.text = str(score)

func update_health(health):
	var hearts_display = HEART_CHAR.repeat(health) + EMPTY_HEART_CHAR.repeat(Globals.MAX_HP - health)
	$HealthLabel.text = hearts_display
