# Plan short trajectories, but execute only coast or the human cycle's next kick.
extends Node2D

enum Goal { COLLECT, HEAL, EVADE, HUNT, ROAM }
const COAST = -1
const SAMPLE_COUNT = 8

@export var decision_interval: float = 0.55
@export var min_kick_interval: float = 0.85
@export var prediction_horizon: float = 1.0
@export var target_commitment_time: float = 0.8
@export var aiming_error: float = 20.0
@export_range(0.0, 1.0) var hesitation_probability: float = 0.10
@export var danger_weight: float = 260.0
@export var kick_penalty: float = 24.0
@export var anti_stuck_time: float = 1.8
@export var observation_limit: int = 12
@export var debug_enabled: bool = false:
	set(value):
		debug_enabled = value
		queue_redraw()

var player: Player
var world: Node2D
var goal: Goal = Goal.ROAM
var target: Node2D
var chosen_direction: int = COAST
# Read-only diagnostics; no changes to scoring or pickup behavior.
var diagnostics = {"decisions": 0, "kicks": 0, "stars": 0, "hearts": 0,
	"deaths": 0, "attacks": 0, "powerups": 0, "unsticks": 0, "stuck_seconds": 0.0,
	"goals": [0, 0, 0, 0, 0], "directions": [0, 0, 0, 0], "max_speed": 0.0}
var _rng = RandomNumberGenerator.new()
var _planes: Array = []
var _roam_bounds: Rect2
var _goal_point: Vector2
var _path = PackedVector2Array()
var _decision_left: float = 0.0
var _kick_left: float = 0.0
var _commit_left: float = 0.0
var _roam_left: float = 0.0
var _stuck_left: float = 0.0
var _anchor: Vector2
var _best_distance: float = INF
var _unproductive_time: float = 0.0
var _recover_left: float = 0.0
var _was_alive: bool = false

func setup(controlled_player: Player, observed_world: Node2D):
	player = controlled_player
	world = observed_world
	_rng.seed = randi() # Independent stream: decisions do not consume the spawner's RNG.
	_planes = world.get_cpu_arena_planes()
	_roam_bounds = world.get_cpu_roam_bounds()
	_anchor = player.global_position
	player.score_earned.connect(func(_amount, factor):
		if factor == 1: diagnostics.stars += 1
		else: diagnostics.attacks += 1)
	player.health_collected.connect(func(): diagnostics.hearts += 1)
	player.player_died.connect(func(): diagnostics.deaths += 1)
	player.powerup_activated.connect(func(_p): diagnostics.powerups += 1)
	_decision_left = decision_interval * _rng.randf_range(0.85, 1.15)

func _physics_process(delta: float):
	if not is_instance_valid(player):
		return
	var alive = player.hp > 0 and player.visible and player.is_physics_processing()
	if not alive:
		target = null
		_was_alive = false
		_path.clear()
		if debug_enabled: queue_redraw()
		return
	if not _was_alive:
		_anchor = player.global_position
		_stuck_left = anti_stuck_time
		_unproductive_time = 0.0
		_best_distance = INF
		_commit_left = 0.0
		_decision_left = decision_interval * _rng.randf_range(0.85, 1.15)
		_was_alive = true
	_kick_left = maxf(0.0, _kick_left - delta)
	_commit_left -= delta
	_roam_left -= delta
	_recover_left -= delta
	_stuck_left -= delta
	_decision_left -= delta
	diagnostics.max_speed = maxf(diagnostics.max_speed, player.linear_velocity.length())
	if _decision_left > 0.0:
		return
	_decision_left = maxf(0.05, decision_interval * _rng.randf_range(0.85, 1.15))
	_decide()

