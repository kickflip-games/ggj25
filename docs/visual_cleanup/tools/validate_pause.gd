extends SceneTree
var game
var failures = 0
var checks = 0

func _initialize():
	call_deferred("run")

func check(condition, message):
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func escape(echo = false):
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await escape()
	check(not paused and not game.hud.pause_menu.visible, "Escape at title does not pause")
	var mapping = game.hud.start_seq.mapping_screen
	mapping.start_capture(0)
	await escape()
	check(mapping.capturing_slot == -1, "Escape cancels lobby capture")
	game.hud.start_seq.hide()
	game.hud.get_node("StartMarginContainer").hide()
	game.new_game(selected([0,1]))
	game.hud.time_label.show()
	game.spawner.stop()
	for mob in get_nodes_in_group("mobs"):
		mob.queue_free()
	await process_frame
	var player = game._current_players[0]
	player.position = Vector2(500, 540)
	game._current_players[1].position = Vector2(900, 540)
	player._on_score_powerup_ready()
	await create_timer(0.2).timeout
	await escape()
	check(paused and game.hud.pause_menu.visible, "Escape opens pause menu")
	check(game.hud.continue_button.has_focus(), "Continue receives keyboard focus")
	var round_left = game.game_timer.time_left
	var power_left = player.powerup_timer.time_left
	var pos = player.position
	var direction = player._next_direction
	var event = InputEventAction.new()
	event.action = "player0"
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(0.4).timeout
	event.pressed = false
	Input.parse_input_event(event)
	check(is_equal_approx(game.game_timer.time_left, round_left), "round timer stops while paused")
	check(is_equal_approx(player.powerup_timer.time_left, power_left), "Star Power timer stops while paused")
	check(player.position.is_equal_approx(pos) and player._next_direction == direction, "player input and physics stop while paused")
	check(root.get_node("MusicManager").powerup_player.stream_paused, "music pauses")
	await escape(true)
	check(paused, "Escape auto-repeat cannot toggle pause")
	root.size = Vector2i(1920, 1080)
	await process_frame
	RenderingServer.force_draw()
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("res://docs/visual_cleanup/after/04_pause.png")
	await escape()
	check(not paused and not game.hud.pause_menu.visible, "Escape resumes gameplay")
	await create_timer(0.2).timeout
	check(player.powerup_timer.time_left < power_left and game.game_timer.time_left < round_left, "both timers resume from their remaining time")
	check(not root.get_node("MusicManager").powerup_player.stream_paused, "music resumes")
	await escape()
	game.hud.continue_button.pressed.emit()
	check(not paused, "Continue button resumes")
	await escape()
	game.hud.get_node("PauseMenu/Center/Options/BackButton").pressed.emit()
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	check(not paused, "Back to Main clears tree pause")
	check(current_scene == game and game._current_players.is_empty(), "Back to Main returns to editable lobby")
	check(not current_scene.hud.pause_menu.visible and current_scene.hud.start_seq.lobby.visible, "fresh title has no pause overlay")
	check(root.get_node("MusicManager").current_mode == 0, "Back to Main restores normal music")
	current_scene.new_game(selected([0]))
	check(current_scene._current_players.size() == 1 and current_scene._game_playing, "a new round starts after returning to title")
	game = current_scene
	game._current_players[0]._on_score_powerup_ready()
	await escape()
	game.hud.get_node("PauseMenu/Center/Options/BackButton").pressed.emit()
	await create_timer(0.4).timeout
	check(root.get_node("MusicManager").current_mode == 0, "immediate Back during power-music crossfade returns to normal music")
	check(not paused and game.hud.start_seq.visible, "immediate Back returns to an unpaused lobby")
	print("RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func selected(ids: Array) -> Array:
	var config_script = load("res://HUD/GameStart/player_slot_config.gd")
	var configs = []
	for id in ids:
		var config = config_script.new(id)
		config.mode = 1
		var binding = InputEventKey.new()
		binding.keycode = [KEY_ENTER, KEY_SPACE, KEY_F, KEY_G][id]
		config.binding = binding
		configs.append(config)
	return configs
