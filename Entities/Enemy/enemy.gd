extends RigidBody2D

enum EnemyType{
	STATIC,
	ARROW,
	BOUNCER
}

@onready var sprite = $Sprite2D
@onready var hurt_area = $HurtArea

@export var enemy_type:EnemyType = EnemyType.STATIC



func _ready():
	#hurt_area.collision_occured.connect(die)
	
	match enemy_type:
		EnemyType.ARROW:
			rotate_and_shoot_in_random_direction()
		EnemyType.BOUNCER:
			pass
		EnemyType.STATIC:
			pass


func rotate_and_shoot_in_random_direction():
	# set a random rotation for transform
	rotation_degrees = randf_range(0, 360)
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", 10, 2)  # Adjust duration as needed
	tween.finished.connect(
		func(): 
			var forward_dir = Vector2.RIGHT.rotated(rotation)  # RIGHT is the default forward
			linear_velocity = forward_dir * 400  # Adjust speed as desired
 
	)




func die():
	print_debug("DIE")
	hurt_area.queue_free()
	linear_velocity=Vector2.ZERO
	var tween = create_tween()
		# Flash the sprite 3 times
	for i in range(3):
		# Fade out
		tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)

	# After flashing, fade away
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

	# Optional: rotate and scale down for added effect
	tween.parallel().tween_property(sprite, "rotation", PI/2, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)

	# Connect to the tween's finished signal to queue_free  
	tween.finished.connect(queue_free)



func _physics_process(delta):
	var collision = move_and_collide(linear_velocity * delta)
	if collision:
		print(collision)
		die()
