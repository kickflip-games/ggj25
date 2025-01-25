class_name Enemy
extends RigidBody2D


enum EnemyType{
	STATIC,
	ARROW,
	BOUNCER
}

@onready var background_sprite = $BackgroundSprite
@onready var sprite = $Sprite2D
@onready var hurt_area = $HurtArea
@export var enemy_type:EnemyType = EnemyType.BOUNCER
@export var speed = 250
@export var spawn_time=2
@export var timeout_time = 10

var has_started_moving:bool = false
var _is_dead:bool = false

var _init_background_scale:Vector2
var _init_sprite_scale:Vector2


func _ready():
	$CollisionShape2D.disabled = true
	sleeping = true
	_init_background_scale = background_sprite.scale
	_init_sprite_scale=sprite.scale
	
	begin_spawn()
	
	

	
func begin_spawn():
	# Fade in effect 
	print("Spawn enemy")
	sprite.scale = Vector2.ONE * 0.01
	background_sprite.scale = Vector2.ONE * 0.01
	sprite.modulate.a = 0.1
	background_sprite.modulate.a = 0.1
	

	
	var tween = create_tween().parallel()
	
	tween.tween_property(background_sprite, "scale", _init_background_scale, spawn_time/4)
	tween.tween_property(background_sprite, "modulate:a", 0.3, spawn_time/4)
	tween.tween_property(sprite, "scale", _init_sprite_scale, spawn_time)
	tween.tween_property(sprite, "modulate:a", 1, spawn_time)
	tween.finished.connect(
		func():
				print("Enable ennemy colliders")
				hurt_area.collision_occured.connect(die)
				hurt_area.enabled = true
				$CollisionShape2D.disabled = false
				sleeping = false
				custom_start_based_on_type()
				$TimeoutTimer.start(timeout_time)
	)

			
func custom_start_based_on_type():
	match enemy_type:
		EnemyType.ARROW:
			init_arrow_enemy()
		EnemyType.BOUNCER:
			init_bouncer_enemy()
		EnemyType.STATIC:
			init_static_enemy()


var direction:
	get:
		return Vector2(cos(rotation), sin(rotation)).normalized()

func init_static_enemy():
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", -20, 2).as_relative()
	tween.tween_property(self, "position:y", 20, 2).as_relative()
	


func init_arrow_enemy():
	# rotate_and_shoot_in_random_direction
	rotation = randf_range(0, 2 * PI)
	var tween = create_tween()
	var spin_speed = 360
	var spin_duration = 2
	tween.tween_property(self, "rotation_degrees", rotation_degrees + spin_speed * spin_duration, spin_duration)
	
	tween.finished.connect(
		func(): 
			has_started_moving= true
			angular_velocity = 0
			linear_velocity = direction * speed  # Adjust speed as desired
	)


func init_bouncer_enemy():
	# point_and_start_bouncing
	var tween = Globals.create_flash_tween(sprite)
	tween.finished.connect(
		func():
			rotation = [0, PI / 2, PI, 3 * PI / 2][randi() % 4]
			linear_velocity = direction * speed
	)
	



func die():
	
	if _is_dead:
		return
	
	print_debug("DIE")
	_is_dead = true
	hurt_area.enabled = false
	$CollisionShape2D.set_deferred("disabled",  true)
	
	linear_velocity=Vector2.ZERO
	
	var tween = Globals.create_flash_tween(sprite)
	# After flashing, fade away
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

	# Optional: rotate and scale down for added effect
	tween.parallel().tween_property(sprite, "rotation", PI/2, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)
	tween.parallel().tween_property(background_sprite, "scale", Vector2.ZERO, 0.5)
	

	# Connect to the tween's finished signal to queue_free  
	tween.finished.connect(queue_free)


func _on_body_entered(body):
	if body is StaticBody2D:  # Use groups to identify walls
		print("Collided with a wall")
		if enemy_type == EnemyType.ARROW:
			die()


func _on_timeout_timer_timeout():
	die()
