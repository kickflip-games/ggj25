extends Node2D

var PLAYER_BUTTONS = {
	"player1": 0,
	"player2": 0,
	"player3": 0,
	"player4": 0
}


func _ready():
	for player_id in PLAYER_BUTTONS.keys():
		PLAYER_BUTTONS[player_id]= InputMap.action_get_events(player_id)
		print(player_id, " key is ", PLAYER_BUTTONS[player_id])
	
func remap_key(player_id:String, event:InputEvent):
	InputMap.action_erase_events(player_id)
	InputMap.action_add_event(player_id, event)
	#PLAYER_BUTTONS[player_id] = event.
	

#
## Set up the button for each player at the start
#func set_player_button(player: String, key: int) -> void:
	#PLAYER_BUTTONS[player] = key
	#print(player, " button set to: ", OS.get_scancode_string(key))
#
