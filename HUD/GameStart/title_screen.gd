extends Control
signal play_requested

func _on_play_pressed():
	play_requested.emit()
