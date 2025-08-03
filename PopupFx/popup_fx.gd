extends Node

const CUSTOM_FONT = preload("res://HUD/Sniglet.ttf")

func display_popup(msg: String, position: Vector2, color: Color = Color.WHITE):
	var label = Label.new()
	label.label_settings = LabelSettings.new()
	label.label_settings.font = CUSTOM_FONT
	label.global_position = position
	label.text = msg
	label.z_index = 5 
	label.label_settings = LabelSettings.new()
	
	label.label_settings.font_color = color
	label.label_settings.font_size = 28
	label.label_settings.outline_color = Color.BLACK
	label.label_settings.outline_size = 1
	
	call_deferred("add_child", label)
	
	await label.resized
	
	label.pivot_offset = Vector2(label.size/2)
	
	var foo = 2
	
	var t = get_tree().create_tween().set_parallel()
	t.tween_property(label, "position:y", label.position.y - 24, 0.25*foo).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "position:y", label.position.y, 0.5 *foo).set_ease(Tween.EASE_IN).set_delay(0.25*foo)
	t.tween_property(label, "scale", Vector2.ZERO, 0.25*foo).set_ease(Tween.EASE_IN).set_delay(0.25*foo)
	
	await t.finished
	label.queue_free()

func display_combo_popup(combo_count: int, position: Vector2, color: Color = Color.WHITE):
	"""Display a combo popup with enhanced effects based on combo count"""
	var label = Label.new()
	label.global_position = position
	label.text = "x" + str(combo_count) 
	label.z_index = 10  # Higher z-index for combo messages
	label.label_settings = LabelSettings.new()
	
	# Scale font size based on combo count (bigger combos = bigger text)
	var base_font_size = 32
	var font_size = base_font_size + min(combo_count * 4, 32)  # Cap at reasonable size
	label.label_settings.font_size = font_size
	
	# Enhanced outline for combo text
	label.label_settings.outline_color = Color.BLACK
	label.label_settings.outline_size = 2
	
	call_deferred("add_child", label)
	await label.resized
	label.pivot_offset = Vector2(label.size/2)
	
	var t = get_tree().create_tween().set_parallel()
	
	# Different effects based on combo level
	if combo_count >= 7:
		# Epic combo (10+): Rainbow cycle + dramatic movement
		_create_epic_combo_effect(label, t, position)
	elif combo_count >= 4:
		# Big combo (5-9): Color cycle + big scale
		_create_big_combo_effect(label, t, position, color)
	else:
		# Regular combo (2-4): Simple enhanced popup
		_create_regular_combo_effect(label, t, position, color)
	
	await t.finished
	label.queue_free()

func _create_epic_combo_effect(label: Label, tween: Tween, position: Vector2):
	"""Epic combo effect with rainbow colors and dramatic movement"""
	label.scale = Vector2(2.0, 2.0)
	
	var rainbow_colors = [
		Color.RED, 
		Color(1.0, 0.5, 0.0),  # Orange
		Color.YELLOW, 
		Color.LIME_GREEN,
		Color.CYAN, 
		Color.BLUE, 
		Color.MAGENTA,
		Color.HOT_PINK,
		Color.WHITE
	]
	
	var color_duration = 0.2
	var total_color_time = rainbow_colors.size() * color_duration
	label.modulate = rainbow_colors[0]
	
	# Rotation starts immediately
	tween.parallel().tween_property(label, "rotation", deg_to_rad(360), total_color_time)

	# Color changes – use delays instead of chaining
	for i in range(1, rainbow_colors.size()):
		tween.parallel().tween_property(label, "modulate", rainbow_colors[i], color_duration).set_delay(i * color_duration)

	# Dramatic movement (all parallel)
	tween.parallel().tween_property(label, "position:y", position.y - 60, total_color_time * 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:x", position.x + randf_range(-20, 20), total_color_time * 0.5)

	# Scale animations after color cycle
	tween.parallel().tween_property(label, "scale", Vector2(1.5, 1.5), 0.3).set_delay(total_color_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "scale", Vector2.ZERO, 0.4).set_delay(total_color_time + 0.5).set_ease(Tween.EASE_IN)

func _create_big_combo_effect(label: Label, tween: Tween, position: Vector2, color: Color):
	"""Big combo effect with color transitions and enhanced scale"""
	# Start larger
	label.scale = Vector2(1.5, 1.5)
	
	# Color transitions: base color -> bright white -> base color
	label.modulate = color
	tween.tween_property(label, "modulate", Color.WHITE, 0.15)
	tween.tween_property(label, "modulate", color * 1.5, 0.15)  # Brightened base color
	tween.tween_property(label, "modulate", color, 0.2)
	
	# Enhanced movement
	tween.tween_property(label, "position:y", position.y - 45, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", position.y - 30, 0.4).set_ease(Tween.EASE_IN).set_delay(0.35)
	
	# Scale with elastic bounce
	tween.tween_property(label, "scale", Vector2(1.8, 1.8), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(label, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.5)

func _create_regular_combo_effect(label: Label, tween: Tween, position: Vector2, color: Color):
	"""Regular combo effect with enhanced popup style"""
	# Start with punch scale
	label.scale = Vector2(1.2, 1.2)
	label.modulate = color
	
	# Color flash
	tween.tween_property(label, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(label, "modulate", color, 0.15)
	
	# Enhanced movement
	tween.tween_property(label, "position:y", position.y - 35, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", position.y - 20, 0.4).set_ease(Tween.EASE_IN).set_delay(0.3)
	
	# Scale animation with small bounce
	tween.tween_property(label, "scale", Vector2(1.4, 1.4), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN).set_delay(0.4)

func display_score_popup(score_increase: int, position: Vector2, color: Color = Color.WHITE, is_powerup: bool = false):
	"""Enhanced score popup with different styles for normal vs powerup scoring"""
	var msg = "+" + str(score_increase)
	var label = Label.new()
	label.global_position = position
	label.text = msg
	label.z_index = 8
	label.label_settings = LabelSettings.new()
	
	if is_powerup:
		# Powerup scoring gets special treatment
		label.label_settings.font_size = 36
		label.label_settings.font_color = Color.GOLD
		label.label_settings.outline_color = Color.BLACK
		label.label_settings.outline_size = 3
	else:
		# Regular scoring
		label.label_settings.font_size = 28
		label.label_settings.font_color = color
		label.label_settings.outline_color = Color.BLACK
		label.label_settings.outline_size = 1
	
	call_deferred("add_child", label)
	await label.resized
	label.pivot_offset = Vector2(label.size/2)
	
	var t = get_tree().create_tween().set_parallel()
	
	if is_powerup:
		# Golden glow effect for powerup scores
		t.tween_property(label, "modulate", Color.WHITE, 0.1)
		t.tween_property(label, "modulate", Color.GOLD, 0.2).set_delay(0.1)
		t.tween_property(label, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
		t.tween_property(label, "position:y", label.position.y - 40, 0.4).set_ease(Tween.EASE_OUT)
	else:
		# Regular score animation
		t.tween_property(label, "position:y", label.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	
	# Common fade out
	t.tween_property(label, "position:y", label.position.y, 0.5).set_ease(Tween.EASE_IN).set_delay(0.25)
	t.tween_property(label, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	
	await t.finished
	label.queue_free()
