extends Area2D

@onready var sprite = $Sprite2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", sprite.scale*2, 0.3)
		tween.tween_property(sprite, "modulate:a", 0,0.3) 
		tween.finished.connect(queue_free)
