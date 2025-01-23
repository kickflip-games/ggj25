extends Node2D

var _tween:Tween

func _start_tween(arrow:Sprite2D):
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_loops()
	_tween.tween_property(arrow, "modulate:a", 0.5, 0.3)
	_tween.tween_property(arrow, "modulate:a", 0.3, 0.3)

func show_arrow(dir:int):
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
