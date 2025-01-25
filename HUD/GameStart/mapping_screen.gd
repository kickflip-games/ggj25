extends Control

var num_players = 4 # TODO: Link this up with the button press on previous screen
var curr_player: int

var player_text: Label
var player_mappings = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_text = get_node("PlayerText")
	curr_player = 1
	
func _process(_delta: float) -> void:
	if player_mappings.size() == num_players:
		hide()
		# Start game
	
func _input(event):
	if event is InputEventKey and event.pressed and player_mappings.size() < num_players:
		curr_player += 1
		player_mappings.append(event.keycode)
		_update_player_label()

func _update_player_label():
	if curr_player <= num_players:
		player_text.text = "Player %d" % curr_player 
