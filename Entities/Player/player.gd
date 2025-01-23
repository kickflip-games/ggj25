class_name Player
extends RigidBody2D

const POWERUP_TIME = 3.0
const BASE_SPEED = 500.0
const KICK_FORCE = 2000
const POWERUP_SPEED_FACTOR = 2 

@export var damage_cooldown_time:float = 1
@onready var collision_shape:= $CollisionShape2D
@onready var sprite:=$Sprite2D
@onready var score_manager:=$Score
@onready var powerup_timer:=$PowerupTimer
@onready var direction_arrows:=$DirectionArrows



signal player_died

var Direction = {
	0: Vector2.RIGHT, # Right
	1: Vector2.DOWN, # Down
	2: Vector2.LEFT, # Left
	3: Vector2.UP, # Up
	-1: Vector2.ZERO
}
var curr_dir: int # Current direction
var hp:int
var _speed:int
var _kick_force:float
var _in_power_up_mode:bool=false

var _can_take_damage:bool=true
var _init_sprite_scale:Vector2

var _next_dir:int=0
var _prev_dir:int =0 

var ui:PlayerUi



func _ready() -> void:
	curr_dir = 0
	hide()
	_init_sprite_scale = sprite.scale
	
func start(pos:Vector2, player_ui:PlayerUi):
	position = pos
	collision_shape.disabled = false
	set_process_input(true)
	set_physics_process(true)
	sprite.modulate.a = 1
	sprite.scale = _init_sprite_scale
	hp=Globals.MAX_HP
	score_manager.reset(player_ui)
	_can_take_damage=true
	ui = player_ui
	ui.reset()
	_speed = BASE_SPEED
	_kick_force = KICK_FORCE
	show()
	

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Cap the speed at _speed
	if state.linear_velocity.length() > _speed:
		state.linear_velocity = state.linear_velocity.normalized() * _speed



#func _physics_process(delta):
	## Handle bouncing off the screen edge
	#var collision = move_and_collide(velocity * delta)
	#if collision:
		#_environment_change_direction()  
		
	## Cap the speed at _speed
	#if linear_velocity.length() > _speed:
		#linear_velocity = linear_velocity.normalized() * _speed
		#
	#if _in_power_up_mode:
		#linear_velocity = Direction[curr_dir] * _speed
	
func _input(event: InputEvent) -> void:
	var key_press = event is InputEventKey   and event.pressed
	var mouse_press = event is InputEventMouseButton  and event.pressed

	if key_press or mouse_press: # TODO: Make this more generic (e.g. key press at start)
			_prev_dir = curr_dir
			curr_dir = _next_dir
			_next_dir = (curr_dir + 1) % 4 
			direction_arrows.show_arrow(_next_dir)
			kick_in_direction(curr_dir)
			 

func kick_in_direction(dir:int):
	apply_central_impulse(Direction[dir] * _kick_force)  # Apply force at the center of the body


# Hacky way to bounce off a surface, should be changed	
func _environment_change_direction() -> void:
	curr_dir = (curr_dir + 2 ) % 4


func take_damage():
	if  _can_take_damage:
		$HurtFx.emitting = true
		_can_take_damage = false
		hp -= 1
		ui.update_health(hp)
		if hp <= 0:
			die()
		else:
			var tween = Globals.create_flash_tween(sprite)
			tween.finished.connect( 
				func(): 
					_can_take_damage = true
					sprite.modulate.a = 1
					)




func die():
	# Disable player input and collision
	set_process_input(false)
	set_physics_process(false)
	collision_shape.call_deferred("set_disabled", true)

	# Create a new Tween
	var tween = Globals.create_flash_tween(sprite)
	# After flashing, fade away
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

	# Optional: rotate and scale down for added effect
	tween.parallel().tween_property(sprite, "rotation", PI/2, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)

	tween.finished.connect(
		func(): 
			player_died.emit()
			hide()
	)
	


func increment_score():
	score_manager.increment()


func _on_score_powerup_ready():
	if not _in_power_up_mode:
		_in_power_up_mode = true
		powerup_timer.start(POWERUP_TIME)
		_speed = BASE_SPEED * POWERUP_SPEED_FACTOR
		_kick_force = KICK_FORCE * POWERUP_SPEED_FACTOR * 4
		kick_in_direction(curr_dir)
		_can_take_damage = false
		sprite.modulate = Color.DARK_BLUE


func _on_powerup_timer_timeout():
	_in_power_up_mode = false
	_speed = BASE_SPEED
	_kick_force = KICK_FORCE
	_can_take_damage = true
	sprite.modulate = Color.GOLD
	ui.update_bar(0)
	powerup_timer.stop()
	score_manager.powerup_progress = 0 
