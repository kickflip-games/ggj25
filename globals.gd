extends Node



const  MAX_HP:int = 3



func create_flash_tween(sprite:Sprite2D):
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	return tween
