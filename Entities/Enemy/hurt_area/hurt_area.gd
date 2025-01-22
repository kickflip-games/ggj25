extends Area2D


signal collision_occured
var enabled:bool = false



func _on_body_entered(body):
	if enabled:
		if body is Player:
			body.take_damage()
			collision_occured.emit()
		if body.is_in_group("WALLS"):
			collision_occured.emit()
	
