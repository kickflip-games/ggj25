# MAIN.gd

extends Node2D

const CPUController = preload("res://Entities/Player/cpu_controller.gd")
@export var cpu_debug_enabled: bool = false

const SlotConfig = preload("res://HUD/GameStart/player_slot_config.gd")

@export var player_scene:PackedScene

@onready var spawner:=$Spawner
@onready var hud:=$Hud
@onready var game_timer:=$GameTimer
@onready var background:=$Background
@export var game_time:float = 2 * 60

var _game_playing:bool= false
var _player_data:Array[PlayerData]
var _current_players:Array[Player]
var _powered_players:Array[Player] = []







func _ready():
	_init_player_data()
	Globals.MainCam = $Camera2D
	
	
func _init_player_data():
	_player_data = [
		PlayerData.new(0, $StartPositions/P1.global_position, hud.player_uis[0]),
		PlayerData.new(1, $StartPositions/P2.global_position, hud.player_uis[1]),
		PlayerData.new(2, $StartPositions/P3.global_position, hud.player_uis[2]),
		PlayerData.new(3, $StartPositions/P4.global_position, hud.player_uis[3]),
	]


func game_over():
	_clear_shared_powerup()
	
	var player_scores = []
	spawner.stop()
	_game_playing = false
	for _p in _current_players:
		player_scores.append({"id": _p.player_data.id, "score": _p.score_manager._score, "cpu": _p.player_data.is_cpu})
		_p._toggle_physics(false)
		_p.queue_free()
	
	hud.show_game_over(player_scores)
	
	_current_players.clear()

func _instantiate_player(player_data:PlayerData):
	var player:Player = player_scene.instantiate()
	add_child(player)
	player.name = player_data.name
	player.start(player_data)
	player.powerup_activated.connect(_on_powerup_activated)
	player.powerup_deactivated.connect(_on_powerup_deactivated)
	_current_players.append(player)
	if player_data.is_cpu:
		var controller = CPUController.new()
		controller.name = "CPUController"
		controller.debug_enabled = cpu_debug_enabled
		player.add_child(controller)
		controller.setup(player, self)
	

func _on_powerup_activated(p:Player):
	if p in _powered_players:
		return
	_powered_players.append(p)
	p.ui.play_powerup_mode_fx()
	$Shockwave.create_shock()
	Globals.MainCam.SHAKE() 
	MusicManager.enter_powerup_mode()
		
	background.set_color(p.player_color)
	spawner.freeze()
	
	for _p in _current_players:
		if _p not in _powered_players:
			_p._speed = Player.BASE_SPEED / 2.0
			
	background.start_powerup()
	
func _on_powerup_deactivated(p:Player):
	_powered_players.erase(p)
	if not _powered_players.is_empty():
		# The ending player rejoins the slowed players; powered players keep their speed.
		p._speed = Player.BASE_SPEED / 2.0
		background.set_color(_powered_players.back().player_color)
		return
	_clear_shared_powerup()

func _clear_shared_powerup():
	_powered_players.clear()
	MusicManager.exit_powerup_mode()
	spawner.resume()
	background.end_powerup()
	for p in _current_players:
		p._speed = Player.BASE_SPEED

func new_game(configuration: Array) -> bool:
	if not SlotConfig.validation_message(configuration).is_empty():
		return false
	_clear_shared_powerup()
	TimeManager.reset()
	# clear any already present mobs / pickups 
	get_tree().call_group("mobs", "queue_free")
	
	if len(_current_players)>0:
		for _p in _current_players:
			_p.queue_free()
		_current_players.clear()
	
	
	for ui in hud.player_uis:
		ui.hide()
	for config in configuration:
		InputMap.action_erase_events("player%d" % config.id)
		if config.mode != SlotConfig.PlayerMode.OFF:
			_player_data[config.id].is_cpu = config.mode == SlotConfig.PlayerMode.CPU
			if config.mode == SlotConfig.PlayerMode.HUMAN:
				InputMap.action_add_event("player%d" % config.id, config.binding)
			_instantiate_player(_player_data[config.id])
	
	 # not the best place... but whatever.. maybe (call_groups(player) for each player connect )...
	spawner.start()
	game_timer.start(game_time)
	_game_playing = true
	return true

	

func _on_hud_start_game(configuration: Array):
	new_game(configuration)
	hud.update_timer(game_time)


func _process(_delta):
	if _game_playing:
		hud.update_timer(game_timer.time_left)

func _on_game_timer_timeout():
	game_over()

func return_to_lobby():
	_clear_shared_powerup()
	spawner.stop()
	game_timer.stop()
	_game_playing = false
	get_tree().call_group("mobs", "queue_free")
	for player in _current_players:
		player._toggle_physics(false)
		player.queue_free()
	_current_players.clear()
	TimeManager.reset()
	hud.show_lobby()

func get_cpu_pickups() -> Array:
	return spawner.get_cpu_pickups()

func get_cpu_enemies() -> Array:
	return spawner.get_cpu_enemies()

func get_cpu_players() -> Array:
	return _current_players.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion() and p.hp > 0 and p.visible)

func get_cpu_roam_bounds() -> Rect2:
	var shape = spawner.collider.shape as RectangleShape2D
	return Rect2(spawner.collider.global_position - shape.size / 2.0, shape.size)

func get_cpu_arena_planes() -> Array:
	# Read the actual static collision geometry once per controller, not every frame.
	# Each plane's normal points into this convex arena. No hard-coded arena size.
	var planes: Array = []
	var center = spawner.collider.global_position
	for wall in get_tree().get_nodes_in_group("WALLS"):
		for child in wall.get_children():
			if child is CollisionShape2D and child.shape is WorldBoundaryShape2D:
				var normal = child.global_transform.basis_xform(child.shape.normal).normalized()
				var point = child.to_global(child.shape.normal * child.shape.distance)
				if (center - point).dot(normal) < 0.0: normal = -normal
				planes.append({"normal": normal, "distance": normal.dot(point)})
			elif child is CollisionPolygon2D:
				for i in range(child.polygon.size()):
					var a = child.to_global(child.polygon[i])
					var b = child.to_global(child.polygon[(i + 1) % child.polygon.size()])
					var normal = (b - a).orthogonal().normalized()
					if (center - a).dot(normal) < 0.0: normal = -normal
					planes.append({"normal": normal, "distance": normal.dot(a)})
	return planes
