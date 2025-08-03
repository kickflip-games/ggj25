class_name Enemy
extends RigidBody2D

# Constants
const FADE_IN_ALPHA = 0.1
const BACKGROUND_FADE_ALPHA = 0.3
const TINY_SCALE = 0.01
const STATIC_FLOAT_DISTANCE = 20.0
const STATIC_FLOAT_DURATION = 2.0
const ARROW_SPIN_SPEED = 360.0
const ARROW_SPIN_DURATION = 2.0
const DEATH_FADE_DURATION = 0.5
const FREEZE_ALPHA_FACTOR = 0.3

# Enums
enum EnemyType {
	STATIC,
	ARROW,
	BOUNCER
}

# Exported variables
@export var enemy_type: EnemyType
@export var speed: int = 250
@export var spawn_time: float = 2.0
@export var timeout_time: float = 10.0

# Node references
@onready var background_sprite := $BackgroundSprite
@onready var sprite := $Sprite2D
@onready var hurt_area := $HurtArea
@onready var collision_shape := $CollisionShape2D
@onready var timeout_timer := $TimeoutTimer

# State variables
var has_started_moving: bool = false
var is_dead: bool = false
var is_frozen: bool = false
var _init_background_scale: Vector2
var _init_sprite_scale: Vector2
var _original_sprite_color: Color
var _original_background_color: Color

# Tweens for reuse
var movement_tween: Tween
var death_tween: Tween

func _ready():
	_initialize_enemy()
	_cache_initial_values()
	begin_spawn()

func _initialize_enemy():
	"""Set up initial enemy state"""
	collision_shape.disabled = true
	sleeping = true
	var enemy_types = [EnemyType.STATIC, EnemyType.ARROW, EnemyType.BOUNCER]
	enemy_type = enemy_types.pick_random()
	
	

func _cache_initial_values():
	"""Cache initial scale and color values"""
	_init_background_scale = background_sprite.scale
	_init_sprite_scale = sprite.scale
	_original_sprite_color = sprite.modulate
	_original_background_color = background_sprite.modulate

func begin_spawn():
	"""Start the enemy spawn animation"""
	_setup_spawn_appearance()
	_animate_spawn_in()

func _setup_spawn_appearance():
	"""Set initial appearance for spawn animation"""
	sprite.scale = Vector2.ONE * TINY_SCALE
	background_sprite.scale = Vector2.ONE * TINY_SCALE
	sprite.modulate.a = FADE_IN_ALPHA
	background_sprite.modulate.a = FADE_IN_ALPHA

func _animate_spawn_in():
	"""Animate the enemy spawning in"""
	var spawn_tween = create_tween().set_parallel(true)
	
	# Background animation (faster)
	spawn_tween.tween_property(background_sprite, "scale", _init_background_scale, spawn_time * 0.25)
	spawn_tween.tween_property(background_sprite, "modulate:a", BACKGROUND_FADE_ALPHA, spawn_time * 0.25)
	
	# Sprite animation (full duration)
	spawn_tween.tween_property(sprite, "scale", _init_sprite_scale, spawn_time)
	spawn_tween.tween_property(sprite, "modulate:a", 1.0, spawn_time)
	
	spawn_tween.finished.connect(_on_spawn_complete)

func _on_spawn_complete():
	"""Called when spawn animation completes"""
	
	# Enable collision and hurt detection
	hurt_area.collision_occured.connect(die)
	hurt_area.enabled = true
	collision_shape.disabled = false
	sleeping = false
	
	# Start enemy-specific behavior
	_start_enemy_behavior()
	timeout_timer.start(timeout_time)

func _start_enemy_behavior():
	"""Initialize behavior based on enemy type"""
	match enemy_type:
		EnemyType.ARROW:
			_init_arrow_enemy()
		EnemyType.BOUNCER:
			_init_bouncer_enemy()
		EnemyType.STATIC:
			_init_static_enemy()

# Direction property for movement calculations
var direction: Vector2:
	get:
		return Vector2(cos(rotation), sin(rotation)).normalized()

func _init_static_enemy():
	"""Initialize floating static enemy behavior"""
	movement_tween = create_tween().set_loops()
	movement_tween.tween_property(self, "position:y", -STATIC_FLOAT_DISTANCE, STATIC_FLOAT_DURATION).as_relative()
	movement_tween.tween_property(self, "position:y", STATIC_FLOAT_DISTANCE, STATIC_FLOAT_DURATION).as_relative()

