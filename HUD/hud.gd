extends CanvasLayer
class_name HUD

@export var score_container_scene:PackedScene


@onready var game_text:= $StartMarginContainer/GameText
@onready var start_button:= $StartMarginContainer/StartGameButton
@onready var pause_menu:= $PauseMenu
@onready var continue_button:= $PauseMenu/Center/Options/ContinueButton
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
	pause_menu.hide()
	$StartMarginContainer.hide()
	start_seq.match_requested.connect(_on_lobby_match_requested)
	start_button.text = "Back to Lobby"

func _on_lobby_match_requested(configuration: Array):
	$StartMarginContainer.hide()
	start_game.emit(configuration)
	time_label.show()
	pause_menu.hide()

func show_lobby():
	$StartMarginContainer.hide()
	pause_menu.hide()
	time_label.hide()
	_stop_flashing()
	for ui in player_uis:
		ui.hide()
	for child in final_score_box.get_children():
		child.queue_free()
	start_seq.return_to_lobby()

func show_game_over(player_scores:Array):
	$StartMarginContainer.show()
	_show_message("Game Over")
	start_button.show()
	time_label.hide()
	pause_menu.hide()
	instructions_box.hide()
	
	for child in final_score_box.get_children():
		child.queue_free() 
	
	var max_score = 0
	for entry in player_scores:
		max_score = max(max_score, entry.score)

	
	for i in range(len(player_scores)):
		var score_display = score_container_scene.instantiate() 
		final_score_box.add_child(score_display)
		var is_winner = (player_scores[i].score == max_score)
		score_display.create(player_scores[i].id, player_scores[i].score, is_winner, player_scores[i].get("cpu", false))  # Pass winner status
		

func show_start_game_txt():
	_show_message("Start game?")
	instructions_box.show()

func _show_message(text):
	game_text.text = text
	game_text.show()


func _on_start_game_button_pressed():
	get_parent().return_to_lobby()


var flashing := false
var flash_tween: Tween = null

func update_timer(time_remaining: int):
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining % 60)
	time_label.text = "%02d:%02d" % [minutes, seconds]

	if time_remaining < 10 and not flashing:
		_start_flashing()
	elif time_remaining >= 10 and flashing:
		_stop_flashing()


func _start_flashing():
	flashing = true
	flash_tween = create_tween()
	flash_tween.set_loops()  # loop forever
	flash_tween.tween_property(time_label, "modulate", Color.RED, 0.3).set_trans(Tween.TRANS_SINE)
	flash_tween.tween_property(time_label, "modulate", Color.WHITE, 0.3).set_trans(Tween.TRANS_SINE)

func _stop_flashing():
	if flash_tween:
		flash_tween.kill()
	time_label.modulate = Color.WHITE
	flashing = false

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if get_parent()._game_playing:
			_set_paused(not get_tree().paused)
			get_viewport().set_input_as_handled()

func _set_paused(value: bool):
	pause_menu.visible = value
	get_tree().paused = value
	if value:
		MusicManager.pause_music()
		continue_button.grab_focus()
	else:
		MusicManager.resume_music()
		continue_button.release_focus()

func _on_continue_button_pressed():
	_set_paused(false)

func _on_back_button_pressed():
	_set_paused(false)
	get_parent().return_to_lobby()
