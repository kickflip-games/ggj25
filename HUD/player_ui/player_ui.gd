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
@onready var _playerButtonLabel = $PanelContainer/PlayerButton
@onready var _statusLabel: Label = $HealthLabel/Label

const EMPTY_HEART_COLOR := Color(0.65, 0.68, 0.75, 0.45)

var _score_tween: Tween
var _bar_tween: Tween
var _status_tween: Tween
var _heart_tweens: Dictionary = {}

var _col: Color
var _current_score: int = 0
var _player_id: int = -1  # Store the player ID

func write_resapwning():
	_statusLabel.modulate = _col
	_statusLabel.text = "Respawning..."
	# Add a gentle pulse to respawning text
	if _status_tween:
		_status_tween.kill()
	var tween = create_tween().set_loops()
	_status_tween = tween
	tween.tween_property(_statusLabel, "modulate:a", 0.5, 1.0)
	tween.tween_property(_statusLabel, "modulate:a", 1.0, 1.0)
	
func write_bash_mode():
	_statusLabel.modulate = _col
	_statusLabel.text = "Star Power"
	if _status_tween:
		_status_tween.kill()
	_statusLabel.scale = Vector2.ONE
	_statusLabel.rotation = 0.0
	_stop_full_bar_pulse()

var _is_cpu: bool = false

func reset(player_id: int, is_cpu: bool = false):
	_is_cpu = is_cpu
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
	if _is_cpu:
		_playerButtonLabel.text = "CPU"
		_playerButtonLabel.modulate = _col
		return
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
		var key_string = OS.get_keycode_string(event.keycode if event.keycode != 0 else event.physical_keycode)
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
	_statusLabel.modulate = _col
	update_health(Globals.MAX_HP)
	var sb = StyleBoxFlat.new()
	sb.bg_color = _col
	sb.set_corner_radius_all(5)
	_bar.add_theme_stylebox_override("fill", sb)
	for fx in _sparks:
		fx.color = _col
	# Update button label color too
	if _playerButtonLabel:
		_playerButtonLabel.modulate = _col
	#_set_flame_col()

func update_score(score: int):
	var old_score = int(_scoreLbl.text)
	if _score_tween:
		_score_tween.kill()
	_current_score = score
	
	# Animate from the currently displayed value, cancelling the previous count.
	var tween = create_tween()
	_score_tween = tween
	tween.parallel().tween_method(_animate_score_count, old_score, score, 0.5).set_ease(Tween.EASE_OUT)

func _animate_score_count(value: int):
	_scoreLbl.text = str(value).pad_zeros(4)


func update_health(health: int):
	print("HEALTH update ", health)
	# Keep the original artwork; dim empty hearts instead of filling them black.
	for i in range(hearts.size()):
		var heart = hearts[i]
		if _heart_tweens.has(i):
			_heart_tweens[i].kill()
		heart.scale = Vector2.ONE
		if i < health:
			# Animate only hearts gaining health.
			var was_empty = heart.modulate.is_equal_approx(EMPTY_HEART_COLOR) or heart.modulate.a < 0.5
			heart.modulate = _col
			
			# Heart pop animation when gaining health
			if was_empty:
				var tween = create_tween()
				_heart_tweens[i] = tween
				tween.tween_property(heart, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT)
				tween.tween_property(heart, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		else:
			# Animate hearts losing health with a shrink effect
			var was_colored = !heart.modulate.is_equal_approx(EMPTY_HEART_COLOR) and heart.modulate.a >= 0.5
			if was_colored:
				var tween = create_tween()
				_heart_tweens[i] = tween
				tween.parallel().tween_property(heart, "scale", Vector2(0.8, 0.8), 0.1)
				tween.parallel().tween_property(heart, "modulate", EMPTY_HEART_COLOR, 0.1)
				tween.tween_property(heart, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			else:
				heart.modulate = EMPTY_HEART_COLOR

func reset_bar():
	if _bar_tween:
		_bar_tween.kill()
	_stop_full_bar_pulse()
	_bar.max_value = Globals.POWERUP_THRESHOLD
	_bar.value = 0

func update_bar(value):
	if _bar_tween:
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(_bar, "value", value, 0.2).set_ease(Tween.EASE_OUT)
	if value >= _bar.max_value:
		_start_full_bar_pulse()
	else:
		_stop_full_bar_pulse()

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
	write_bash_mode()
	_statusLabel.text = "Star Power!"
	_start_full_bar_pulse()

var _full_bar_pulse_tween: Tween

func _start_full_bar_pulse():
	if _full_bar_pulse_tween and _full_bar_pulse_tween.is_running():
		return
	_full_bar_pulse_tween = create_tween().set_loops()
	_full_bar_pulse_tween.tween_property(_bar, "modulate", Color(1.04, 1.04, 1.04), 0.5)
	_full_bar_pulse_tween.tween_property(_bar, "modulate", Color.WHITE, 0.5)

func _stop_full_bar_pulse():
	if _full_bar_pulse_tween:
		_full_bar_pulse_tween.kill()
	_bar.modulate = Color.WHITE
