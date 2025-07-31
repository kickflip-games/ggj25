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
const SQUISH_DURATION = 0.15
const SQUISH_INTENSITY = 1.7

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

# Signals
signal player_died
signal powerup_activated(player: Player)
signal powerup_deactivated

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
var _next_direction: int = 0

# UI and data
var ui: PlayerUi
var _start_pos: Vector2
var _player_name: String
var player_color: Color
var player_data: PlayerData

# Tweens for reuse
var squish_tween: Tween

func _ready() -> void:
	current_direction = Direction.RIGHT
	hide()
	_init_sprite_scale = sprite.scale
	_setup_tweens()

func _setup_tweens():
	squish_tween = create_tween()
	squish_tween.pause()

func respawn_player():
	"""Reset player to starting state"""
	_toggle_physics(true)
	position = _start_pos
	sprite.modulate.a = 1
	sprite.scale = _init_sprite_scale
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
	score_manager.reset(ui)
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
	"""Create squishy deformation effect based on collision direction"""
	if squish_tween:
		squish_tween.kill()
	
	squish_tween = create_tween()
	
	# Calculate squish direction (perpendicular to collision normal)
	var squish_scale = Vector2.ONE
	var abs_normal = collision_normal.abs()
	
	if abs_normal.x > abs_normal.y:
		# Horizontal collision - squish vertically
		squish_scale.y = SQUISH_INTENSITY
	else:
		# Vertical collision - squish horizontally  
		squish_scale.x = SQUISH_INTENSITY
	
	# Apply squish and bounce back
	squish_tween.tween_property(sprite, "scale", _init_sprite_scale * squish_scale, SQUISH_DURATION * 0.3)
	squish_tween.tween_property(sprite, "scale", _init_sprite_scale, SQUISH_DURATION * 0.7)

func take_damage():
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
			PopupFx.display_popup("ouch!", message_point.global_position, player_color)
			var tween = Globals.create_flash_tween(sprite)
			tween.finished.connect(
				func(): 
					_can_take_damage = true
					sprite.modulate.a = 1
			)

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

func _on_score_powerup_ready():
	"""Activate powerup mode"""
	if not _in_power_up_mode:
		print("Player went super saiyan")
		Globals.MainCam.SHAKE() 
		powerup_activated.emit(self)  # Emit with player reference
		_in_power_up_mode = true
		powerup_timer.start(POWERUP_TIME)
		_speed = BASE_SPEED * POWERUP_SPEED_FACTOR
		_kick_force = KICK_FORCE * POWERUP_SPEED_FACTOR 
		kick_in_direction(current_direction)
		_can_take_damage = false
		
		# Scale up the sprite during powerup
		var scale_tween = create_tween()
		scale_tween.tween_property(sprite, "scale", _init_sprite_scale * POWERUP_SCALE_FACTOR, 0.3)
		
		#sprite.hide()
		#star_sprite.show()
		background_sprite.show()
		power_trail.emitting = true
		powerup_fx.emitting = true

func _on_powerup_timer_timeout():
	"""Deactivate powerup mode"""
	_in_power_up_mode = false
	_speed = BASE_SPEED
	_kick_force = KICK_FORCE
	_can_take_damage = true
	sprite.modulate = player_color
	ui.update_bar(0)
	powerup_timer.stop()
	score_manager.powerup_progress = 0
	
	# Scale back to normal
	var scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", _init_sprite_scale, 0.3)
	
	sprite.show()
	star_sprite.hide()
	background_sprite.hide()
	power_trail.emitting = false
	powerup_fx.emitting = false
	powerup_deactivated.emit()

func _on_body_entered(body):
	"""Handle collision with other bodies"""
	if not body:
		return
		
	if _in_power_up_mode:
		if body is Player:
			increment_score(POWERUP_SCORE_MULTIPLIER)
			body.take_damage()
		elif body is Enemy:
			increment_score(ENEMY_SCORE_MULTIPLIER)
	else:
		# Create squishy collision effect
		var collision_direction = (global_position - body.global_position).normalized()
		create_squish_effect(collision_direction)

func _set_color():
	"""Apply player color to all visual elements"""
	sprite.modulate = player_color
	star_sprite.modulate = player_color
	
	var color_low_alpha = player_color
	color_low_alpha.a = 0.4
	bubble_trail.color = color_low_alpha
	hurt_fx.color = color_low_alpha
	dash_fx.color = color_low_alpha 
	background_sprite.modulate = color_low_alpha
	$DirectionArrows/ActiveArrow.modulate = color_low_alpha
	power_trail.color = player_color
	powerup_fx.color = player_color
