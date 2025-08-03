"""
StartSequence
- TitleScreen
- MappingScreen
"""
extends Control
@onready var title_screen = $TitleScreen
@onready var mapping_screen = $MappingScreen

func _ready() -> void:
	mapping_screen.hide()
	# Connect the visibility changed signal if you want to track state changes
	mapping_screen.visibility_changed.connect(mapping_screen._on_visibility_changed)

func _on_title_screen_button_pressed(num_players: int) -> void:
	mapping_screen.num_players = num_players
	title_screen.hide()
	mapping_screen.show()
	# Start the mapping process after showing the screen
	mapping_screen.start_mapping()
	
func _on_mapping_screen_keys_mapped() -> void:
	mapping_screen.hide()
	self.hide()
