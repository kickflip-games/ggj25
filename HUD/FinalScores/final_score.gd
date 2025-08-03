extends VBoxContainer


@onready var nameLbl:=$Name
@onready var scoreLbl:=$Score
@onready var background:=$background

func create(pid:int, score:int, is_winner:bool):
	var c = Globals.PLAYER_COLORS[pid]
	nameLbl.text = "Player " + str(pid+1)
	scoreLbl.text = str(score).pad_zeros(4)
	nameLbl.add_theme_color_override("font_color", c)
	scoreLbl.add_theme_color_override("font_color", c)
	background.modulate = c
	if is_winner:
		background.visible = true
	else:
		background.visible = false
