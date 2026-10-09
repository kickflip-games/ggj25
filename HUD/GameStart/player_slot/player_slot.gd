extends PanelContainer
signal enable_requested
signal disable_requested
signal binding_requested
signal cpu_requested
signal human_requested
var _pulse: Tween

func _ready():
	$Content/Enable.pressed.connect(func(): enable_requested.emit())
	$Content/Actions/Binding.pressed.connect(func():
		if $Content/Mode.text == "CPU":
			human_requested.emit()
		else:
			binding_requested.emit())
	$Content/Cpu.pressed.connect(func(): cpu_requested.emit())
	$Content/Actions/Off.pressed.connect(func(): disable_requested.emit())

func display(slot_id: int, active: bool, caption: String, is_cpu: bool = false):
	var color = Globals.PLAYER_COLORS[slot_id]
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(1, 1, 1, 0.72 if active else 0.5)
	panel.border_color = color.darkened(0.12)
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(12)
	panel.content_margin_left = 20
	panel.content_margin_right = 20
	panel.content_margin_top = 16
	panel.content_margin_bottom = 16
	add_theme_stylebox_override("panel", panel)
	$Content/Name.text = "P%d" % (slot_id + 1)
	$Content/Name.modulate = color if active else Color(0.7, 0.7, 0.7)
	$Content/Preview/Body.self_modulate = color if active else Color(0.55, 0.55, 0.55, 0.55)
	$Content/Preview/Body/Face.modulate = Color.WHITE if active else Color(0.55, 0.55, 0.55, 0.55)
	$Content/Mode.text = ("CPU" if is_cpu else "HUMAN") if active else "OFF"
	$Content/Mode.modulate = color if active else Color(0.7, 0.7, 0.7)
	$Content/Enable.visible = not active
	$Content/Actions.visible = active
	$Content/Actions/Binding.text = "Switch to Human" if is_cpu else caption
	$Content/Cpu.visible = not is_cpu

func celebrate():
	if _pulse:
		_pulse.kill()
	var preview = $Content/Preview/Body
	preview.pivot_offset = preview.size / 2
	_pulse = create_tween()
	_pulse.tween_property(preview, "scale", Vector2(1.08, 1.08), 0.1)
	_pulse.tween_property(preview, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
