extends Control

signal keys_mapped

var curr_player: int
@onready var player_text:= $PlayerText
@onready var use_warning:= $AlreadyInUse

var num_players = 1
var used_keys = []

func _ready() -> void:
	curr_player = 1
	use_warning.modulate.a = 0.0


func _input(event):
	if event is InputEventKey and event.pressed:
		if curr_player <= num_players:
			if event.keycode in used_keys:
				print("Key already used:", event.keycode)
				var tween = create_tween()
				tween.tween_property(use_warning, "modulate:a", 1.0, 0.1)
			else:
				use_warning.modulate.a = 0.0
				curr_player += 1
				
				if curr_player == (num_players + 1):
					keys_mapped.emit()
							
				_update_player_label()
				remap_key("player" + str(curr_player - 2), event)
				used_keys.append(event.keycode)
		
				
func remap_key(player_id:String, event:InputEvent):
	print("Before remapping ", player_id, InputMap.action_get_events(player_id))
	InputMap.action_erase_events(player_id)
	InputMap.action_add_event(player_id, event) 
	print("After remapping ", player_id, InputMap.action_get_events(player_id))


func _update_player_label():
	if curr_player <= num_players:
		player_text.text = "Player %d" % curr_player
