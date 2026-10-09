extends SceneTree
var game
var summaries: Array = []
var failed = false
var visual = "--screenshots" in OS.get_cmdline_user_args()
func _initialize(): call_deferred("run")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	if visual: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/cpu_players/match_frames"))
	await process_frame
	game.hud.start_seq.show_lobby()
	var Config = load("res://HUD/GameStart/player_slot_config.gd")
	for scenario in [{"seed": 250125, "humans": [0], "cpus": [1]}, {"seed": 250126, "humans": [0], "cpus": [1,2,3]}, {"seed": 250127, "humans": [], "cpus": [0,1,2,3]}]:
		seed(scenario.seed)
		var configs: Array = []
		for id in range(4):
			var config = Config.new(id)
			if id in scenario.cpus: config.mode = Config.PlayerMode.CPU
			elif id in scenario.humans:
				config.mode = Config.PlayerMode.HUMAN
				config.binding = InputEventKey.new()
				config.binding.keycode = KEY_SPACE
			configs.append(config)
		game.hud.start_seq.lobby.configuration = configs
		game.hud.start_seq.lobby.refresh()
		game.hud.start_seq.lobby.request_start()
		var players = game._current_players.duplicate()
		var records: Array = []
		for p in players:
			var record = {"id": p.player_data.id, "cpu": p.player_data.is_cpu, "score": 0}
			if p.player_data.is_cpu:
				var controller = p.get_node("CPUController")
				record["metrics"] = controller.diagnostics
			p.tree_exiting.connect(func(): record.score = p.score_manager._score)
			records.append(record)
		var power_overlap = 0
		for frame in range(7300):
			await physics_frame
			if game._powered_players.size() > 1: power_overlap += 1
			if visual and frame in [1800,3600,5400]:
				RenderingServer.force_draw()
				root.get_texture().get_image().save_png("res://docs/cpu_players/match_frames/%d_%03d.png" % [scenario.seed,frame / 60])
			if not game._game_playing: break
		var summary = {"seed": scenario.seed, "seconds": 120, "humans_stationary": scenario.humans, "players": records, "overlap_seconds": power_overlap / 60.0}
		await process_frame
		if visual:
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://docs/cpu_players/match_frames/%d_results.png" % scenario.seed)
		print("MATCH_RESULT ", JSON.stringify(summary))
		summaries.append(summary)
		for record in records:
			if record.cpu:
				if record.metrics.stars < 1 or record.metrics.kicks < 10 or record.metrics.directions.has(0):
					failed = true
		game.return_to_lobby()
		await process_frame
		await process_frame
	FileAccess.open("res://docs/cpu_players/matches.json", FileAccess.WRITE).store_string(JSON.stringify(summaries, "\t"))
	print("MATCHES_COMPLETE useful_planning=", not failed)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)
