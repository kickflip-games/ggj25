extends Control

signal button_pressed(num_players: int)

func _on_single_player_pressed() -> void:
	print("Single Player Pressed.")
	button_pressed.emit(1)

func _on_two_player_pressed() -> void:
	print("Two Player Pressed.")
	button_pressed.emit(2)

func _on_three_player_pressed() -> void:
	print("Three Player Pressed.")
	button_pressed.emit(3)

func _on_four_player_pressed() -> void:
	print("Four Player Pressed.")
	button_pressed.emit(4)
