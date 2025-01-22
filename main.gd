extends Node2D

@onready var player:=$Player
@onready var spawner:=$Spawner
@onready var hud:=$Hud


func game_over():
	hud.show_game_over()
	spawner.stop()

func new_game():
	# clear any already present mobs 
	get_tree().call_group("mobs", "queue_free")
	player.start($StartPositionMarker.position, hud.player_ui)
	spawner.start()

func _on_hud_start_game():
	new_game()


func _on_player_player_died():
	game_over()
	
