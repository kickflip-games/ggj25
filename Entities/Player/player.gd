class_name Player
extends CharacterBody2D

const MAX_HP = 3

@export var SPEED: float = 500.0
@export var damage_cooldown_time:float = 1

@onready var collision_shape:= $CollisionShape2D
@onready var sprite:=$Sprite2D

signal player_died
signal player_taken_damage

var Direction := {
	0: Vector2(1, 0), # Right
	1: Vector2(0, 1), # Down
	2: Vector2(-1, 0), # Left
	3: Vector2(0, -1), # Up
	-1: Vector2.ZERO
}
var curr_dir: int # Current direction
var hp:int = MAX_HP
var _can_take_damage:bool=true
var _init_sprite_scale:Vector2




func _ready() -> void:
	curr_dir = 0
	hide()
	_init_sprite_scale = sprite.scale
	
func start(pos):
	position = pos
	collision_shape.disabled = false
	set_process_input(true)
	set_physics_process(true)
	sprite.modulate.a = 1
	sprite.scale = _init_sprite_scale
	hp=MAX_HP
	_can_take_damage=true
	
	show()
	
	
	
func _physics_process(delta):
	velocity = Direction[curr_dir] * SPEED
	
	# Handle bouncing off the screen edge
	var collision = move_and_collide(velocity * delta)
	if collision:
		_environment_change_direction()  
	
func _input(event: InputEvent) -> void:
	var key_press = event is InputEventKey   and event.pressed
	var mouse_press = event is InputEventMouseButton  and event.pressed

	if key_press or mouse_press: # TODO: Make this more generic (e.g. key press at start)
			_player_change_direction() 

# Change direction in looping clockwise orientation
func _player_change_direction() -> void:
	curr_dir = (curr_dir + 1) % 4

# Hacky way to bounce off a surface, should be changed	
func _environment_change_direction() -> void:
	curr_dir = (curr_dir + 2 ) % 4


func take_damage():
	if  _can_take_damage:
		
		_can_take_damage = false
		hp -= 1
		player_taken_damage.emit(hp)
		if hp <= 0:
			die()
		else:
			var tween = create_flash_tween()
			tween.finished.connect( func(): _can_take_damage = true)


func create_flash_tween():
	var tween = create_tween()
	for i in range(3):
		# Fade out
		tween.tween_property(sprite, "modulate:a", 0.1, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	return tween



func die():
	# Disable player input and collision
	set_process_input(false)
	set_physics_process(false)
	collision_shape.call_deferred("set_disabled", true)

	# Create a new Tween
	var tween = create_flash_tween()
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

	
	
	# restart 
	
