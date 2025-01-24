extends CanvasLayer

@onready var game_text:= $MarginContainer/GameText
@onready var start_button:= $MarginContainer/MarginContainer/StartGameButton
@onready var player_ui:=$MarginContainer/PlayerUi


signal start_game


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
	player_ui.reset()
	print_debug("Start game pressed")
	start_game.emit()
	
	
