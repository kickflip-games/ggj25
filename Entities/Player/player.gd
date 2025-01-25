class_name Player
extends RigidBody2D

const POWERUP_TIME = 3.0
const BASE_SPEED = 500.0
const KICK_FORCE = 3000
const POWERUP_SPEED_FACTOR = 2 

@export var damage_cooldown_time:float = 1
@onready var collision_shape:= $CollisionShape2D
@onready var sprite:=$Sprite2D
@onready var score_manager:=$Score
@onready var powerup_timer:=$PowerupTimer
@onready var direction_arrows:=$DirectionArrows






signal player_died
signal powerup_activated

var Direction = {
	0: Vector2.RIGHT, # Right
	1: Vector2.DOWN, # Down
	2: Vector2.LEFT, # Left
	3: Vector2.UP, # Up
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
var _start_pos:Vector2

var _name:String





func _ready() -> void:
	curr_dir = 0
	hide()
	_init_sprite_scale = sprite.scale
	
func start(player_data:PlayerData):
	# Cache varibles into player
	_start_pos = player_data.x0
	_name = player_data.name
	ui = player_data.ui
	
	# reset player to starting state
	_toggle_physics(true)
	position = _start_pos
	sprite.modulate.a = 1
	sprite.scale = _init_sprite_scale
	hp=Globals.MAX_HP
	score_manager.reset(ui)
	_can_take_damage=true
	ui.reset()
	_speed = BASE_SPEED
	_kick_force = KICK_FORCE
	show()
	
	
func _toggle_physics(on:bool):
	linear_velocity =  Vector2.ZERO
	collision_shape.call_deferred("set_disabled", !on)
	set_process_input(on)
	set_physics_process(on)
	

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Cap the speed at _speed
	if state.linear_velocity.length() > _speed:
		state.linear_velocity = state.linear_velocity.normalized() * _speed
		
	if Direction[_next_dir].distance_to(state.linear_velocity.normalized()) < 0.1:
		print("Manual change dir... TODO: make the new direction point INNWARDS TO CENTER")
		_update_dir(false)


func _get_new_dir(rand_dir:bool):
	var new_dir:int 
	
	rand_dir = true # TURNED OFF 
	

	#var random_change = (randi() % 2) * 2 - 1  # Generates either -1 or +1
	var random_change = 1
	new_dir = (curr_dir + random_change) % 4
	if new_dir < 0:
		new_dir += 4  # Ensure the direction stays in the range 0 to 3	
	
	
	
	return new_dir
	



func _update_dir(rand_dir:bool):
	_prev_dir = curr_dir
	curr_dir = _next_dir
	_next_dir = _get_new_dir(rand_dir)
	direction_arrows.show_arrow(_next_dir)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed(_name):
			_update_dir(true)
			kick_in_direction(curr_dir)
			 

func kick_in_direction(dir:int):
	linear_velocity = Vector2.ZERO
	apply_central_impulse(Direction[dir] * _kick_force)  # Apply force at the center of the body
	DampedOscillator.animate(sprite, "scale", 350.0, 30.0, 40.0, 0.2)
	$DashFx.emitting = true # todo -- not pl;ayinng everytime... wtf? 


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
	_toggle_physics(false)


	# Create a new Tween
	var tween = Globals.create_flash_tween(sprite)
	tween.tween_property(sprite, "modulate", 0.0, 0.5)
	tween.parallel().tween_property(sprite, "rotation", PI/2, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)

	tween.finished.connect(
		func(): 
			player_died.emit()
			hide()
	)
	


func increment_score():
	score_manager.increment()
	
func increment_health():
	if hp < Globals.MAX_HP: 
		hp += 1
	ui.update_health(hp)


func _on_score_powerup_ready():
	if not _in_power_up_mode:
		print("Player went super sayin")
		powerup_activated.emit()
		_in_power_up_mode = true
		powerup_timer.start(POWERUP_TIME)
		_speed = BASE_SPEED * POWERUP_SPEED_FACTOR
		_kick_force = KICK_FORCE * POWERUP_SPEED_FACTOR 
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


func _on_body_entered(body):
	DampedOscillator.animate(sprite, "scale", 200.0, 10.0, 15.0, 0.25)
