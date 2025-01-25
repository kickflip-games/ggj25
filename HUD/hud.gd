extends CanvasLayer
class_name HUD

@onready var game_text:= $StartMarginContainer/GameText
@onready var start_button:= $StartMarginContainer/StartGameButton
@onready var time_label:= $MarginContainer/TimeLabel
@onready var player_uis:=[
	$MarginContainer/P1Ui,
	$MarginContainer/P2Ui,
	$MarginContainer/P3Ui,
	$MarginContainer/P4Ui	
]

signal start_game

func show_game_over():
	_show_message("Game Over")
	update_timer(0)
	start_button.show()
	time_label.hide()

func show_start_game_txt():
	_show_message("Start game?")

func _show_message(text):
	game_text.text = text
	game_text.show()

func _on_start_game_button_pressed():
	start_button.hide()
	game_text.hide()
	print_debug("Start game pressed")
	start_game.emit()
	time_label.show()
	
	
func update_timer(time_remaining:int):
	# Convert time_remaining to MM:SS format and update the label
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining % 60)
	time_label.text = "%02d:%02d" % [minutes, seconds]
