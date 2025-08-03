extends Node2D
@onready var combo_timer := $ComboTimer
const COMBO_COOLDOWN = 2.0
var powerup_progress: int = 0 
var _score: int = 0
var _ui: PlayerUi
var combo_multiplier = 1
var combo_active = false

# Add reference to the player for popup positioning and color
var _player: Player

signal powerup_ready

func reset(ui: PlayerUi, player: Player = null):
	powerup_progress = 0
	_score = 0
	_ui = ui
	_player = player  # Store player reference for popup positioning

func increment(in_powerup_mode: bool = false, additional_factor: int = 1):
	var score_addition = 10 * combo_multiplier * additional_factor
	_score += score_addition
	_ui.update_score(_score)
	combo_timer.start(COMBO_COOLDOWN)  # Reset timer to 2 seconds for each pickup
	
	if combo_active:
		combo_multiplier += 1
		if combo_multiplier > 1:
			# Use popup instead of UI combo effect
			if _player:
				PopupFx.display_combo_popup(
					combo_multiplier, 
					_player.message_point.global_position, 
					_player.player_color
				)
	else:
		combo_multiplier = 1
		combo_active = true
	
	if not in_powerup_mode:
		powerup_progress += 1
		_ui.update_bar(powerup_progress)
		if powerup_progress % Globals.POWERUP_THRESHOLD == 0:
			print("Powerup ready")
			powerup_ready.emit()
			_ui.play_powerup_mode_fx()
	
	return score_addition

func _on_combo_timer_timeout():
	combo_active = false
	combo_multiplier = 1
	print("Combo ended")
	combo_timer.stop()
