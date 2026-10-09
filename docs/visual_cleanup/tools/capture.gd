extends SceneTree

var game
var output: String

func _initialize():
	call_deferred("run")

func run():
	seed(250125)
	output = OS.get_cmdline_user_args()[0]
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920, 1080)
	await process_frame
	game.hud.get_node("StartSequence").hide()
	game.hud.get_node("StartMarginContainer").hide()
	game.new_game(selected([0,1]))
	game.hud.time_label.show()
	game.spawner.stop()
	game.game_timer.stop()
	game._game_playing = false
	game.hud.update_timer(90)
	for i in range(4):
		var ui = game.hud.player_uis[i]
		ui.reset(i)
		ui.show()
		ui.update_score([128, 96, 64, 32][i])
		ui.update_health([3, 2, 3, 1][i])
		ui.update_bar([2, 1, 2, 1][i])
	# Fixed objects use original scenes and rendering, isolated from the normal entry point.
	for child in game.spawner.get_children():
		if child is RigidBody2D or child.is_in_group("mobs"):
			child.queue_free()
	await process_frame
	var spots = [Vector2(650, 360), Vector2(1100, 430), Vector2(1300, 700), Vector2(800, 780)]
	for pos in spots:
		var enemy = game.spawner.enemy_scenes[0].instantiate()
		game.spawner.add_child(enemy)
		enemy.position = pos
		enemy.enemy_type = 0
		game.spawner._active_enemies.append(enemy)
	for i in range(game.spawner.pickup_scenes.size()):
		var pickup = game.spawner.pickup_scenes[i].instantiate()
		game.spawner.add_child(pickup)
		pickup.position = Vector2(900 + i * 130, 550)
	game._current_players[0].position = Vector2(500, 540)
	game._current_players[1].position = Vector2(1420, 540)
	for p in game._current_players:
		p.freeze = true
		p.direction_arrows.show_arrow(1)
	await create_timer(2.5).timeout
	paused = true
	await capture("01_normal.png")
	await capture("03_hud.png")
	paused = false
	game._current_players[0]._on_score_powerup_ready()
	game._current_players[0].powerup_timer.stop()
	await create_timer(1.0).timeout
	paused = true
	await capture("02_star_power.png")
	quit()

func capture(filename):
	await process_frame
	RenderingServer.force_draw()
	var image = root.get_texture().get_image()
	var error = image.save_png(output.path_join(filename))
	print("CAPTURE ", filename, " ", image.get_size(), " error=", error)

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
