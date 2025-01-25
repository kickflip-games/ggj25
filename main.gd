# MAIN.gd

extends Node2D

@export var player_scene:PackedScene

@onready var spawner:=$Spawner
@onready var hud:=$Hud
@onready var input_mapper:=$InputMapper


var _player_data:Array[PlayerData]
var _current_players:Array[Player]



func _ready():
	_player_data = [
		PlayerData.new(1, $StartPositions/P1.global_position, hud.player_uis[0]),
		PlayerData.new(2, $StartPositions/P2.global_position, hud.player_uis[1]),
		PlayerData.new(3, $StartPositions/P3.global_position, hud.player_uis[2]),
		PlayerData.new(4, $StartPositions/P4.global_position, hud.player_uis[3]),
	]


func game_over():
	hud.show_game_over()
	spawner.stop()

func _instantiate_player(player_data:PlayerData):
	var player:Player = player_scene.instantiate()
	add_child(player)
	player.start(player_data)
	player.powerup_activated.connect($Shockwave.create_shock)
	_current_players.append(player)
	player.player_died.connect(_on_player_died)
	#%GameCam.append_follow_targets(player)



func new_game(num_players:int):
	# clear any already present mobs / pickups 
	get_tree().call_group("mobs", "queue_free")
	
	
	for i in range(num_players):
		_instantiate_player(_player_data[i])
	
	 # not the best place... but whatever.. maybe (call_groups(player) for each player connect )...
	spawner.start()

func _on_hud_start_game():
	new_game(2)


func _on_player_died():
	game_over()
