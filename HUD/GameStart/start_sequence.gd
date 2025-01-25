extends Control

signal start_game

@onready var title_screen = $TitleScreen
@onready var mapping_screen = $MappingScreen

func _ready() -> void:
	mapping_screen.hide()

func _on_title_screen_button_pressed(num_players: int) -> void:
	mapping_screen.num_players = num_players
	title_screen.hide()
	mapping_screen.show()
	
func _on_mapping_screen_keys_mapped() -> void:
	start_game.emit()
	mapping_screen.hide()
