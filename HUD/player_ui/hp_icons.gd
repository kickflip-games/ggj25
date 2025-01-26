extends HBoxContainer


@onready var hearts:=[
	$ColorRect,
	$ColorRect2,
	$ColorRect3
]


func set_hp(val:int, color:Color):
	# color the first "val" hearts by color, others are se to black
	for i in range(hearts.size()):
		if i < val:
			hearts[i].modulate = color
		else:
			hearts[i].modulate = Color(0, 0, 0)  # Set to black
			
	var t = create_tween().set_loops(5)
	for i in range(hearts.size()):
		t.tween_property(hearts[i], "modulate:a", 0, 0.2)
		t.tween_property(hearts[i], "modulate:a", 1, 0.2)
	

	
	
