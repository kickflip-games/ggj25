extends Node2D

var shader_mat:Material 
const  C1:Color= Color(0.122, 0.122, 0.122, 1.0)
const  C2:Color = Color(0.09, 0.09, 0.09, 1.0)
const   SPEED:float = 3.0
const   LINES:int = 20

func _ready():
	var mat = $ColorRect.material
	if mat is ShaderMaterial:
		shader_mat = mat
	else:
		push_error("Material is not a ShaderMaterial!")
	reset()
	
	


func reset():
	_set_shader(SPEED, LINES, C1, C2)
	
func set_color(c:Color):
	print("Set background color based on player")
	var c1 = c.darkened(0.8)  # 80% darker
	var c2 = c.darkened(0.6)  # 50% darker
	_set_shader(SPEED*2, LINES*2, c1, c2)

func _set_shader(_speed:float, _lines:int, _c1:Color, _c2:Color):
	shader_mat.set_shader_parameter("speed", _speed)
	shader_mat.set_shader_parameter("line_count", float(_lines))  # cast to float
	shader_mat.set_shader_parameter("color_one", _c1)
	shader_mat.set_shader_parameter("color_two", _c2)
