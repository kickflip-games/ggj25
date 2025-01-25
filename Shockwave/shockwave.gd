class_name Shockwave
extends CanvasLayer

var shader_mat:Material

func _ready():
	shader_mat = $ColorRect.material


func create_shock():
	create_tween().tween_method(set_shader_value, 0.0, 1.0, 2)

func set_shader_value(value: float):
	shader_mat.set_shader_parameter("radius", value);
