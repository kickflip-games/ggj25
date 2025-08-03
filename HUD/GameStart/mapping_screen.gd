# mapping screen
extends Control
signal keys_mapped
var curr_player: int
@onready var player_text:= $PlayerText
@onready var use_warning:= $AlreadyInUse
var num_players = 1
var used_inputs = []
var accept_mouse_input = false  # Start as false
var is_mapping_active = false  # Track if mapping is currently active

func _ready() -> void:
	# Don't start mapping immediately
	reset_mapping_state()

# Call this when the mapping screen becomes active
func start_mapping():
	reset_mapping_state()
	is_mapping_active = true
	# Small delay to prevent immediate clicks from the UI transition
	await get_tree().create_timer(0.3).timeout
	accept_mouse_input = true
	print("Mapping started for", num_players, "players")

func reset_mapping_state():
	curr_player = 1
	used_inputs.clear()
	use_warning.modulate.a = 0.0
	accept_mouse_input = false
	is_mapping_active = false
	update_player_label()

func _input(event):
	# Only process input if mapping is active and this screen is visible
	if not is_mapping_active or not visible:
		return
		
	var input_identifier = null
	var valid_input = false
	
	# Handle keyboard input (always accepted when mapping is active)
	if event is InputEventKey and event.pressed:
		input_identifier = "key_" + str(event.keycode)
		valid_input = true
	
	# Handle mouse button input - only if flag is set and not clicking UI
	elif event is InputEventMouseButton and event.pressed and accept_mouse_input:
		if not _is_clicking_ui(event.position):
			input_identifier = "mouse_" + str(event.button_index)
			valid_input = true
	
	# Handle touch input - only if flag is set and not touching UI
	elif event is InputEventScreenTouch and event.pressed and accept_mouse_input:
		if not _is_clicking_ui(event.position):
			input_identifier = "touch_" + str(event.index)
			valid_input = true
	
	if valid_input and curr_player <= num_players:
		if input_identifier in used_inputs:
			print("Input already used:", input_identifier)
			show_warning()
		else:
			use_warning.modulate.a = 0.0
			
			# Map the input BEFORE incrementing player
			remap_input("player" + str(curr_player - 1), event)
			used_inputs.append(input_identifier)
			
			curr_player += 1
			
			# Briefly disable mouse input after successful mapping
			if event is InputEventMouseButton or event is InputEventScreenTouch:
				accept_mouse_input = false
				await get_tree().create_timer(0.2).timeout
				if is_mapping_active:  # Check if still mapping
					accept_mouse_input = true
			
			if curr_player > num_players:
				is_mapping_active = false
				keys_mapped.emit()
			else:
				update_player_label()

# Enhanced UI click detection
func _is_clicking_ui(position: Vector2) -> bool:
	# Check if clicking on this control or any of its children
	var local_pos = global_position
	var control_rect = Rect2(local_pos, size)
	
	# If clicking anywhere on the mapping screen's UI area, consider it a UI click
	# You might want to adjust this based on your specific layout
	if control_rect.has_point(position):
		# Check if there's actual UI content at this position
		var controls_to_check = [player_text, use_warning]
		for control in controls_to_check:
			if control.visible and control.get_global_rect().has_point(position):
				return true
	
	return false

func show_warning():
	var tween = create_tween()
	tween.tween_property(use_warning, "modulate:a", 1.0, 0.1)
	# Auto-hide warning after a moment
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		var fade_tween = create_tween()
		fade_tween.tween_property(use_warning, "modulate:a", 0.0, 0.3)

func remap_input(player_id: String, event: InputEvent):
	print("Mapping input for", player_id, "- Event:", event)
	print("Before remapping ", player_id, InputMap.action_get_events(player_id))
	InputMap.action_erase_events(player_id)
	InputMap.action_add_event(player_id, event) 
	print("After remapping ", player_id, InputMap.action_get_events(player_id))

func update_player_label():
	if curr_player <= num_players:
		player_text.text = "Player %d" % curr_player
	else:
		player_text.text = "Mapping complete!"

# Optional: Helper function to get a human-readable description of the input
func get_input_description(event: InputEvent) -> String:
	if event is InputEventKey:
		return "Key: " + OS.get_keycode_string(event.keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Left Mouse Button"
			MOUSE_BUTTON_RIGHT:
				return "Right Mouse Button"
			MOUSE_BUTTON_MIDDLE:
				return "Middle Mouse Button"
			MOUSE_BUTTON_WHEEL_UP:
				return "Mouse Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Mouse Wheel Down"
			_:
				return "Mouse Button " + str(event.button_index)
	elif event is InputEventScreenTouch:
		return "Touch " + str(event.index)
	else:
		return "Unknown Input"

# Override visibility change to manage state
func _on_visibility_changed():
	if not visible:
		is_mapping_active = false
		accept_mouse_input = false
