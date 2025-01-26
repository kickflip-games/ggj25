extends CanvasLayer
class_name HUD

@export var score_container_scene:PackedScene


@onready var game_text:= $StartMarginContainer/GameText
@onready var start_button:= $StartMarginContainer/StartGameButton
@onready var back_button:= $BackButton
@onready var start_seq:=$StartSequence
@onready var time_label:= $GameUi/TimeLabel
@onready var player_uis:=[
	$GameUi/P1Ui,
	$GameUi/P2Ui,
	$GameUi/P3Ui,
	$GameUi/P4Ui
]

@onready var final_score_box:= $StartMarginContainer/FinalScores
@onready var instructions_box := $StartMarginContainer/Instructions

signal start_game


func _ready():
	back_button.hide()


func show_game_over(player_scores:Array):
	_show_message("Game Over")
	start_button.show()
	time_label.hide()
	back_button.hide()
	instructions_box.hide()
	
	for child in final_score_box.get_children():
		child.queue_free() 
	
	for i in range(len(player_scores)):
		var score_display = score_container_scene.instantiate() 
		final_score_box.add_child(score_display)
		score_display.create(i, player_scores[i])

func show_start_game_txt():
	_show_message("Start game?")
	instructions_box.show()

func _show_message(text):
	game_text.text = text
	game_text.show()


func _on_start_game_button_pressed():
	start_button.hide()
	game_text.hide()
	print_debug("Start game pressed")
	start_game.emit(start_seq.mapping_screen.num_players)
	time_label.show()
	back_button.show()
	instructions_box.hide()
		
	for child in final_score_box.get_children():
		child.queue_free() 

func update_timer(time_remaining:int):
	# Convert time_remaining to MM:SS format and update the label
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining % 60)
	time_label.text = "%02d:%02d" % [minutes, seconds]


func _on_back_button_pressed():
	get_tree().reload_current_scene()
