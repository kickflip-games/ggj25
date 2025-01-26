extends VBoxContainer


@onready var nameLbl:=$Name
@onready var scoreLbl:=$Score

func create(pid:int, score:int):
	var c = Globals.PLAYER_COLORS[pid]
	nameLbl.text = "Player " + str(pid+1)
	scoreLbl.text = str(score).pad_zeros(4)
	nameLbl.add_theme_color_override("font_color", c)
	scoreLbl.add_theme_color_override("font_color", c)
