extends Node2D

enum EnemyType{
	STATIC,
	ARROW,
	BOUNCER
}

@onready var sprite = $Sprite2D
@onready var hurt_area = $HurtArea

@export var enemy_type:EnemyType



func _ready():
	hurt_area.collision_occured.connect(die)




func die():
	hurt_area.queue_free()
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
	tween.connect("finished", queue_free)