func _nearby(objects: Array) -> Array:
	objects.sort_custom(func(a, b): return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
	return objects.slice(0, maxi(1, observation_limit))

func _valid_target() -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion(): return false
	if target is Pickup:
		return not target.is_collected and not player._in_power_up_mode and (target.pickup_type == Pickup.PickupType.BASE or player.hp < Globals.MAX_HP)
	if target is Enemy: return not target.is_dead and target.hurt_area.enabled and player._in_power_up_mode
	if target is Player: return target.hp > 0 and target.visible and target._can_take_damage and player._in_power_up_mode
	return false

func _velocity(entity: Node2D) -> Vector2:
	return entity.linear_velocity if entity is RigidBody2D else Vector2.ZERO

func _dangerous(enemies: Array, players: Array) -> Array:
	if player._in_power_up_mode: return []
	var dangers = enemies.duplicate()
	for other in players:
		if other != player and other._in_power_up_mode: dangers.append(other)
	return _nearby(dangers)

func _goal_value(entity: Node2D) -> float:
	var distance = player.global_position.distance_to(entity.global_position)
	var value: float = 1.0
	if entity is Pickup:
		if entity.pickup_type == Pickup.PickupType.HEALTH:
			if player.hp >= Globals.MAX_HP: return 0.0
			value = 3.2 if player.hp == 1 else 1.25
		else:
			value = 1.5 if player.score_manager.powerup_progress == Globals.POWERUP_THRESHOLD - 1 else 1.0
	else:
		# Ignore targets beyond the remaining power-up's plausible travel distance.
		if distance > player._speed * player.powerup_timer.time_left + 100.0: return 0.0
		value = 1.4 if entity is Player else 1.0
	# Modest preference for an already useful axis, rather than only proximity.
	var offset = (entity.global_position - player.global_position).abs()
	var turning_cost = minf(offset.x, offset.y) * 0.3
	return value * 400.0 / (100.0 + distance + turning_cost)

func _choose_goal(pickups: Array, enemies: Array, players: Array, dangers: Array):
	var threat: Node2D
	var nearest: float = 175.0 if player.hp == 1 else 135.0
	for danger in dangers:
		var relative = danger.global_position - player.global_position
		var closing = relative + (_velocity(danger) - player.linear_velocity) * 0.25
		var distance = minf(relative.length(), closing.length())
		if distance < nearest:
			nearest = distance
			threat = danger
	if threat and player._can_take_damage:
		goal = Goal.EVADE
		target = null
		var away = player.global_position - threat.global_position
		if away.length_squared() < 1.0: away = Vector2.RIGHT.rotated(_rng.randf() * TAU)
		_goal_point = player.global_position + away.normalized() * 450.0
		_commit_left = 0.0
		return
	if _recover_left > 0.0:
		return
	var candidates: Array = pickups
	if player._in_power_up_mode:
		candidates = enemies.duplicate()
		for other in players:
			if other != player and other._can_take_damage: candidates.append(other)
	var best: Node2D
	var best_value: float = 0.0
	for entity in candidates:
		var value = _goal_value(entity)
		if value > best_value:
			best_value = value
			best = entity
	if _valid_target() and _commit_left > 0.0 and best_value < _goal_value(target) * 1.7:
		return
	if best:
		if target != best:
			_best_distance = INF
			_unproductive_time = 0.0
		target = best
		goal = Goal.HUNT if player._in_power_up_mode else (Goal.HEAL if best.pickup_type == Pickup.PickupType.HEALTH else Goal.COLLECT)
		_commit_left = target_commitment_time
	else:
		if goal != Goal.ROAM or _roam_left <= 0.0 or player.global_position.distance_to(_goal_point) < 90.0:
			_new_waypoint()

func _new_waypoint():
	goal = Goal.ROAM
	target = null
	_goal_point = Vector2(_rng.randf_range(_roam_bounds.position.x, _roam_bounds.end.x), _rng.randf_range(_roam_bounds.position.y, _roam_bounds.end.y))
	_roam_left = _rng.randf_range(1.8, 3.0)
	_best_distance = INF
	_unproductive_time = 0.0

func _decide():
	diagnostics.decisions += 1
	var pickups = _nearby(world.get_cpu_pickups())
	var enemies = _nearby(world.get_cpu_enemies())
	var players = world.get_cpu_players()
	var dangers = _dangerous(enemies, players)
	_choose_goal(pickups, enemies, players, dangers)
	if is_instance_valid(target): _goal_point = target.global_position
	var distance = player.global_position.distance_to(_goal_point)
	if distance < _best_distance - 30.0:
		_best_distance = distance
		_unproductive_time = 0.0
	else:
		_unproductive_time += decision_interval
	if _stuck_left <= 0.0:
		if player.global_position.distance_to(_anchor) < 65.0 or _unproductive_time > anti_stuck_time * 3.0:
			diagnostics.unsticks += 1
			diagnostics.stuck_seconds += anti_stuck_time
			_new_waypoint()
			_recover_left = target_commitment_time
		_anchor = player.global_position
		_stuck_left = anti_stuck_time
	var jitter = Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, aiming_error)
	var aim = _goal_point + jitter
	var goal_velocity = _velocity(target) if is_instance_valid(target) else Vector2.ZERO
	var coast = _predict(COAST)
	var coast_utility = _utility(coast, aim, goal_velocity, dangers, COAST)
	chosen_direction = COAST
	_path = coast.points
	if _kick_left <= 0.0:
		var next_direction = player._next_direction
		var next_path = _predict(next_direction)
		var next_utility = _utility(next_path, aim, goal_velocity, dangers, next_direction)
		# Later directions are planning hints only. A setup kick must still advance
		# one step in the cycle, respect cooldown, and pay its real danger cost.
		var future_utility = coast_utility
		for direction in range(4):
			if direction == next_direction: continue
			future_utility = maxf(future_utility, _utility(_predict(direction), aim, goal_velocity, dangers, direction))
		if _path_distance(coast.points, aim, goal_velocity) > 100.0:
			next_utility += clampf((future_utility - coast_utility - 40.0) * 0.4, 0.0, 80.0)
		if next_utility > coast_utility:
			chosen_direction = next_direction
			_path = next_path.points
	diagnostics.goals[goal] += 1
	if chosen_direction != COAST:
		if goal != Goal.EVADE and _recover_left <= 0.0 and _rng.randf() < hesitation_probability:
			chosen_direction = COAST
			_path = _predict(COAST).points
		else:
			player.cpu_kick(chosen_direction)
			_kick_left = min_kick_interval
			diagnostics.kicks += 1
			diagnostics.directions[chosen_direction] += 1
	if debug_enabled: queue_redraw()

