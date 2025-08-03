class_name Player
extends RigidBody2D

# Constants
const POWERUP_TIME = 5.0
const BASE_SPEED = 500.0
const KICK_FORCE = 3000
const POWERUP_SPEED_FACTOR = 2.0
const POWERUP_SCALE_FACTOR = 2.5
const MAX_DIRECTIONS = 4
const DAMAGE_FLASH_DURATION = 0.5
const RESPAWN_DELAY = 3.0
const POWERUP_SCORE_MULTIPLIER = 4
const ENEMY_SCORE_MULTIPLIER = 2
const SQUISH_DURATION = 0.25
const SQUISH_INTENSITY = 0.7
const SQUISH_RECOVERY = 1.2
const ENEMY_COLLISION_LAYER = 1
const PLAYER_COLLISION_LAYER = 0

# Exported variables
@export var damage_cooldown_time: float = 1

# Node references
@onready var collision_shape := $CollisionShape2D
@onready var sprite := $Sprite2D
@onready var score_manager := $Score
@onready var powerup_timer := $PowerupTimer
@onready var direction_arrows := $DirectionArrows
@onready var star_sprite := $StarSprite
@onready var background_sprite := $BackgroundSprite
@onready var power_trail := $PowerTrail
@onready var powerup_fx := $PowerupFX
@onready var message_point := $MessagePoint
@onready var hurt_fx := $HurtFx
@onready var dash_fx := $DashFx
@onready var bubble_trail := $BubbleTrail

# Child nodes that need scaling
var scalable_nodes: Array[Node2D]

# Signals
signal player_died
signal powerup_activated(player: Player)
signal powerup_deactivated(player: Player)

# Enums
enum Direction { RIGHT, DOWN, LEFT, UP }

# Direction mapping
const DIRECTION_VECTORS = {
	Direction.RIGHT: Vector2.RIGHT,
	Direction.DOWN: Vector2.DOWN,
	Direction.LEFT: Vector2.LEFT,
	Direction.UP: Vector2.UP
}

# Player state
var current_direction: int
var hp: int
var _speed: float
var _kick_force: float
var _in_power_up_mode: bool = false
var _can_take_damage: bool = true
var _init_sprite_scale: Vector2
var _init_collision_scale: Vector2
var _next_direction: int = 0
var _original_collision_mask: int

# UI and data
var ui: PlayerUi
var _start_pos: Vector2
var _player_name: String
var player_color: Color
var player_data: PlayerData

# Tweens for reuse
var squish_tween: Tween
var scale_tween: Tween

func _ready() -> void:
	current_direction = Direction.RIGHT
	hide()
	_init_sprite_scale = sprite.scale
	_init_collision_scale = collision_shape.scale
	_setup_tweens()
	_original_collision_mask = collision_mask
	
	# Initialize scalable nodes
	scalable_nodes = [
		$AttackArea,
		$Sprite2D
	]

func _setup_tweens():
	squish_tween = create_tween()
	squish_tween.pause()
	scale_tween = create_tween()
	scale_tween.pause()

func respawn_player():
	"""Reset player to starting state"""
	_toggle_physics(true)
	position = _start_pos
	sprite.self_modulate.a = 1
	sprite.scale = _init_sprite_scale
	collision_shape.scale = _init_collision_scale
	hp = Globals.MAX_HP
	ui.update_health(hp)
	_can_take_damage = true
	_speed = BASE_SPEED
	_kick_force = KICK_FORCE
	show()
	Globals.create_flash_tween(sprite)

func start(data: PlayerData):
	"""Initialize player with given data"""
	if not data:
		push_error("Player data is null")
		return
		
	# Cache variables into player
	_start_pos = data.x0
	_player_name = data.name
	ui = data.ui
	player_color = data.color
	player_data = data
	ui.reset(data.id)
	score_manager.reset(ui, self)
	ui.show()
	_set_color()
	
	respawn_player()

func _toggle_physics(on: bool):
	"""Enable or disable physics processing"""
	linear_velocity = Vector2.ZERO
	collision_shape.call_deferred("set_disabled", !on)
	set_process_input(on)
	set_physics_process(on)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	"""Apply physics speed cap to prevent excessive velocity"""
	if state.linear_velocity.length() > _speed:
		state.linear_velocity = state.linear_velocity.normalized() * _speed

func _get_new_direction(_use_random: bool) -> int:
	"""Get the next direction in sequence"""
	var new_dir = (current_direction + 1) % MAX_DIRECTIONS
	if new_dir < 0:
		new_dir += MAX_DIRECTIONS
	return new_dir

func _update_direction(use_random: bool):
	"""Update current and next direction"""
	current_direction = _next_direction
	_next_direction = _get_new_direction(use_random)
	direction_arrows.show_arrow(_next_direction)

func _input(_event: InputEvent) -> void:
	"""Handle player input"""
	if Input.is_action_just_pressed(_player_name):
		_update_direction(true)
		kick_in_direction(current_direction)

