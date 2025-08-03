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
	var tween = create_tween().set_loops()
	tween.tween_property($Background, "modulate:a", 0.1, 1)
	tween.tween_property($Background, "modulate:a", 1, 1)
	
	
	var tween2 = create_tween().set_loops()
	tween2.tween_property(self, "position:y", -20, 2).as_relative()
	tween2.tween_property(self, "position:y", 20, 2).as_relative()



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
		


func handle_base_pickup(body: Node2D):
	body.increment_score()



func handle_health_pickup(body: Node2D):
	body.increment_health()
