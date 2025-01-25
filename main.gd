# MAIN.gd

extends Node2D

@export var player_scene:PackedScene

@onready var spawner:=$Spawner
@onready var hud:=$Hud
@onready var game_timer:=$GameTimer
@export var game_time:float = 4

var _game_playing:bool= false


var _player_data:Array[PlayerData]
var _current_players:Array[Player]





func _ready():
	_init_player_data()
	
func _init_player_data():
	_player_data = [
		PlayerData.new(0, $StartPositions/P1.global_position, hud.player_uis[0]),
		PlayerData.new(1, $StartPositions/P2.global_position, hud.player_uis[1]),
		PlayerData.new(2, $StartPositions/P3.global_position, hud.player_uis[2]),
		PlayerData.new(3, $StartPositions/P4.global_position, hud.player_uis[3]),
	]


func game_over():
	hud.show_game_over()
	spawner.stop()
	_game_playing = false
	TimeManager.slow_to_pause()
	for _p in _current_players:
		_p.die()
		_p.queue_free()
	_current_players.clear()

func _instantiate_player(player_data:PlayerData):
	var player:Player = player_scene.instantiate()
	add_child(player)
	player.name = player_data.name
	player.start(player_data)
	player.powerup_activated.connect($Shockwave.create_shock)
	_current_players.append(player)
	

func new_game(num_players:int):
	TimeManager.reset()
	# clear any already present mobs / pickups 
	get_tree().call_group("mobs", "queue_free")
	
	
	for i in range(num_players):
		_instantiate_player(_player_data[i])
	
	 # not the best place... but whatever.. maybe (call_groups(player) for each player connect )...
	spawner.start()
	game_timer.start(game_time)
	_game_playing = true

	

func _on_hud_start_game(num_players: int):
	new_game(num_players)
	hud.update_timer(game_time)


func _process(_delta):
	if _game_playing:
		hud.update_timer(game_timer.time_left)

func _on_game_timer_timeout():
	game_over()
