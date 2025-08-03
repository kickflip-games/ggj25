extends Node2D

var _tween:Tween
@onready var active_arrow:=$ActiveArrow


	
func _start_tween(arrow:Sprite2D) -> void:
	var new_rotation = arrow.rotation_degrees
	var current_rotation = active_arrow.rotation_degrees
	# Find the shortest path for rotation
	var delta_rotation = wrapf(new_rotation - current_rotation, -180, 180)
	var final_rotation = current_rotation + delta_rotation
	# Tween to the final rotation
	
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(active_arrow, "rotation_degrees", final_rotation, 0.1)

func show_arrow(dir:int):
	$ActiveArrow.modulate.a = 0.3
	$Right.modulate.a = 0
	$Left.modulate.a = 0
	$Up.modulate.a =0
	$Down.modulate.a = 0
	if dir==0:
		_start_tween($Right)
	elif dir==1:
		_start_tween($Down)
	elif dir==2:
		_start_tween($Left)
	elif dir==3:
		_start_tween($Up)
