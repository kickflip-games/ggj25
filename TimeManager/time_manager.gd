extends Node2D

# Default time scale
const DEFAULT_TIME = 1.0
const LOW_TIME = 0.5
const PAUSE_TIME = 0.001


var tween: Tween 


func _set_timescale(value:float):
	Engine.time_scale = value
	AudioServer.playback_speed_scale =  value


func change_timescale(start:float, end:float, duration:float = 1.0) -> Tween:
	print(">>>> SLOWWW DOWN <<<<<")
	var t = create_tween()
	t.tween_method(_set_timescale, start, end, duration)
	return t


func start_slowmo(duration:float):
	var t = change_timescale(DEFAULT_TIME, LOW_TIME, 0.4)
	t.finish.connect(remove_slowmo)

func remove_slowmo(duration:float = 0.2) -> void:
	print(">>>> REMOVE SLOWMO  <<<<<")
	change_timescale(LOW_TIME, DEFAULT_TIME, 0.2)

func slow_to_pause():
	print(">>>> GO TO PAUSE TIME <<<<")
	change_timescale(DEFAULT_TIME, PAUSE_TIME,  0.2)


func reset():
	print(">>>> RESET TIME <<<<")
	if tween:
		tween.kill()
	_set_timescale(DEFAULT_TIME)
	
