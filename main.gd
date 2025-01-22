extends Node2D

@onready var player:=$Player
@onready var spawner:=$Spawner
@onready var hud:=$Hud

var score = 0




func game_over():
	hud.show_game_over()
	spawner.stop()

func new_game():
	# clear any already present mobs 
	get_tree().call_group("mobs", "queue_free")
	score = 0
	player.start($StartPositionMarker.position)
	spawner.start()

func _on_hud_start_game():
	new_game()


func _on_player_player_died():
	game_over()
	

func _on_player_player_taken_damage(hp:int):
	hud.update_health(hp)
	


func _on_spawner_increment_score():
	score += 1
	hud.update_score(score)
