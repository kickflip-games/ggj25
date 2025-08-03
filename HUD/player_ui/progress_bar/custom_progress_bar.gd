@tool
extends Control
class_name CustomProgressBar

# Node references
@onready var progress_bar: TextureRect = $progress_bar
@onready var bar_fill: TextureRect = $progress_bar/barFill
@onready var sparks: GPUParticles2D = $progress_bar/barFill/Sparks
@onready var sparks2: GPUParticles2D = $progress_bar/barFill/Sparks2
@onready var flame: Sprite2D = $progress_bar/barFill/Flame
@onready var flame2: Sprite2D = $progress_bar/barFill/Flame2
@onready var flame3: Sprite2D = $progress_bar/barFill/Flame3
# Exported properties for editor customization
@export_group("Bar Fill Settings")
@export var bar_fill_color: Color = Color.WHITE: set = set_bar_fill_color

@export_group("Flame and Sparks Colors")
@export var flame_color: Color = Color.WHITE: set = set_flame_color
@export var sparks_color: Color = Color.WHITE: set = set_sparks_color

@export_group("Animation Thresholds")
@export var sparks_threshold: float = 0.5  # Start sparks at 50%
@export var flames_threshold: float = 0.9  # Start flames at 90%

@export_group("Progress Settings")
@export var max_value: float = 100.0: set = set_max_value
@export var current_value: float = 0.0: set = set_current_value

@export_group("Debug Settings")
@export var debugging: bool = false
@export var debug_step_size: float = 5.0

# Internal variables
var _original_bar_fill_size: Vector2
var _original_position: Vector2
var _original_rotation: float
var _powerup_pulse_tween: Tween
var _full_bar_pulse_tween: Tween
var max_x: float = 100.0  # Set from bar_fill initial position
var min_x: float = 0.0    # Always 0

func _ready():
	if not Engine.is_editor_hint():
		_initialize_progress_bar()
		_setup_debug_tools()
		
	set_bar_fill_color(bar_fill_color)
	set_sparks_color(sparks_color)
	set_flame_color(flame_color)

func _setup_debug_tools():
	if debugging:
		print("CustomProgressBar: Debug mode enabled")
		print("Use UI_UP/UI_DOWN to change bar value (step size: ", debug_step_size, ")")

func _input(event):
	if not debugging or Engine.is_editor_hint():
		return
	
	if event.is_action_pressed("ui_up"):
		var new_progress = current_value + debug_step_size
		update_bar(new_progress)
		print("Debug: Bar progress increased to ", new_progress, "/", max_value, " (", (new_progress/max_value)*100, "%)")
	elif event.is_action_pressed("ui_down"):
		var new_progress = current_value - debug_step_size
		update_bar(new_progress)
		print("Debug: Bar progress decreased to ", new_progress, "/", max_value, " (", (new_progress/max_value)*100, "%)")

func _initialize_progress_bar():
	if bar_fill:
		_original_bar_fill_size = bar_fill.size
		_original_position = position
		_original_rotation = rotation_degrees
		
		# Set max_x from the initial bar_fill size (assumes it's set at full position)
		max_x = bar_fill.size.x
		min_x = 0.0
		
		print("CustomProgressBar initialized - max_x: ", max_x, ", min_x: ", min_x)
	
	# Initialize effects as disabled
	_disable_sparks()
	_disable_flames()
	
	_update_bar_fill_visual()

# Setter functions for exported properties
func set_bar_fill_color(color: Color):
	bar_fill_color = color
	if bar_fill:
		bar_fill.self_modulate = color

func set_flame_color(color: Color):
	flame_color = color
	_update_flame_colors()

func set_sparks_color(color: Color):
	sparks_color = color
	_update_sparks_colors()

func set_max_value(value: float):
	max_value = value
	_update_bar_fill_visual()

func set_current_value(value: float):
	current_value = clamp(value, 0.0, max_value)
	_update_bar_fill_visual()
	_update_effects_based_on_value()

# Update visual elements
func _update_bar_fill_visual():
	if not bar_fill or max_x <= 0:
		return
	
	# Calculate fill percentage (0-1)
	var fill_percentage = current_value / max_value if max_value > 0 else 0.0
	
	# Calculate the actual width based on min_x and max_x
	var usable_width = max_x - min_x
	var fill_width = usable_width * fill_percentage
	
	# Update bar fill size and position
	bar_fill.size.x = fill_width
	bar_fill.position.x = min_x

