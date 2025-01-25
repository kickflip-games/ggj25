# MAIN.gd

extends Node2D

@export var player_scene:PackedScene

@onready var spawner:=$Spawner
@onready var hud:=$Hud


var _current_players:Array[Player]

func game_over():
	hud.show_game_over()
	spawner.stop()

func _instantiate_player(pos:Vector2, ui):
	var player:Player = player_scene.instantiate()
	add_child(player)
	player.start(pos, ui)
	player.powerup_activated.connect($Shockwave.create_shock)
	_current_players.append(player)
	player.player_died.connect(_on_player_died)



func new_game():
	# clear any already present mobs / pickups 
	get_tree().call_group("mobs", "queue_free")
	_instantiate_player($StartPositionMarker.position, $Hud.player_ui)
	
	 # not the best place... but whatever.. maybe (call_groups(player) for each player connect )...
	spawner.start()

func _on_hud_start_game():
	new_game()


func _on_player_died():
	game_over()
