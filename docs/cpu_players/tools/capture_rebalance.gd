# Opt-in visual verification; the frozen/repositioned respawn fixture is test-only.
extends SceneTree
var game
func _initialize(): call_deferred("run")
func frames(count):
	for i in range(count): await physics_frame
func capture(name):
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/cpu_players/rebalance/" + name)
func run():
	seed(250126)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.size = Vector2i(1920,1080)
	await process_frame
	var lobby = game.hud.start_seq.lobby
	var key = InputEventKey.new()
	key.keycode = KEY_SPACE
	lobby.assign_input(0,key)
	for id in [1,2,3]: lobby._use_cpu(id)
	lobby.request_start()
	await frames(480)
	await capture("01_slower_cpus.png")
	game.spawner.stop()
	for mob in get_nodes_in_group("mobs"): mob.queue_free()
	for player in game._current_players:
		if player.player_data.is_cpu: player.get_node("CPUController").set_physics_process(false)
		player.freeze = true
	await process_frame
	var human = game._current_players[0]
	human.position = Vector2(530,500)
	human.hp = 1
	human._can_take_damage = true
	human.take_damage(human.position + Vector2(20,0))
	await frames(300)
	if human.hp != 3 or absf(human.sprite.rotation - human._init_sprite_rotation) > 0.001:
		push_error("Respawn pose failed")
		quit(1)
		return
	await capture("02_upright_respawn.png")
	print("CAPTURE_COMPLETE: slower CPU gameplay and upright human respawn")
	game.return_to_lobby()
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	quit()