func _update_effects_based_on_value():
	var fill_percentage = get_fill_percentage()
	
	# Handle sparks at threshold
	if fill_percentage >= sparks_threshold:
		_enable_sparks()
	else:
		_disable_sparks()
	
	# Handle flames at threshold
	if fill_percentage >= flames_threshold:
		_enable_flames()
	else:
		_disable_flames()

func _enable_sparks():
	if sparks:
		sparks.emitting = true
	if sparks2:
		sparks2.emitting = true

func _disable_sparks():
	if sparks:
		sparks.emitting = false
	if sparks2:
		sparks2.emitting = false

func _enable_flames():
	if flame:
		flame.visible = true
	if flame2:
		flame2.visible = true
	if flame3:
		flame3.visible = true

func _disable_flames():
	if flame:
		flame.visible = false
	if flame2:
		flame2.visible = false
	if flame3:
		flame3.visible = false

func _update_flame_colors():
	if flame_color == Color.TRANSPARENT:
		return
	
	# Update flame shader material parameter 'flame_gradient'
	_update_flame_shader_color(flame)
	_update_flame_shader_color(flame2)
	_update_flame_shader_color(flame3)

func _update_flame_shader_color(flame_sprite: Sprite2D):
	if not flame_sprite or not flame_sprite.material:
		return
	
	var material = flame_sprite.material as ShaderMaterial
	material.set_shader_parameter("flame_gradient", flame_color)

func _update_sparks_colors():
	if sparks_color == Color.TRANSPARENT:
		return
	
	# Update particle color curves
	_update_particle_color_curve(sparks)
	_update_particle_color_curve(sparks2)

func _update_particle_color_curve(particle_system: GPUParticles2D):
	if not particle_system or not particle_system.process_material:
		return
	
	var material = particle_system.process_material as ParticleProcessMaterial
	if material:
		# Create a new gradient with the sparks_color
		var gradient = Gradient.new()
		gradient.add_point(0.0, sparks_color)
		gradient.add_point(1.0, Color(sparks_color.r, sparks_color.g, sparks_color.b, 0.0))  # Fade to transparent
		
		material.color_ramp = gradient

# Public API functions
func reset_bar():
	current_value = 0
	_update_bar_fill_visual()
	_update_effects_based_on_value()
	_stop_all_effects()

func update_bar(powerup_progress: float):
	# Convert powerup_progress to percentage (0-100)
	var target_percentage = (powerup_progress / max_value) * 100.0
	target_percentage = clamp(target_percentage, 0.0, 100.0)
	
	var old_percentage = (current_value / max_value) * 100.0
	
	# Smooth bar fill animation
	var tween = create_tween()
	tween.tween_method(_animate_bar_percentage, old_percentage, target_percentage, 0.3).set_ease(Tween.EASE_OUT)
	
	# Check if bar is getting full (90%+ of max)
	if target_percentage >= 90.0 and target_percentage < 100.0:
		# Subtle glow pulse for near-full bar
		tween.parallel().tween_property(self, "modulate", Color(1.2, 1.2, 1.2), 0.2)
		tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.2)
	
	# If bar is completely full, make it dramatic and start pulsing!
	if target_percentage >= 100.0:
		tween.tween_callback(_play_full_bar_effect)
		tween.tween_callback(_start_full_bar_pulse)
	else:
		# Stop pulsing if bar is no longer full
		tween.tween_callback(_stop_full_bar_pulse)

func _animate_bar_percentage(percentage: float):
	# Convert percentage back to current_value for internal calculations
	current_value = (percentage / 100.0) * max_value
	_update_bar_fill_visual()
	_update_effects_based_on_value()

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
	
	# Flash effect
	for i in range(flashes):
		tween.tween_property(self, "modulate", Color(flash_intensity, flash_intensity, flash_intensity), 0.04)
		tween.tween_property(self, "modulate", bar_fill_color, 0.04)

	# Shake (position + rotation)
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-shake_magnitude, shake_magnitude),
			randf_range(-shake_magnitude, shake_magnitude)
		)
		var rot_offset = randf_range(-rotation_magnitude, rotation_magnitude)
		tween.parallel().tween_property(self, "position", _original_position + shake_offset, 0.03)
		tween.parallel().tween_property(self, "rotation_degrees", _original_rotation + rot_offset, 0.03)

	# Snap back to original
	tween.tween_property(self, "position", _original_position, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(self, "rotation_degrees", _original_rotation, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Scale pop
	tween.parallel().tween_property(self, "scale", Vector2(scale_peak, scale_peak), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

func _start_powerup_pulse():
	_stop_powerup_pulse()
	_powerup_pulse_tween = create_tween().set_loops()
	_powerup_pulse_tween.tween_property(self, "modulate", Color(1.4, 1.4, 1.4), 0.5)
	_powerup_pulse_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1), 0.5)

func _stop_powerup_pulse():
	if _powerup_pulse_tween:
		_powerup_pulse_tween.kill()
		_powerup_pulse_tween = null
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.3)