func kick_in_direction(dir: int):
	"""Apply kick force in specified direction"""
	if dir < 0 or dir >= MAX_DIRECTIONS:
		push_error("Invalid direction: " + str(dir))
		return
		
	linear_velocity = Vector2.ZERO
	apply_central_impulse(DIRECTION_VECTORS[dir] * _kick_force)
	DampedOscillator.animate(sprite, "scale", 350.0, 30.0, 40.0, 0.2)
	dash_fx.emitting = true

func create_squish_effect(collision_normal: Vector2):
	"""Create improved squishy deformation effect based on collision direction"""
	if _in_power_up_mode:
		return
	
	# Kill existing squish tween
	if squish_tween and squish_tween.is_valid():
		squish_tween.kill()
	
	squish_tween = create_tween()
	squish_tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	
	# Calculate squish direction (perpendicular to collision normal)
	var squish_scale = _init_sprite_scale
	var abs_normal = collision_normal.abs()
	
	if abs_normal.x > abs_normal.y:
		# Horizontal collision - squish horizontally, stretch vertically
		squish_scale.x = _init_sprite_scale.x * SQUISH_INTENSITY
		squish_scale.y = _init_sprite_scale.y * SQUISH_RECOVERY
	else:
		# Vertical collision - squish vertically, stretch horizontally
		squish_scale.x = _init_sprite_scale.x * SQUISH_RECOVERY
		squish_scale.y = _init_sprite_scale.y * SQUISH_INTENSITY
	
	# Create a more bouncy squish effect with multiple phases
	# Phase 1: Initial squish (fast)
	squish_tween.tween_property(sprite, "scale", squish_scale, SQUISH_DURATION * 0.3)
	squish_tween.tween_property(sprite, "scale", squish_scale, 0.0)  # Ensure we start from squish
	
	# Phase 2: Overshoot recovery (medium)
	var overshoot_scale = _init_sprite_scale
	if abs_normal.x > abs_normal.y:
		overshoot_scale.x = _init_sprite_scale.x * 1.1
		overshoot_scale.y = _init_sprite_scale.y * 0.95
	else:
		overshoot_scale.x = _init_sprite_scale.x * 0.95
		overshoot_scale.y = _init_sprite_scale.y * 1.1
	
	squish_tween.chain().tween_property(sprite, "scale", overshoot_scale, SQUISH_DURATION * 0.4)
	
	# Phase 3: Final settle (slow)
	squish_tween.chain().tween_property(sprite, "scale", _init_sprite_scale, SQUISH_DURATION * 0.3)
	
	# Add some rotation for extra juice
	var rotation_amount = randf_range(-0.1, 0.1)
	squish_tween.parallel().tween_property(sprite, "rotation", rotation_amount, SQUISH_DURATION * 0.3)
	squish_tween.parallel().tween_property(sprite, "rotation", 0.0, SQUISH_DURATION * 0.7)

func take_damage(enemy_position: Vector2):
	"""Handle player taking damage"""
	if _can_take_damage:
		hurt_fx.emitting = true
		_can_take_damage = false
		hp -= 1
		ui.update_health(hp)
		
		if hp <= 0:
			die()
			PopupFx.display_popup("pop!", message_point.global_position, player_color)
		else:
			var direction = (global_position - enemy_position).normalized()
			apply_central_impulse(direction * KICK_FORCE * 1.5)
			
			PopupFx.display_popup("ouch!", message_point.global_position, player_color)
			
			# Start invincibility period with visual feedback
			_start_invincibility_period()

func _start_invincibility_period():
	"""Start the invincibility period with visual feedback"""
	# Create flashing effect during invincibility
	var flash_tween = create_tween()
	flash_tween.set_loops() # Loop indefinitely until we stop it
	
	# Flash between player color and white
	flash_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(sprite, "self_modulate", player_color, 0.1)
	
	# Start invincibility timer
	var invincibility_timer = get_tree().create_timer(damage_cooldown_time)
	invincibility_timer.timeout.connect(_end_invincibility_period.bind(flash_tween))

func _end_invincibility_period(flash_tween: Tween):
	"""End the invincibility period and restore normal state"""
	# Stop the flashing effect
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	# Restore normal appearance
	sprite.self_modulate.a = 1.0
	sprite.self_modulate = player_color
	
	# Re-enable damage taking
	_can_take_damage = true


func die():
	"""Handle player death"""
	_toggle_physics(false)
	
	var tween = Globals.create_flash_tween(sprite)
	tween.tween_property(sprite, "modulate:a", 0.0, DAMAGE_FLASH_DURATION)
	tween.parallel().tween_property(sprite, "rotation", PI/2, DAMAGE_FLASH_DURATION)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, DAMAGE_FLASH_DURATION)
	
	tween.finished.connect(
		func(): 
			player_died.emit()
			ui.write_resapwning()
			hide()
			await get_tree().create_timer(RESPAWN_DELAY).timeout
			respawn_player()
			ui.write_bash_mode()
	)

