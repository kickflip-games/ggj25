extends SceneTree
var game
var lobby
var mapping
var checks = 0
var failures = 0
var Config = load("res://HUD/GameStart/player_slot_config.gd")
func _initialize():
	call_deferred("run")
func check(ok, message):
	checks += 1
	if ok: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func key(code):
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func mouse(pos, button = MOUSE_BUTTON_LEFT):
	var move = InputEventMouseMotion.new()
	move.position = pos
	Input.parse_input_event(move)
	var event = InputEventMouseButton.new()
	event.position = pos
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventMouseButton.new()
	event.position = pos
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func click(control):
	# Containers sort after visibility changes; query the final on-screen button rect.
	await process_frame
	await process_frame
	await mouse(control.get_global_rect().get_center())
func quiet():
	game.spawner.stop()
	for mob in get_nodes_in_group("mobs"):
		mob.queue_free()
	await process_frame
func return_lobby():
	game.return_to_lobby()
	await process_frame
	await process_frame
func ids():
	var values = []
	for p in game._current_players: values.append(p.player_data.id)
	return values
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await process_frame
	await process_frame
	check(game.hud.start_seq.title_screen.visible and not game.hud.start_seq.lobby.visible, "launch shows title before selection")
	await click(game.hud.start_seq.title_screen.get_node("Play"))
	check(not game.hud.start_seq.title_screen.visible and game.hud.start_seq.lobby.visible, "Play opens selection screen")
	lobby = game.hud.start_seq.lobby
	mapping = game.hud.start_seq.mapping_screen
	check(lobby.configuration[0].mode == 1 and lobby.configuration[0].binding == null, "P1 starts human without a binding")
	for i in [1,2,3]:
		check(lobby.configuration[i].mode == 0 and InputMap.action_get_events("player%d" % i).is_empty(), "P%d starts off without old bindings" % (i+1))
	check(lobby.start_button.disabled, "Start disabled until all active humans have bindings")
	lobby.request_start()
	check(not game._game_playing and not lobby.status.text.is_empty(), "invalid Start explains missing input")
	await click(lobby.slots[0].get_node("Content/Actions/Binding"))
	check(mapping.capturing_slot == 0 and lobby.configuration[0].binding == null, "binding button opens P1 capture without binding its opening click")
	await key(KEY_TAB)
	check(mapping.capturing_slot == 0 and mapping.warning.text.contains("reserved"), "Tab remains reserved")
	await key(KEY_SPACE)
	check(mapping.capturing_slot == -1 and Config.input_text(lobby.configuration[0].binding) == "SPACE", "keyboard assignment through actual input events")
	check(InputMap.action_get_events("player0").size() == 1 and not lobby.start_button.disabled, "one valid human can start")
	await click(lobby.start_button)
	check(ids() == [0] and game._game_playing, "one-player match starts through lobby button")
	await quiet()
	await return_lobby()
	check(lobby.configuration[0].binding.keycode == KEY_SPACE and game.hud.start_seq.visible, "return retains configuration")
	await click(lobby.slots[2].get_node("Content/Enable"))
	check(lobby.configuration[2].mode == 1 and mapping.capturing_slot == 2, "P3 independently enables and captures")
	check(lobby.configuration[2].binding == null and lobby.start_button.disabled, "Enable click is not assigned as a mouse input")
	await key(KEY_SPACE)
	check(mapping.capturing_slot == 2 and lobby.configuration[2].binding == null and mapping.warning.text.contains("P1"), "duplicate key warns and preserves capture")
	await click(lobby.slots[0].get_node("Content/Actions/Binding"))
	check(mapping.capturing_slot == 2 and lobby.configuration[2].binding == null, "clicking underlying UI cannot bind or switch capture")
	await mouse(Vector2(70,70))
	check(Config.input_text(lobby.configuration[2].binding) == "LEFT CLICK" and mapping.capturing_slot == -1, "mouse assignment from empty paper")
	await click(lobby.slots[2].get_node("Content/Actions/Binding"))
	await key(KEY_ESCAPE)
	check(Config.input_text(lobby.configuration[2].binding) == "LEFT CLICK" and mapping.capturing_slot == -1, "Escape cancels remap and preserves previous input")
	await click(lobby.slots[2].get_node("Content/Actions/Binding"))
	await click(mapping.cancel_button)
	check(mapping.capturing_slot == -1 and Config.input_text(lobby.configuration[2].binding) == "LEFT CLICK", "Cancel button never becomes a mouse binding")
	await click(lobby.slots[0].get_node("Content/Actions/Binding"))
	await key(KEY_F)
	check(lobby.configuration[0].binding.keycode == KEY_F and InputMap.action_get_events("player0").size() == 1, "successful remap replaces old action event")
	await click(lobby.slots[0].get_node("Content/Actions/Binding"))
	await key(KEY_SPACE)
	await click(lobby.start_button)
	check(ids() == [0,2], "P1 plus P3 spawn without P2 or P4")
	await quiet()
	for i in range(4): check(game.hud.player_uis[i].visible == (i in [0,2]), "HUD visibility matches slot %d" % i)
	for p in game._current_players:
		check(p._start_pos.is_equal_approx(game._player_data[p.player_data.id].x0), "original spawn position preserved")
		check(p.player_color == root.get_node("Globals").PLAYER_COLORS[p.player_data.id], "original slot color preserved")
	check(game.hud.player_uis[0]._playerButtonLabel.text == "SPACE" and game.hud.player_uis[2]._playerButtonLabel.text == "LEFT CLICK", "HUD input labels match assigned controls")
	var p1 = game._current_players[0]
	var p3 = game._current_players[1]
	await key(KEY_SPACE)
	await mouse(Vector2(900,500))
	await create_timer(0.1).timeout
	check(p1._next_direction == 1 and p3._next_direction == 1, "both non-contiguous players move using selected inputs")
	p1.increment_score()
	p3.increment_score()
	p3._can_take_damage = true
	p3.take_damage(p3.position - Vector2(20,0))
	check(p1.score_manager._score == 10 and p3.score_manager._score == 10 and p3.hp == 2, "scores and health work for original IDs")
	p3._on_score_powerup_ready()
	await create_timer(0.2).timeout
	check(p3._in_power_up_mode and game.background.is_powerup_mode, "P3 Star Power still activates")
	game.game_over()
	await process_frame
	var results = game.hud.final_score_box.get_children()
	check(results.size() == 2 and results[0].nameLbl.text == "Player 1" and results[1].nameLbl.text == "Player 3", "results retain original non-contiguous player IDs")
	check(results[0].scoreLbl.text == "0010" and results[1].scoreLbl.text == "0010", "results retain scores")
	await click(game.hud.start_button)
	await process_frame
	await process_frame
	check(game.hud.start_seq.visible and not game.hud.get_node("StartMarginContainer").visible, "results return to editable lobby")
	await click(lobby.slots[1].get_node("Content/Enable"))
	await mouse(Vector2(70,70))
	check(mapping.capturing_slot == 1 and mapping.warning.text.contains("P3"), "duplicate mouse binding is rejected")
	await key(KEY_ESCAPE)
	await click(lobby.slots[1].get_node("Content/Actions/Off"))
	await click(lobby.slots[2].get_node("Content/Actions/Off"))
	check(lobby.configuration[2].mode == 0 and lobby.configuration[2].binding == null and InputMap.action_get_events("player2").is_empty(), "Off clears slot and its old action binding")
	await click(lobby.slots[0].get_node("Content/Actions/Off"))
	check(lobby.start_button.disabled and lobby.status.text.contains("at least"), "all-off configuration cannot start")
	for i in range(4):
		await click(lobby.slots[i].get_node("Content/Enable"))
		check(mapping.capturing_slot == i, "only chosen slot %d captures" % i)
		await key([KEY_SPACE,KEY_F,KEY_G,KEY_H][i])
		check(not lobby.slots[i].get_node("Content/Cpu").disabled, "CPU option %d is now enabled" % i)
	check(not lobby.start_button.disabled, "four humans with distinct inputs can start")
	await click(lobby.start_button)
	check(ids() == [0,1,2,3], "four-player match starts")
	await quiet()
	await key(KEY_ESCAPE)
	check(paused, "Escape pause integration remains functional")
	game.hud.get_node("PauseMenu/Center/Options/BackButton").pressed.emit()
	await process_frame
	await process_frame
	check(not paused and game.hud.start_seq.visible and not game._game_playing, "pause Back returns to same editable lobby")
	var invalid = lobby.configuration[0].copy()
	invalid.mode = 2
	check(game.new_game([invalid]), "CPU configuration can start without a binding")
	game.return_to_lobby()
	await process_frame
	invalid.mode = 1
	invalid.binding = InputEventKey.new()
	check(not game.new_game([invalid]), "empty key cannot bypass validation")
	lobby.request_start()
	check(ids() == [0,1,2,3], "another match starts after pause return")
	print("RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
