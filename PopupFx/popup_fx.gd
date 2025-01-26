extends Node


func display_popup(msg:String, position:Vector2, color:Color=Color.WHITE):
	var label = Label.new()
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
