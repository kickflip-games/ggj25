extends Node2D
@onready var _combo_timer:=$ComboTimer

const COMBO_COOLDOWN = 2.0

var powerup_progress :int = 0 
var _score:int = 0
var _ui:PlayerUi

var _combo_multiplier = 1
var _combo_threshold = 5
var _combo_active = false


signal powerup_ready


func reset(ui:PlayerUi):
	powerup_progress = 0
	_score = 0
	_ui=ui


func increment():
	powerup_progress += 1
	_score += 1* _combo_multiplier
	_ui.update_score(_score)
	_ui.update_bar(powerup_progress)
	_combo_timer.start(COMBO_COOLDOWN)  # Reset timer to 2 seconds for each pickup
	
	
	
	if _combo_active:
			_combo_multiplier += 1
			if _combo_multiplier > 1 :
				_ui.play_combo_fx(_combo_multiplier)
	else:
		_combo_multiplier = 1
		_combo_active = true
	print("Score: %d, Combo Multiplier: %d" % [_score, _combo_multiplier])

	if powerup_progress % Globals.POWERUP_THRESHOLD == 0:
		print("Powerup ready")
		powerup_ready.emit()
		_ui.play_powerup_mode_fx()

func _on_combo_timer_timeout():
	_combo_active = false
	_combo_multiplier = 1
	print("Combo ended")
	_combo_timer.stop()
