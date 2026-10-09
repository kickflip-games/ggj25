extends SceneTree
var game
var failures = 0
var checks = 0

func _initialize():
	call_deferred("run")

func check(condition, message):
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: ", message)

func wait(seconds):
	await create_timer(seconds).timeout

func quiet_arena():
	game.spawner.stop()
	for node in get_nodes_in_group("mobs"):
		node.queue_free()
	await process_frame

func press(action):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame

func run():
	seed(250125)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.hud.get_node("StartSequence").hide()
	game.hud.get_node("StartMarginContainer").hide()
	check(game.player_scene != null, "main scene starts with player assets")
	game.new_game(selected([0]))
	await quiet_arena()
	check(game._current_players.size() == 1, "one-player game starts")
	var p = game._current_players[0]
	var old_position = p.position
	await press("player0")
	await wait(0.1)
	check(p.position.distance_to(old_position) > 1, "one-button input moves player through real physics")
	check(p._next_direction == 1, "direction advances once per press")
	game.new_game(selected([0,1,2,3]))
	await quiet_arena()
	check(game._current_players.size() == 4, "four-player game starts")
	for i in range(4):
		p = game._current_players[i]
		await press("player" + str(i))
		check(p._next_direction == 1, "player %d independent control" % (i + 1))
		check(p.ui.visible, "player %d HUD visible" % (i + 1))
		p._can_take_damage = true
		p.take_damage(p.position - Vector2(20, 0))
		check(p.hp == 2, "player %d health decreases" % (i + 1))
		p.increment_health()
		check(p.hp == 3, "player %d health increases" % (i + 1))
		p.freeze = true
	var enemy = game.spawner.enemy_scenes[0].instantiate()
	game.spawner.add_child(enemy)
	enemy.position = Vector2(800, 500)
	enemy.enemy_type = 0
	game.spawner._active_enemies.append(enemy)
	await wait(2.2)
	check(enemy.hurt_area.enabled and not enemy.is_frozen, "enemy spawns with original hurt detection")
	p = game._current_players[0]
	var earned = p.score_manager.increment(false)
	check(earned == 10 and p.score_manager._score == 10, "ordinary scoring remains 10")
	p.score_manager.increment(false)
	p.score_manager.increment(false)
	check(p._in_power_up_mode, "three pickups activate Star Power")
	check(p._speed == 1000 and p._kick_force == 6000, "existing powered movement values preserved")
	await wait(1.0)
	var second = game._current_players[1]
	second._on_score_powerup_ready()
	check(game._powered_players.size() == 2, "two simultaneous activations tracked")
	check(p._speed == 1000 and second._speed == 1000, "powered players do not slow one another")
	await wait(4.1)
	check(not p._in_power_up_mode and second._in_power_up_mode, "first timer ends while second remains powered")
	check(game._powered_players.size() == 1 and game.background.is_powerup_mode, "shared background remains active")
	check(game.spawner.pickup_timer.paused and game.spawner.powerup_timer.paused, "spawner remains frozen during overlap")
	check(enemy.is_frozen and enemy.timeout_timer.paused, "enemy stays frozen until last power expires")
	check(root.get_node("MusicManager").current_mode == 1, "power music remains active during overlap")
	check(p._speed == 250 and second._speed == 1000, "ended player slows while powered player keeps boosted speed")
	await wait(1.0)
	check(not second._in_power_up_mode and game._powered_players.is_empty(), "last timer clears power state")
	check(not game.background.is_powerup_mode and not game.spawner.pickup_timer.paused, "last timer restores background and spawner")
	check(root.get_node("MusicManager").current_mode == 0, "last timer restores normal music")
	check(not enemy.is_frozen and not enemy.timeout_timer.paused, "last expiry resumes enemy")
	for player in game._current_players:
		check(player._speed == 500, "base movement restored")
	await wait(0.7)
	check(is_zero_approx(game.background.shader_mat.get_shader_parameter("alpha")), "overlay fades out fully")
	check(p.ui._scoreLbl.text == "0040", "score count settles correctly after rapid updates")
	check(p.ui._bar.value == 0 and not p.ui._bar.show_percentage, "bar resets without percentage clutter")
	p.ui.update_health(0)
	p.ui.update_health(3)
	await wait(0.6)
	check(p.ui.hearts[0].modulate == p.player_color, "rapid health UI updates settle to latest state")
	var popup = root.get_node("PopupFx")
	popup.display_popup("+10", Vector2(600, 500))
	await process_frame
	await process_frame
	var label = popup.get_child(popup.get_child_count() - 1)
	check(label.label_settings.font == load("res://HUD/Sniglet.ttf"), "ordinary popup preserves intended font")
	check(label.label_settings.font_size == 24, "ordinary popup is smaller")
	await wait(0.8)
	check(not is_instance_valid(label), "ordinary popup clears within 0.8 seconds")
	for i in range(4):
		game.hud.player_uis[i].update_score(100 + i)
		game.hud.player_uis[i].update_health(i % 3 + 1)
	await wait(0.6)
	for i in range(4):
		check(int(game.hud.player_uis[i]._scoreLbl.text) == 100 + i, "HUD %d independently updates score" % (i + 1))
		check(game.hud.player_uis[i].hearts[0].modulate == game._current_players[i].player_color, "HUD %d preserves heart color" % (i + 1))
	p._on_score_powerup_ready()
	await wait(0.2)
	game.new_game(selected([0,1]))
	await quiet_arena()
	await wait(0.6)
	check(game._powered_players.is_empty() and not game.background.is_powerup_mode, "new round clears shared effects")
	game.game_over()
	await wait(0.2)
	check(not game._game_playing, "game over completes")
	# Remove the intentionally paused, empty player tweens before orderly exit.
	game.queue_free()
	await process_frame
	await process_frame
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