func _start_full_bar_pulse():
	# Stop any existing full bar pulse
	_stop_full_bar_pulse()
	
	# Create an intense pulsing effect for the full bar with shake
	_full_bar_pulse_tween = create_tween().set_loops()
	
	# Pulse color and add subtle shake
	_full_bar_pulse_tween.tween_callback(_shake_bar_during_pulse)
	_full_bar_pulse_tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 0.4)
	_full_bar_pulse_tween.tween_callback(_shake_bar_during_pulse)
	_full_bar_pulse_tween.tween_property(self, "modulate", bar_fill_color, 0.4)

func _shake_bar_during_pulse():
	# Small shake during each pulse
	var shake_tween = create_tween()
	var shake_offset = Vector2(randf_range(-2, 2), randf_range(-1, 1))
	shake_tween.tween_property(self, "position", _original_position + shake_offset, 0.05)
	shake_tween.tween_property(self, "position", _original_position, 0.05)

func _stop_full_bar_pulse():
	if _full_bar_pulse_tween:
		_full_bar_pulse_tween.kill()
		_full_bar_pulse_tween = null
	
	# Return bar to normal color
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _stop_all_effects():
	_stop_powerup_pulse()
	_stop_full_bar_pulse()

# Utility functions
func get_fill_percentage() -> float:
	return current_value / max_value if max_value > 0 else 0.0

func is_full() -> bool:
	return current_value >= max_value

func is_nearly_full(threshold: float = 0.9) -> bool:
	return current_value >= max_value * threshold

# Additional animation functions
func pulse_bar(intensity: float = 1.2, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(intensity, intensity, intensity), duration * 0.5)
	tween.tween_property(self, "modulate", Color.WHITE, duration * 0.5)

func flash_bar(color: Color = Color.WHITE, duration: float = 0.1, count: int = 3):
	var tween = create_tween()
	for i in range(count):
		tween.tween_property(self, "modulate", color, duration * 0.5)
		tween.tween_property(self, "modulate", Color.WHITE, duration * 0.5)

# Additional debugging functions
func debug_set_random_value():
	if debugging:
		var random_progress = randf() * max_value
		update_bar(random_progress)
		print("Debug: Set random progress ", random_progress)

func debug_fill_to_percentage(percentage: float):
	if debugging:
		var target_progress = max_value * clamp(percentage, 0.0, 1.0)
		update_bar(target_progress)
		print("Debug: Set to ", percentage * 100, "% (progress: ", target_progress, ")")

func debug_info():
	if debugging:
		print("=== CustomProgressBar Debug Info ===")
		print("Current Value: ", current_value)
		print("Max Value: ", max_value)
		print("Fill Percentage: ", get_fill_percentage() * 100, "%")
		print("Min X: ", min_x)
		print("Max X: ", max_x)
		print("Bar Fill Color: ", bar_fill_color)
		print("Flame Color: ", flame_color)
		print("Sparks Color: ", sparks_color)
		print("Sparks Threshold: ", sparks_threshold * 100, "%")
		print("Flames Threshold: ", flames_threshold * 100, "%")
		print("Sparks Active: ", sparks.emitting if sparks else "N/A")
		print("Flames Visible: ", flame.visible if flame else "N/A")
		print("Is Full: ", is_full())
		print("Is Nearly Full: ", is_nearly_full())
		print("=====================================")

# Quick debug shortcuts (call these from other scripts during development)
func _unhandled_key_input(event):
	if not debugging or Engine.is_editor_hint():
		return
	
	if event.pressed:
		match event.keycode:
			KEY_R:
				debug_set_random_value()
			KEY_1:
				debug_fill_to_percentage(0.1)
			KEY_2:
				debug_fill_to_percentage(0.25)
			KEY_5:
				debug_fill_to_percentage(0.5)
			KEY_9:
				debug_fill_to_percentage(0.9)
			KEY_0:
				debug_fill_to_percentage(1.0)
			KEY_I:
				debug_info()
			KEY_X:
				reset_bar()
				print("Debug: Bar reset")
			KEY_M:
				# Quick test of setting max_value
				max_value = 200.0
				print("Debug: Max value changed to ", max_value)