func _init_arrow_enemy():
	"""Initialize spinning arrow enemy that shoots in a direction"""
	# Set random initial rotation
	rotation = randf_range(0, 2 * PI)
	
	# Create spinning animation
	var spin_tween = create_tween()
	var total_spin = rotation_degrees + (ARROW_SPIN_SPEED * ARROW_SPIN_DURATION)
	spin_tween.tween_property(self, "rotation_degrees", total_spin, ARROW_SPIN_DURATION)
	
	spin_tween.finished.connect(_on_arrow_spin_complete)

func _on_arrow_spin_complete():
	"""Called when arrow enemy finishes spinning"""
	has_started_moving = true
	angular_velocity = 0
	linear_velocity = direction * speed

func _init_bouncer_enemy():
	"""Initialize bouncing enemy behavior"""
	var flash_tween = Globals.create_flash_tween(sprite)
	flash_tween.finished.connect(_on_bouncer_flash_complete)

func _on_bouncer_flash_complete():
	"""Called when bouncer enemy finishes flashing"""
	# Choose random cardinal direction
	var cardinal_rotations = [0, PI * 0.5, PI, PI * 1.5]
	rotation = cardinal_rotations[randi() % cardinal_rotations.size()]
	linear_velocity = direction * speed

func die():
	"""Handle enemy death"""
	if is_dead:
		return
	is_dead = true
	
	_disable_enemy()
	_animate_death()

func _disable_enemy():
	"""Disable enemy collision and movement"""
	hurt_area.enabled = false
	collision_shape.set_deferred("disabled", true)
	linear_velocity = Vector2.ZERO
	
	# Stop any ongoing movement tweens
	if movement_tween:
		movement_tween.kill()

func _animate_death():
	"""Animate enemy death sequence"""
	death_tween = Globals.create_flash_tween(sprite)
	
	# Fade out and shrink
	death_tween.tween_property(sprite, "modulate:a", 0.0, DEATH_FADE_DURATION)
	death_tween.parallel().tween_property(sprite, "rotation", PI * 0.5, DEATH_FADE_DURATION)
	death_tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, DEATH_FADE_DURATION)
	death_tween.parallel().tween_property(background_sprite, "scale", Vector2.ZERO, DEATH_FADE_DURATION)
	
	death_tween.finished.connect(queue_free)

func freeze():
	"""Freeze enemy when player enters powerup mode"""
	if is_dead or is_frozen:
		return
		
	is_frozen = true
	timeout_timer.paused = true
	
	# Stop movement
	var current_velocity = linear_velocity
	set_meta("frozen_velocity", current_velocity)
	linear_velocity = Vector2.ZERO
	
	# Stop movement tweens
	if movement_tween:
		movement_tween.pause()
	
	# Dim colors
	var frozen_sprite_color = _original_sprite_color
	frozen_sprite_color.a *= FREEZE_ALPHA_FACTOR
	var frozen_bg_color = _original_background_color
	frozen_bg_color.a *= FREEZE_ALPHA_FACTOR
	
	var freeze_tween = create_tween().set_parallel(true)
	freeze_tween.tween_property(sprite, "modulate", frozen_sprite_color, 0.2)
	freeze_tween.tween_property(background_sprite, "modulate", frozen_bg_color, 0.2)

func resume():
	"""Resume enemy when player exits powerup mode"""
	if is_dead or not is_frozen:
		return
		
	is_frozen = false
	timeout_timer.paused = false
	
	# Restore movement
	if has_meta("frozen_velocity"):
		linear_velocity = get_meta("frozen_velocity")
		remove_meta("frozen_velocity")
	
	# Resume movement tweens
	if movement_tween:
		movement_tween.play()
	
	# Restore colors
	var resume_tween = create_tween().set_parallel(true)
	resume_tween.tween_property(sprite, "modulate", _original_sprite_color, 0.2)
	resume_tween.tween_property(background_sprite, "modulate", _original_background_color, 0.2)

func _on_body_entered(body):
	"""Handle collision with other bodies"""
	print("enemy body collison with ", body.name)
	if body is StaticBody2D:
		if enemy_type == EnemyType.ARROW:
			die()

func _on_timeout_timer_timeout():
	"""Handle enemy timeout"""
	die()

func get_enemy_type_name() -> String:
	"""Get human-readable enemy type name"""
	return EnemyType.keys()[enemy_type].capitalize()

func is_moving() -> bool:
	"""Check if enemy is currently moving"""
	return linear_velocity.length() > 0.1

func get_movement_speed() -> float:
	"""Get current movement speed"""
	return linear_velocity.length()
