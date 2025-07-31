extends Node2D

var shader_mat:Material 
const  C1:Color= Color(0.122, 0.122, 0.122, 1.0)
const  C2:Color = Color(0.09, 0.09, 0.09, 1.0)
const   SPEED:float = 3.0
const   LINES:int = 20

func _ready():
	shader_mat = $ColorRect.material
	reset()
	
	


func reset():
	_set_shader(SPEED, LINES, C1, C2)
	
func set_color(c:Color):
	_set_shader(SPEED*2, LINES*2, c, C2)

func _set_shader(_speed:float, _lines:int, _c1:Color, _c2:Color):
	shader_mat.set_shader_parameter("Speed", _speed)
	shader_mat.set_shader_parameter("Line Count", _lines)
	shader_mat.set_shader_parameter("Color 1", _c1)
	shader_mat.set_shader_parameter("Color 2", _c2)
