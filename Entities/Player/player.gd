class_name Player
extends CharacterBody2D

@export var SPEED: float = 500.0
@export var damage_cooldown_time:float = 1

var Direction := {
	0: Vector2(1, 0), # Right
	1: Vector2(0, 1), # Down
	2: Vector2(-1, 0), # Left
	3: Vector2(0, -1), # Up
	-1: Vector2.ZERO
}
var curr_dir: int # Current direction

var hp:int = 3
var _can_take_damage:bool=true


@onready var collision_shape:= $CollisionShape2D
@onready var sprite:=$Sprite2D

func _ready() -> void:
	curr_dir = 0
	
func _physics_process(delta):
	velocity = Direction[curr_dir] * SPEED
	
	# Handle bouncing off the screen edge
	var collision = move_and_collide(velocity * delta)
	if collision:
		_environment_change_direction()  
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE: # TODO: Make this more generic (e.g. key press at start)
			_player_change_direction() 

# Change direction in looping clockwise orientation
func _player_change_direction() -> void:
	curr_dir = (curr_dir + 1) % 4

# Hacky way to bounce off a surface, should be changed	
func _environment_change_direction() -> void:
	curr_dir = (curr_dir + 2 ) % 4


func take_damage():
	if not _can_take_damage:
		return 
	hp -= 1
	
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
	collision_shape.set_deferred("disabled", true)

	# Create a new Tween
	var tween = create_flash_tween()
	# After flashing, fade away
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

	# Optional: rotate and scale down for added effect
	tween.parallel().tween_property(sprite, "rotation", PI/2, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)

	# Connect to the tween's finished signal to queue_free the player
	tween.finished.connect(func():get_tree().reload_current_scene())

	# You might want to emit a signal here to inform other parts of your game
	# emit_signal("player_died")
	
	# restart 
	
