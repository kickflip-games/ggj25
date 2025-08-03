class_name PlayerUi
extends VBoxContainer

@onready var _bar:ProgressBar = $PowerupBar
@onready var _scoreLbl:Label = $PanelContainer/ScoreLabel
@onready var _playerLbl:Label = $PanelContainer/PlayerLabel
@onready var hearts:Array[TextureRect] = [ # 3 rects with the heart texture
	$HealthLabel/ColorRect,
	$HealthLabel/ColorRect2,
	$HealthLabel/ColorRect3
]
@onready var _sparks:Array[CPUParticles2D] = [
	$PowerupBar/ColorRect/Sparks,
]
@onready var _playerButtonLabel = $PlayerButton

var _col: Color
var _current_score: int = 0
var _player_id: int = -1  # Store the player ID

func write_resapwning():
	$Label.modulate = _col
	$Label.text = "Respawning..."
	# Add a gentle pulse to respawning text
	var tween = create_tween().set_loops()
	tween.tween_property($Label, "modulate:a", 0.5, 1.0)
	tween.tween_property($Label, "modulate:a", 1.0, 1.0)
	
func write_bash_mode():
	$Label.modulate = _col
	$Label.text = "STAR POWER"
	# Make BASH MODE feel energetic
	var tween = create_tween()
	tween.parallel().tween_property($Label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property($Label, "rotation", deg_to_rad(2), 0.1)
	tween.tween_interval(0.1)
	tween.parallel().tween_property($Label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property($Label, "rotation", 0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func reset(player_id: int):
	_player_id = player_id  # Store the player ID
	_col = Globals.PLAYER_COLORS[player_id]
	update_score(0)
	update_health(Globals.MAX_HP)
	reset_bar()
	_playerLbl.text = "P" + str(player_id + 1)
	set_colors()
	write_bash_mode()
	update_player_button_display()  # Update the button display
	print("player colors reset")

func update_player_button_display():
	if _player_id == -1:
		_playerButtonLabel.text = ""
		return
	
	var player_action_name = "player" + str(_player_id)
	
	# Check if this player has a mapped input
	if InputMap.has_action(player_action_name):
		var events = InputMap.action_get_events(player_action_name)
		if events.size() > 0:
			var input_text = get_input_description(events[0])
			_playerButtonLabel.text = input_text
			_playerButtonLabel.modulate = _col
		else:
			_playerButtonLabel.text = "No Input"
			_playerButtonLabel.modulate = Color.GRAY
	else:
		_playerButtonLabel.text = "Not Mapped"
		_playerButtonLabel.modulate = Color.GRAY

func get_input_description(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_string = OS.get_keycode_string(event.keycode)
		# You can customize the display format here
		match key_string:
			"Space":
				return "SPACE"
			"Enter":
				return "ENTER"
			"Shift":
				return "SHIFT"
			"Control":
				return "CTRL"
			_:
				return key_string.to_upper()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LEFT CLICK"
			MOUSE_BUTTON_RIGHT:
				return "RIGHT CLICK"
			MOUSE_BUTTON_MIDDLE:
				return "MIDDLE CLICK"
			MOUSE_BUTTON_WHEEL_UP:
				return "WHEEL UP"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "WHEEL DOWN"
			_:
				return "MOUSE " + str(event.button_index)
	elif event is InputEventScreenTouch:
		return "TOUCH " + str(event.index)
	else:
		return "UNKNOWN"

# Call this if you want to refresh the button display (e.g., if controls change mid-game)
func refresh_button_display():
	update_player_button_display()

func set_colors():
	_playerLbl.modulate = _col
	_scoreLbl.modulate = _col
	$Label.modulate = _col
	update_health(Globals.MAX_HP)
	var sb = StyleBoxFlat.new()
	sb.bg_color = _col
	_bar.add_theme_stylebox_override("fill", sb)
	for fx in _sparks:
		fx.color = _col
	# Update button label color too
	if _playerButtonLabel:
		_playerButtonLabel.modulate = _col
	#_set_flame_col()

func update_score(score: int):
	var old_score = _current_score
	_current_score = score
	
	# Animate the score change with a counting effect
	var tween = create_tween()
	tween.parallel().tween_method(_animate_score_count, old_score, score, 0.5).set_ease(Tween.EASE_OUT)
	
	# Scale pop effect
	tween.parallel().tween_property(_scoreLbl, "scale", Vector2(1.3, 1.3), 0.1)
	tween.parallel().tween_property(_scoreLbl, "modulate", Color.WHITE, 0.1)
	
	tween.tween_interval(0.1)	
	tween.parallel().tween_property(_scoreLbl, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(_scoreLbl, "modulate", _col, 0.4)

func _animate_score_count(value: int):
	_scoreLbl.text = str(value).pad_zeros(4)


func update_health(health: int):
	print("HEALTH update ", health)
	# Color the first "health" hearts by color, others are set to black
	for i in range(hearts.size()):
		var heart = hearts[i]
		if i < health:
			# Check if heart was previously black/transparent
			var was_black = heart.modulate.is_equal_approx(Color.BLACK) or heart.modulate.a < 0.1
			heart.modulate = _col
			
			# Heart pop animation when gaining health
			if was_black:
				var tween = create_tween()
				tween.tween_property(heart, "scale", Vector2(1.4, 1.4), 0.15).set_ease(Tween.EASE_OUT)
				tween.tween_property(heart, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		else:
			# Animate hearts losing health with a shrink effect
			var was_colored = !heart.modulate.is_equal_approx(Color.BLACK) and heart.modulate.a > 0.1
			if was_colored:
				var tween = create_tween()
				tween.parallel().tween_property(heart, "scale", Vector2(0.8, 0.8), 0.1)
				tween.parallel().tween_property(heart, "modulate", Color.BLACK, 0.1)
				tween.tween_property(heart, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			else:
				heart.modulate = Color.BLACK

func reset_bar():
	_bar.max_value = Globals.POWERUP_THRESHOLD
	_bar.value = 0

func update_bar(value):
	var old_value = _bar.value
	
	# Smooth bar fill animation
	var tween = create_tween()
	tween.tween_property(_bar, "value", value, 0.3).set_ease(Tween.EASE_OUT)
	
	# Check if bar is getting full (90%+ of max)
	if value >= _bar.max_value * 0.9 and value < _bar.max_value:
		# Subtle glow pulse for near-full bar
		tween.parallel().tween_property(_bar, "modulate", Color(1.2, 1.2, 1.2), 0.2)
		tween.parallel().tween_property(_bar, "modulate", Color(1.0, 1.0, 1.0), 0.2)
	
	# If bar is completely full, make it dramatic and start pulsing!
	if value >= _bar.max_value:
		_play_full_bar_effect()
		_start_full_bar_pulse()
	else:
		# Stop pulsing if bar is no longer full
		_stop_full_bar_pulse()

func _play_full_bar_effect(drama_level := 3.0):
	# Clamp drama level to sane range
	drama_level = clamp(drama_level, 0.0, 3.0)
	
	var tween = create_tween()
	var flashes = int(3 + 3 * drama_level)
	var shake_count = int(5 + 5 * drama_level)
	var shake_magnitude = 5.0 * drama_level
	var rotation_magnitude = 3.0 * drama_level
	var scale_peak = 1.0 + 0.3 * drama_level
	var flash_intensity = 1.5 + drama_level
	
	var original_pos = _bar.position
	var original_rot = _bar.rotation_degrees
	
	# Flash effect
	for i in range(flashes):
		tween.tween_property(_bar, "modulate", Color(flash_intensity, flash_intensity, flash_intensity), 0.04)
		tween.tween_property(_bar, "modulate", _col, 0.04)

	# Shake (position + rotation)
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-shake_magnitude, shake_magnitude),
			randf_range(-shake_magnitude, shake_magnitude)
		)
		var rot_offset = randf_range(-rotation_magnitude, rotation_magnitude)
		tween.parallel().tween_property(_bar, "position", original_pos + shake_offset, 0.03)
		tween.parallel().tween_property(_bar, "rotation_degrees", original_rot + rot_offset, 0.03)

	# Snap back to original
	tween.tween_property(_bar, "position", original_pos, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(_bar, "rotation_degrees", original_rot, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Scale pop
	tween.parallel().tween_property(_bar, "scale", Vector2(scale_peak, scale_peak), 0.1)
	tween.tween_property(_bar, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)



func play_hp_fx():
	# Screen shake effect for damage
	var original_pos = position
	var tween = create_tween()
	
	# Quick shake
	for i in range(6):
		var shake_offset = Vector2(randf_range(-5, 5), randf_range(-3, 3))
		tween.tween_property(self, "position", original_pos + shake_offset, 0.03)
	
	# Return to position
	tween.tween_property(self, "position", original_pos, 0.1).set_ease(Tween.EASE_OUT)
	
	# Red flash overlay
	tween.parallel().tween_property(self, "modulate", Color(1.5, 0.5, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func play_powerup_mode_fx():
	# Epic powerup activation effect
	var tween = create_tween()
	
	# Grow and glow
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1.3, 1.3, 1.3), 0.3)
	
	# Pulsing glow effect during powerup mode
	tween.tween_callback(_start_powerup_pulse)
	
	# Return to normal after powerup
	await get_tree().create_timer(5.0).timeout  # Adjust timing as needed
	_stop_powerup_pulse()

var _powerup_pulse_tween: Tween
var _full_bar_pulse_tween: Tween

func _start_powerup_pulse():
	_powerup_pulse_tween = create_tween().set_loops()
	_powerup_pulse_tween.tween_property(self, "modulate", Color(1.4, 1.4, 1.4), 0.5)
	_powerup_pulse_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1), 0.5)

func _stop_powerup_pulse():
	if _powerup_pulse_tween:
		_powerup_pulse_tween.kill()
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.3)

func _start_full_bar_pulse():
	# Stop any existing full bar pulse
	if _full_bar_pulse_tween:
		_full_bar_pulse_tween.kill()
	
	# Create an intense pulsing effect for the full bar with shake
	_full_bar_pulse_tween = create_tween().set_loops()
	var original_pos = _bar.position
	
	# Pulse color and add subtle shake
	_full_bar_pulse_tween.tween_callback(func(): _shake_bar_during_pulse(original_pos))
	_full_bar_pulse_tween.tween_property(_bar, "modulate", Color(2.0, 2.0, 2.0), 0.4)
	_full_bar_pulse_tween.tween_callback(func(): _shake_bar_during_pulse(original_pos))
	_full_bar_pulse_tween.tween_property(_bar, "modulate", _col, 0.4)

func _shake_bar_during_pulse(original_pos: Vector2):
	# Small shake during each pulse
	var shake_tween = create_tween()
	var shake_offset = Vector2(randf_range(-2, 2), randf_range(-1, 1))
	shake_tween.tween_property(_bar, "position", original_pos + shake_offset, 0.05)
	shake_tween.tween_property(_bar, "position", original_pos, 0.05)

func _stop_full_bar_pulse():
	if _full_bar_pulse_tween:
		_full_bar_pulse_tween.kill()
	
	# Return bar to normal color
	var tween = create_tween()
	tween.tween_property(_bar, "modulate", Color.WHITE, 0.2)
