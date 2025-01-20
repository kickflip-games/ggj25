extends CharacterBody2D

const SPEED: float = 500.0

var Direction := {
	0: Vector2(1, 0), # Right
	1: Vector2(0, 1), # Down
	2: Vector2(-1, 0), # Left
	3: Vector2(0, -1) # Up
}
var curr_dir: int # Current direction


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