func _radius() -> float:
	return player.collision_shape.shape.radius * player.collision_shape.global_scale.x

func _predict(action: int) -> Dictionary:
	var position = player.global_position
	var velocity = player.linear_velocity.limit_length(player._speed)
	if action != COAST:
		velocity = Player.DIRECTION_VECTORS[action] * minf(player._kick_force / player.mass, player._speed)
	var points = PackedVector2Array([position])
	var walls: int = 0
	var step = maxf(0.05, prediction_horizon) / SAMPLE_COUNT
	var radius = _radius()
	for sample in range(SAMPLE_COUNT):
		var remaining = step
		# At most three inexpensive wall reflections per sample. Walls are useful bounces.
		for bounce in range(3):
			var contact_time = remaining
			var normal = Vector2.ZERO
			for plane in _planes:
				var approach = velocity.dot(plane.normal)
				if approach >= -0.001: continue
				var gap = position.dot(plane.normal) - plane.distance - radius
				var hit_time = maxf(0.0, gap) / -approach
				if hit_time < contact_time:
					contact_time = hit_time
					normal = plane.normal
			position += velocity * contact_time
			remaining -= contact_time
			if normal == Vector2.ZERO: break
			velocity = velocity.bounce(normal)
			position += normal * 0.5
			walls += 1
		points.append(position)
	return {"points": points, "walls": walls}

# Relative segments detect passes through targets, rather than just the final distance.
func _path_distance(points: PackedVector2Array, point: Vector2, velocity: Vector2) -> float:
	var minimum: float = INF
	var step = maxf(0.05, prediction_horizon) / SAMPLE_COUNT
	for i in range(1, points.size()):
		var a = points[i - 1] - point - velocity * minf((i - 1) * step, 0.6)
		var b = points[i] - point - velocity * minf(i * step, 0.6)
		minimum = minf(minimum, Geometry2D.get_closest_point_to_segment(Vector2.ZERO, a, b).length())
	return minimum

func _utility(trajectory: Dictionary, aim: Vector2, goal_velocity: Vector2, dangers: Array, action: int) -> float:
	var points: PackedVector2Array = trajectory.points
	var minimum = _path_distance(points, aim, goal_velocity)
	var utility = player.global_position.distance_to(aim) - minimum
	var reach = 75.0 if goal in [Goal.COLLECT, Goal.HEAL] else (100.0 if goal == Goal.HUNT else 50.0)
	if minimum < reach: utility += 180.0 * (1.0 - minimum / reach)
	for danger in dangers:
		var separation = _path_distance(points, danger.global_position, _velocity(danger))
		var danger_radius = 90.0 if danger is Enemy else 110.0
		var risk = clampf(1.0 - (separation - _radius()) / danger_radius, 0.0, 1.0)
		utility -= risk * risk * danger_weight * (1.5 if player.hp == 1 else 0.8) * (1.0 if player._can_take_damage else 0.25)
	# Only punish repetitive wall contact that makes little useful progress.
	if minimum > player.global_position.distance_to(aim) - 40.0:
		utility -= trajectory.walls * 15.0
	if action != COAST: utility -= kick_penalty
	if _recover_left > 0.0 and action == COAST: utility -= 100.0
	return utility

func _draw():
	if not debug_enabled or not is_instance_valid(player) or not _was_alive: return
	var color = player.player_color
	draw_line(Vector2.ZERO, to_local(_goal_point), Color(color, 0.8), 1.5)
	draw_circle(to_local(_goal_point), 7.0, color, false, 1.5)
	for i in range(1, _path.size()):
		draw_line(to_local(_path[i - 1]), to_local(_path[i]), Color(color, 0.35), 1.0)
	var action = "COAST" if chosen_direction == COAST else ["RIGHT", "DOWN", "LEFT", "UP"][chosen_direction]
	var target_name = target.name if is_instance_valid(target) else "waypoint"
	draw_string(ThemeDB.fallback_font, Vector2(-45, -60), "%s %s" % [Goal.keys()[goal], action], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.BLACK)
	draw_string(ThemeDB.fallback_font, Vector2(-45, -40), str(target_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)
