extends SceneTree
var game
var lobby
var mapping
func _initialize():
	call_deferred("run")
func key(code):
	var e = InputEventKey.new()
	e.keycode = code
	return e
func capture(name):
	await create_timer(0.3).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/lobby_redesign/after/" + name)
	print("CAPTURE ", name)
func run():
	seed(250125)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await process_frame
	lobby = game.hud.start_seq.lobby
	mapping = game.hud.start_seq.mapping_screen
	await capture("00_title.png")
	game.hud.start_seq.show_lobby()
	await capture("01_default.png")
	lobby.assign_input(0,key(KEY_SPACE))
	lobby._enable(2)
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	lobby.assign_input(2,mouse)
	mapping.finish_capture()
	await capture("02_two_players.png")
	lobby._enable(1)
	lobby.assign_input(1,key(KEY_F))
	lobby._enable(3)
	lobby.assign_input(3,key(KEY_G))
	mapping.finish_capture()
	await capture("03_four_players.png")
	mapping.start_capture(2)
	await capture("04_input_mapping.png")
	mapping.finish_capture()
	lobby._disable(1)
	lobby._disable(3)
	lobby.request_start()
	game.spawner.stop()
	await create_timer(2.5).timeout
	paused = true
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/lobby_redesign/after/05_gameplay.png")
	print("CAPTURE 05_gameplay.png")
	paused = false
	game._current_players[0].score_manager._score = 120
	game._current_players[1].score_manager._score = 240
	game.game_over()
	await capture("06_results.png")
	quit()
