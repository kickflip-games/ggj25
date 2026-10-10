extends SceneTree
var game
var phase: String = "after"
func _initialize(): call_deferred("run")
func frames(count):
	for i in range(count): await physics_frame
func capture(filename):
	var path = "res://docs/gameplay_hud/%s/%s" % [phase,filename]
	if phase == "before" and FileAccess.file_exists(path):
		push_error("Baseline already exists; refusing to overwrite: " + path)
		quit(1)
		return
	paused = true
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(path)
	paused = false
	print("CAPTURE ",phase,"/",filename)
func run():
	if "--before" in OS.get_cmdline_user_args(): phase = "before"
	seed(250125)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await process_frame
	var lobby = game.hud.start_seq.lobby
	var key = InputEventKey.new()
	key.keycode = KEY_SPACE
	lobby.assign_input(0,key)
	lobby.configuration[1].mode = 1
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	lobby.assign_input(1,mouse)
	for id in [2,3]: lobby._use_cpu(id)
	lobby.request_start()
	for p in game._current_players:
		p.freeze = true
		if p.player_data.is_cpu: p.get_node("CPUController").set_physics_process(false)
	game.spawner.stop()
	await frames(150)
	for enemy in game.spawner._active_enemies: enemy.freeze()
	for p in game._current_players:
		p.score_manager._score = [187,12340,60,920][p.player_data.id]
		p.ui.update_score(p.score_manager._score)
		p.hp = [2,1,3,2][p.player_data.id]
		p.ui.update_health(p.hp)
		p.ui.update_bar([2,1,0,2][p.player_data.id])
	await frames(60)
	await capture("01_normal.png")
	var p = game._current_players[0]
	p._on_score_powerup_ready()
	await frames(45)
	await capture("02_star_power.png")
	p._on_powerup_timer_timeout()
	await frames(60)
	p.ui.write_resapwning()
	await frames(10)
	await capture("03_hud.png")
	game.return_to_lobby()
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	quit()