func increment_score(factor: int = 1):
	"""Increase player score"""
	var increase = score_manager.increment(_in_power_up_mode, factor)
	PopupFx.display_popup("+" + str(increase), message_point.global_position, player_color)

func increment_health():
	"""Increase player health if not at maximum"""
	if hp < Globals.MAX_HP: 
		hp += 1
	ui.update_health(hp)

func _resize_collision_safely(new_scale: Vector2):
	"""Safely resize collision shape without physics issues"""
	collision_shape.set_deferred("disabled", true)
	await get_tree().process_frame
	collision_shape.scale = new_scale
	collision_shape.set_deferred("disabled", false)

func _on_score_powerup_ready():
	"""Activate powerup mode"""
	if not _in_power_up_mode:
		print("Player went super saiyan")
		Globals.MainCam.SHAKE() 
		MusicManager.enter_powerup_mode()
		powerup_activated.emit(self)
		_in_power_up_mode = true
		powerup_timer.start(POWERUP_TIME)
		_speed = BASE_SPEED * POWERUP_SPEED_FACTOR
		_kick_force = KICK_FORCE * POWERUP_SPEED_FACTOR 
		kick_in_direction(current_direction)
		_can_take_damage = false
		
		# Disable RigidBody2D collision with enemy layer
		collision_mask &= ~(1 << ENEMY_COLLISION_LAYER)
		collision_mask &= ~(1 << PLAYER_COLLISION_LAYER)
		
		# Scale up with proper tween management
		if scale_tween and scale_tween.is_valid():
			scale_tween.kill()
		
		scale_tween = create_tween()
		scale_tween.set_parallel(true)
		
		# Scale sprite and scalable nodes
		scale_tween.tween_property(sprite, "scale", _init_sprite_scale * POWERUP_SCALE_FACTOR, 0.3)
		for node in scalable_nodes:
			if node != sprite:  # Sprite is already handled above
				scale_tween.tween_property(node, "scale", node.scale * POWERUP_SCALE_FACTOR, 0.3)
		
		# Resize collision shape safely
		_resize_collision_safely(_init_collision_scale * POWERUP_SCALE_FACTOR)
		
		background_sprite.show()
		power_trail.emitting = true
		powerup_fx.emitting = true

func _on_powerup_timer_timeout():
	"""Deactivate powerup mode"""
	MusicManager.exit_powerup_mode()
	_in_power_up_mode = false
	_speed = BASE_SPEED
	_kick_force = KICK_FORCE
	_can_take_damage = true
	sprite.self_modulate = player_color
	ui.update_bar(0)
	ui.write_bash_mode()
	powerup_timer.stop()
	score_manager.powerup_progress = 0
	
	# Restore original collision mask
	collision_mask = _original_collision_mask
	
	# Scale back to normal with proper tween management
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	
	scale_tween = create_tween()
	scale_tween.set_parallel(true)
	
	# Scale sprite and scalable nodes back to normal
	scale_tween.tween_property(sprite, "scale", _init_sprite_scale, 0.3)
	for node in scalable_nodes:
		if node != sprite:  # Sprite is already handled above
			var original_scale = node.scale / POWERUP_SCALE_FACTOR
			scale_tween.tween_property(node, "scale", original_scale, 0.3)
	
	# Resize collision shape back to normal
	_resize_collision_safely(_init_collision_scale)
	
	sprite.show()
	star_sprite.hide()
	background_sprite.hide()
	power_trail.emitting = false
	powerup_fx.emitting = false
	powerup_deactivated.emit(self)

func _on_body_entered(body):
	"""Handle RigidBody2D collision with other bodies"""
	if not body:
		return
	
	var collision_direction = (global_position - body.global_position).normalized()
	create_squish_effect(collision_direction)

func _set_color():
	"""Apply player color to all visual elements"""
	sprite.self_modulate = player_color
	star_sprite.self_modulate = player_color
	
	var color_low_alpha = player_color
	color_low_alpha.a = 0.4
	bubble_trail.color = color_low_alpha
	hurt_fx.color = color_low_alpha
	dash_fx.color = color_low_alpha 
	background_sprite.self_modulate = color_low_alpha
	$DirectionArrows/ActiveArrow.modulate = color_low_alpha
	$DirectionArrows.modulate = player_color
	power_trail.color = player_color
	powerup_fx.color = player_color

func _on_attack_area_entered(area):
	var entity = area.get_parent()
	if _in_power_up_mode:
		if entity is Player:
			if entity._can_take_damage:
				increment_score(POWERUP_SCORE_MULTIPLIER)
				entity.take_damage(global_position)
		elif entity is Enemy:
			increment_score(ENEMY_SCORE_MULTIPLIER)
