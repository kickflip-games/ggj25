extends Node



const  MAX_HP:int = 3
const POWERUP_THRESHOLD:int = 5



const COLOR1:Color = Color("#231a28")
const COLOR2:Color = Color("#273450")
const COLOR3:Color = Color("#305358")
const COLOR4:Color = Color("#43785a")
const COLOR5:Color = Color("#528b57")


const PLAYER_COLORS = [
	Color.GOLD,
	Color.GREEN,
	Color.BLUE,
]

func create_flash_tween(sprite:Sprite2D):
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	return tween
