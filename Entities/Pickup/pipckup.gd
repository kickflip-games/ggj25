class_name Pickup
extends Area2D

enum PickupType {
	BASE,
	HEALTH
}

@export var pickup_type:PickupType = PickupType.BASE

@onready var sprite = $Sprite2D
@onready var fx = $PickupFx

signal collected
 
func _ready():
	custom_start_based_on_type()

func custom_start_based_on_type():
	match pickup_type:
		PickupType.BASE:
			init_base_pickup()
		PickupType.HEALTH:
			init_health_pickup()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		fx.emitting = true
		collected.emit()
	
		match pickup_type:
			PickupType.BASE:
				handle_base_pickup(body)
			PickupType.HEALTH:
				handle_health_pickup(body)
				
		$CollisionShape2D.set_deferred("disabled", true)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", sprite.scale*2, 0.3)
		tween.tween_property(sprite, "modulate:a", 0,0.3) 
		tween.finished.connect(queue_free)
		

func init_base_pickup():
	print("initialising base pickup")
	sprite.modulate = Color(1, 1, 1)  # Default
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -20, 2).as_relative()
	tween.tween_property(sprite, "position:y", 20, 2).as_relative()

func handle_base_pickup(body: Node2D):
	body.increment_score()

func init_health_pickup():
	print("initialising health pickup")
	sprite.modulate = Color(1, 0, 0)  # Red

func handle_health_pickup(body: Node2D):
	body.increment_health()
