extends SceneTree
var game
var Config = load("res://HUD/GameStart/player_slot_config.gd")
var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func check(ok, message):
	checks += 1
	if ok: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func frames(count):
	for i in range(count): await physics_frame
func configs(humans: Array, cpus: Array) -> Array:
	var result: Array = []
	for id in range(4):
		var config = Config.new(id)
		if id in humans:
			config.mode = 1
			config.binding = InputEventKey.new()
			config.binding.keycode = [KEY_SPACE,KEY_F,KEY_G,KEY_H][id]
		elif id in cpus: config.mode = 2
		result.append(config)
	return result
func quiet():
	game.spawner.stop()
	for mob in get_nodes_in_group("mobs"): mob.queue_free()
	await process_frame
	await process_frame
func fixture(scene_index, position):
	var list = game.spawner._active_pickups if scene_index == 0 else game.spawner._active_powerups
	var pickup = game.spawner._spawn_entity(game.spawner.pickup_scenes[scene_index], list, 4)
	pickup.monitoring = false # Planning fixture: do not collect while repositioning bodies.
	pickup.global_position = position
	return pickup
func click(control):
	await process_frame
	await process_frame
	var event = InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func run():
	seed(250125)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await process_frame
	var lobby = game.hud.start_seq.lobby
	game.hud.start_seq.show_lobby()
	check(lobby.configuration[0].mode == 1 and lobby.configuration[0].binding == null, "default human still requires binding")
	await click(lobby.slots[0].get_node("Content/Cpu"))
	check(lobby.configuration[0].mode == 2 and not lobby.start_button.disabled, "CPU button enables a playable slot without a key")
	check(lobby.slots[0].get_node("Content/Mode").text == "CPU", "CPU lobby label")
	await click(lobby.slots[0].get_node("Content/Actions/Binding"))
	check(lobby.configuration[0].mode == 1 and game.hud.start_seq.mapping_screen.capturing_slot == 0, "CPU can switch back to a capturing human")
	game.hud.start_seq.mapping_screen.finish_capture()
	var binding = InputEventMouseButton.new()
	binding.button_index = MOUSE_BUTTON_LEFT
	lobby.assign_input(0,binding)
	await click(lobby.slots[0].get_node("Content/Cpu"))
	check(lobby.configuration[0].binding == null and InputMap.action_get_events("player0").is_empty(), "switching to CPU clears human binding")
	await click(lobby.slots[2].get_node("Content/Cpu"))
	check(lobby.configuration[2].mode == 2, "OFF slot can become CPU directly")
	await click(lobby.start_button)
	check(game._current_players.size() == 2 and game._current_players[1].player_data.id == 2, "non-contiguous CPU-only lobby match starts")
	await quiet()
	for p in game._current_players:
		check(p.has_node("CPUController") and not p.is_processing_input(), "controller exists only for CPU; human input is disabled")
		check(p.ui._playerButtonLabel.text == "CPU", "CPU HUD label in original corner")
		check(p.position == game._player_data[p.player_data.id].x0 and p.player_color == game._player_data[p.player_data.id].color, "original CPU identity and spawn position")
	check(not game.hud.player_uis[1].visible and not game.hud.player_uis[3].visible, "inactive corners hidden")
	game.game_over()
	await process_frame
	var results = game.hud.final_score_box.get_children()
	check(results.size() == 2 and results[1].nameLbl.text == "Player 3" and results[1].get_node("Controller").visible, "results preserve original IDs and small CPU label")
	check(results[1].get_node("Controller").get_theme_color("font_color") == game._player_data[2].color and results[1].get_node("Controller").get_theme_constant("outline_size") == 2, "CPU result label contrasts with graph paper")
	game.return_to_lobby()
	await process_frame
	check(lobby.configuration[2].mode == 2, "return preserves editable CPU configuration")
	check(game.new_game(configs([0],[2])), "human plus non-contiguous CPU starts")
	await quiet()
	var human = game._current_players[0]
	var p = game._current_players[1]
	var cpu = p.get_node("CPUController")
	cpu.set_physics_process(false)
	cpu.hesitation_probability = 0.0
	cpu.aiming_error = 0.0
	check(not human.has_node("CPUController") and human.is_processing_input(), "human retains original input processing")
	check(human.ui._playerButtonLabel.text == "SPACE", "human HUD still displays mapped key")
	var human_start = human.position
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await frames(10)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	check(human.position.distance_to(human_start) > 5 and human._next_direction == 1, "real human key still moves and cycles in a mixed match")
	check(p.current_direction == 0 and not p.is_processing_input(), "human key does not steer the CPU")
	human.freeze = true
	check(not cpu.debug_enabled and cpu._planes.size() >= 8, "debug disabled by default and real arena boundaries read")
	var star = fixture(0,Vector2(530,500))
	for direction in range(4):
		p.global_position = Vector2(530,500)
		p.linear_velocity = Vector2.ZERO
		await frames(1)
		star.global_position = p.global_position + p.DIRECTION_VECTORS[direction] * 280
		cpu.target = null
		cpu._kick_left = 0.0
		cpu._recover_left = 0.0
		cpu._decide()
		check(cpu.chosen_direction == direction and p.current_direction == direction, "direct CPU direction %d is selected coherently" % direction)
		await frames(2)
		check(p.linear_velocity.dot(p.DIRECTION_VECTORS[direction]) > 0 and p.linear_velocity.length() <= p._speed + 0.01, "direct kick %d uses capped real physics" % direction)
	# Current momentum already passes through the star; an unnecessary kick loses.
	p.global_position = Vector2(530,500)
	p.linear_velocity = Vector2.RIGHT * p._speed
	star.global_position = Vector2(800,500)
	cpu._kick_left = 0.0
	cpu.target = null
	cpu._decide()
	check(cpu.chosen_direction == -1, "coast wins when momentum already reaches the pickup")
	cpu._kick_left = 0.3
	star.global_position = Vector2(530,200)
	cpu._decide()
	check(cpu.chosen_direction == -1, "kick cooldown forbids an immediate direction change")
	check(cpu._path_distance(PackedVector2Array([Vector2.ZERO,Vector2(500,0)]),Vector2(250,0),Vector2.ZERO) == 0.0, "trajectory detects pickup passage between samples")
	p.global_position = Vector2(530,960)
	p.linear_velocity = Vector2.ZERO
	var prediction = cpu._predict(1)
	check(prediction.walls > 0 and prediction.points[-1].y < 960, "trajectory reflects from actual south boundary")
	for point in prediction.points:
		check(point.y <= 1000, "predicted sample stays within south boundary")
	p.global_position = Vector2(530,900)
	p.cpu_kick(1)
	await frames(30)
	check(p.linear_velocity.y < 0 and p.position.y < 981, "real CPU player bounces off wall")
	await quiet()
	p.global_position = Vector2(530,500)
	p.linear_velocity = Vector2.ZERO
	star = fixture(0,Vector2(760,500))
	var heart = fixture(1,Vector2(680,500))
	cpu.target = null
	p.hp = 3
	cpu._choose_goal([star,heart],[],[p,human],[])
	check(cpu.goal == 0 and cpu.target == star, "full-health CPU seeks stars and ignores hearts")
	p.hp = 1
	cpu.target = null
	cpu._choose_goal([star,heart],[],[p,human],[])
	check(cpu.goal == 1 and cpu.target == heart, "one HP makes nearby heart strongly valuable")
	p.hp = 2
	heart.global_position = Vector2(1300,500)
	star.global_position = Vector2(630,500)
	cpu.target = null
	cpu._choose_goal([star,heart],[],[p,human],[])
	check(cpu.goal == 0 and cpu.target == star, "minor injury does not abandon nearby scoring for a distant heart")
	var second = fixture(0,Vector2(620,500))
	cpu._commit_left = 0.8
	cpu._choose_goal([star,second],[],[p,human],[])
	check(cpu.target == star, "brief commitment resists marginally closer target")
	star.is_collected = true
	cpu._choose_goal([second],[],[p,human],[])
	check(cpu.target == second, "collected target is promptly discarded")
	check(not game.get_cpu_pickups().has(star), "world observations omit fading collected pickups")
	var enemy = game.spawner._spawn_entity(game.spawner.enemy_scenes[0],game.spawner._active_enemies,5)
	enemy.global_position = Vector2(620,500)
	await frames(135)
	enemy.freeze()
	enemy.global_position = p.global_position + Vector2(90,0)
	p.hp = 1
	p._can_take_damage = true
	cpu._choose_goal([], [enemy], [p,human], [enemy])
	check(cpu.goal == 2 and cpu._goal_point.x < p.global_position.x, "imminent skull danger causes evasion away from threat")
	cpu._kick_left = 0.0
	cpu._decide()
	check(cpu.chosen_direction != 0, "escape planning avoids kicking into nearby skull")
	enemy.global_position = Vector2(780,500)
	p._on_score_powerup_ready()
	await frames(2)
	cpu.target = null
	cpu._choose_goal([], [enemy], [p,human], [])
	check(cpu.goal == 3 and cpu.target != null, "Star Power selects an enemy or vulnerable opponent to hunt")
	check(cpu._dangerous([enemy],[p,human]).is_empty(), "powered CPU is not scared of harmless targets")
	check(p._speed == 1000 and p._kick_force == 6000, "existing powered force and speed preserved")
	human._on_score_powerup_ready()
	p._on_powerup_timer_timeout()
	await frames(2)
	check(game._powered_players.size() == 1 and game.background.is_powerup_mode and game.spawner.pickup_timer.paused, "CPU ending does not clear overlapping human power")
	check(human._speed == 1000 and p._speed == 250, "overlap retains powered and slowed speeds")
	human.global_position = p.global_position + Vector2(90,0)
	p._can_take_damage = true
	cpu._choose_goal([],[],[p,human],cpu._dangerous([], [p,human]))
	check(cpu.goal == 2, "powered opponent is a normal-mode danger")
	human._on_powerup_timer_timeout()
	await frames(2)
	check(not game.background.is_powerup_mode and p._speed == 500, "last expiry restores shared environment")
	await quiet()
	cpu.target = null
	cpu.goal = 2
	cpu._choose_goal([],[],[p],[])
	check(cpu.goal == 4 and game.get_cpu_roam_bounds().has_point(cpu._goal_point), "empty arena produces an interior roaming waypoint")
	cpu._anchor = p.global_position
	cpu._stuck_left = 0.0
	cpu._decide()
	check(cpu.diagnostics.unsticks > 0 and cpu._recover_left > 0, "stationary anti-stuck chooses a fresh waypoint without teleporting")
	p.hp = 1
	p._can_take_damage = true
	p.take_damage(p.position + Vector2(20,0))
	cpu.set_physics_process(true)
	var kicks = cpu.diagnostics.kicks
	await frames(60)
	check(p.hp <= 0 and cpu.diagnostics.kicks == kicks and cpu.target == null, "dead CPU stops deciding and clears target")
	await frames(330)
	check(p.hp == 3 and p.visible and not p.is_processing_input() and cpu.diagnostics.kicks > kicks, "existing respawn restores CPU decisions without human input")
	var old_kicks = cpu.diagnostics.kicks
	await frames(60)
	check(cpu.diagnostics.kicks - old_kicks <= 3, "kick frequency remains limited over one second")
	for scenario in [[[0],[1]],[[0],[1,2,3]],[[],[0,1,2,3]]]:
		game.return_to_lobby()
		await process_frame
		check(game.new_game(configs(scenario[0],scenario[1])), "mixed or CPU-only configuration starts after restart: %s" % str(scenario))
		await quiet()
		check(game._current_players.size() == scenario[0].size()+scenario[1].size(), "correct active player count")
	game.return_to_lobby()
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	print("RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
