extends Control

@onready var game_text:= $MarginContainer/GameText
@onready var score_text:= $MarginContainer/VBoxContainer/ScoreLabel
@onready var health_text:= $MarginContainer/VBoxContainer/HealthLabel
@onready var start_button:= $MarginContainer/MarginContainer/StartGameButton

const HEART_CHAR = 'U+2764'
const EMPTY_HEART_CHAR = 'U+2661'
const MAX_HP = 3

signal start_game

func update_score(score):
	score_text.text = str(score)

func update_health(health):
	var hearts_display = HEART_CHAR.repeat(health) + EMPTY_HEART_CHAR.repeat(MAX_HP - health)
	health_text.text = hearts_display

func show_game_over():
	_show_message("Game Over")
	start_button.show()


func show_start_game_txt():
	_show_message("Start game?")


func _show_message(text):
	game_text.text = text
	game_text.show()
	

func _on_start_game_button_pressed():
	start_button.hide()
	game_text.hide()
	update_health(MAX_HP)
	update_score(0)
	print_debug("Start game pressed")
	start_game.emit()
	
	
