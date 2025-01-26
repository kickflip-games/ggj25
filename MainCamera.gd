extends Camera2D
class_name MainCamera

@onready var shaker = $ShakerComponent2D

func SHAKE():
	shaker.play_shake()
	print("Cam shake")
