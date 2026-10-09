extends Control
signal match_requested(configuration: Array)
@onready var title_screen = $TitleScreen
@onready var lobby = $Lobby
@onready var mapping_screen = $MappingScreen

func _ready():
	title_screen.play_requested.connect(show_lobby)
	lobby.capture_requested.connect(mapping_screen.start_capture)
	lobby.match_requested.connect(_start_match)
	mapping_screen.input_chosen.connect(_on_input_chosen)

func _on_input_chosen(slot_id: int, event: InputEvent):
	var error = lobby.assign_input(slot_id, event)
	if error.is_empty():
		mapping_screen.finish_capture()
	else:
		mapping_screen.warning.text = error

func _start_match(configuration: Array):
	mapping_screen.finish_capture()
	hide()
	match_requested.emit(configuration)

func show_lobby():
	title_screen.hide()
	lobby.show()
	lobby.refresh()
	show()

func return_to_lobby():
	mapping_screen.finish_capture()
	show_lobby()
