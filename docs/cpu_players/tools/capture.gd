extends SceneTree
var game
var Config = load("res://HUD/GameStart/player_slot_config.gd")
var manifest: Array = []
func _initialize(): call_deferred("run")
func frames(count):
	for i in range(count): await physics_frame
func save(filename: String, description: String):
	await process_frame
	RenderingServer.force_draw()
	var path = "res://docs/cpu_players/after/" + filename
	var output = root.get_texture().get_image()
	output.save_png(path)
	manifest.append({"file": filename, "description": description, "size": [output.get_width(),output.get_height()], "seconds_remaining": game.game_timer.time_left})
	print("CAPTURE ", filename)
func start(humans: Array, cpus: Array, debug: bool = false):
	game.return_to_lobby()
	await process_frame
	await process_frame
	seed(250125)
	var lobby = game.hud.start_seq.lobby
	for id in range(4):
		lobby._disable(id)
		if id in cpus: lobby._use_cpu(id)
		elif id in humans:
			lobby.configuration[id].mode = 1
			var binding = InputEventKey.new()
			binding.keycode = KEY_SPACE
			lobby.assign_input(id,binding)
	game.cpu_debug_enabled = debug
	lobby.request_start()
	await frames(2)
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await process_frame
	game.hud.start_seq.show_lobby()
	await process_frame
	await save("00_lobby_default.png", "Default lobby: same configuration as baseline, CPU now selectable.")
	var lobby = game.hud.start_seq.lobby
	var binding = InputEventKey.new()
	binding.keycode = KEY_SPACE
	lobby.assign_input(0,binding)
	for id in [1,2,3]: lobby._use_cpu(id)
	await process_frame
	await save("00_lobby_mixed.png", "P1 SPACE, P2–P4 CPU, Start enabled.")
	await start([0],[1])
	await frames(240)
	await save("01_human_cpu.png", "One stationary human and one CPU; unstaged gameplay after four seconds.")
	await start([0],[1,2,3])
	await frames(480)
	await save("02_human_three_cpus.png", "One stationary human and three CPUs; unstaged gameplay after eight seconds.")
	var powered = false
	for frame in range(7200):
		await physics_frame
		for p in game._current_players:
			if p.player_data.is_cpu and p._in_power_up_mode and p.powerup_timer.time_left < 4.4:
				powered = true
		if powered: break
	if powered: await save("03_cpu_star_power.png", "Naturally earned CPU Star Power, not manually triggered.")
	else: push_error("No natural CPU power-up before game over.")
	await start([], [0,1,2,3], true)
	await frames(300)
	await save("04_cpu_debug.png", "Four CPUs with developer-only goals, targets and predicted paths enabled.")
	await start([], [0,1,2,3])
	await frames(360)
	await save("05_four_cpus.png", "Four CPU players, debug disabled; unstaged gameplay after six seconds.")
	await frames(300)
	# 25 seconds of native viewport frames, 20 fps. No changed motion or staged pickups.
	DirAccess.make_dir_recursive_absolute("/tmp/wishbones_cpu_frames")
	for i in range(500):
		await frames(3)
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/tmp/wishbones_cpu_frames/%05d.png" % i)
		if i % 100 == 0: print("VIDEO_FRAME ",i)
	FileAccess.open("res://docs/cpu_players/captures.json", FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	game.return_to_lobby()
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if powered else 1)
