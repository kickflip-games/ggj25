extends Control

signal keys_mapped

var num_players = 1
var curr_player: int
var player_text: Label


func _ready() -> void:
	player_text = get_node("PlayerText")
	curr_player = 1


func _input(event):
	if event is InputEventKey and event.pressed and curr_player <= num_players:
		curr_player += 1
		
		if curr_player == (num_players + 1):
			keys_mapped.emit()
			
		_update_player_label()
		remap_key("player" + str(curr_player - 2), event)
		
				
func remap_key(player_id:String, event:InputEvent):
	print("Before remapping ", player_id, InputMap.action_get_events(player_id))
	InputMap.action_erase_events(player_id)
	InputMap.action_add_event(player_id, event) 
	print("After remapping ", player_id, InputMap.action_get_events(player_id))


func _update_player_label():
	if curr_player <= num_players:
		player_text.text = "Player %d" % curr_player
