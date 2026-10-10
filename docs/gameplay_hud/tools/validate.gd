extends SceneTree
var game
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(condition, message):
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else: print("PASS: ", message)
func frames(count):
	for i in range(count): await process_frame
func check_layout(ui, id):
	var header = ui.get_node("PanelContainer")
	check(ui.size.y < 110, "P%d compact HUD leaves room for gameplay" % (id + 1))
	check(ui._playerButtonLabel.get_global_rect().end.x <= ui._scoreLbl.get_global_rect().position.x,
		"P%d input does not overlap score" % (id + 1))
	check(ui._statusLabel.get_global_rect().position.x >= ui.hearts[2].get_global_rect().end.x,
		"P%d status does not overlap hearts" % (id + 1))
	check(ui._bar.get_global_rect().position.y >= ui._statusLabel.get_global_rect().end.y,
		"P%d bar does not overlap status" % (id + 1))
	check(header.size.x <= ui.size.x, "P%d header fits its corner" % (id + 1))
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await frames(3)
	var configs = []
	var config_script = load("res://HUD/GameStart/player_slot_config.gd")
	for id in range(4):
		var config = config_script.new(id)
		config.mode = 2 if id >= 2 else 1
		if id < 2:
			var binding = InputEventKey.new()
			binding.keycode = KEY_SPACE if id == 0 else KEY_KP_MULTIPLY
			config.binding = binding
		configs.append(config)
	game.new_game(configs)
	game.spawner.stop()
	for p in game._current_players:
		p.freeze = true
		if p.player_data.is_cpu: p.get_node("CPUController").set_physics_process(false)
		p.ui.update_score(123456)
		p.ui.update_health(0)
		p.ui.update_health(2)
	await create_timer(0.7).timeout
	for id in range(4):
		var ui = game.hud.player_uis[id]
		check_layout(ui,id)
		check(ui._scoreLbl.text == "123456", "P%d six-digit score remains complete" % (id + 1))
		check(ui.hearts[0].modulate == game._current_players[id].player_color, "P%d latest filled heart retains color" % (id + 1))
		check(ui.hearts[2].modulate.a < 0.5, "P%d empty heart is visibly dimmed" % (id + 1))
		check(not ui._sparks[0].emitting, "P%d HUD has no persistent particle clutter" % (id + 1))
		check(ui._scoreLbl.scale == Vector2.ONE, "P%d score settles without scaling" % (id + 1))
	check(game.hud.player_uis[2]._playerButtonLabel.text == "CPU", "CPU input label retained")
	var ui = game.hud.player_uis[0]
	ui.write_resapwning()
	await frames(4)
	check_layout(ui,0)
	check(ui._statusLabel.text == "Respawning...", "respawn status remains readable")
	ui.play_powerup_mode_fx()
	await frames(4)
	check(ui._statusLabel.text == "Star Power!" and ui._statusLabel.modulate.a == 1.0,
		"activation replaces respawn pulse and restores opacity")
	ui.update_bar(3)
	ui.update_bar(0)
	ui.write_bash_mode()
	await create_timer(0.3).timeout
	check(ui._bar.value == 0 and ui._bar.modulate == Color.WHITE, "latest bar state cancels full-bar pulse")
	check(ui._statusLabel.text == "Star Power", "expiry restores normal label")
	root.size = Vector2i(1280,720)
	await frames(6)
	for id in range(4):
		ui = game.hud.player_uis[id]
		check_layout(ui,id)
		var rect = ui.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.get_visible_rect().size.x and rect.end.y <= root.get_visible_rect().size.y,
			"P%d stays within 720p window" % (id + 1))
	game.new_game([configs[0],configs[2]])
	await frames(4)
	check(game.hud.player_uis[0].visible and game.hud.player_uis[2].visible,
		"non-contiguous P1 and P3 HUDs retained")
	check(not game.hud.player_uis[1].visible and not game.hud.player_uis[3].visible,
		"inactive corner HUDs stay hidden")
	game.return_to_lobby()
	game.queue_free()
	await frames(3)
	print("RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
