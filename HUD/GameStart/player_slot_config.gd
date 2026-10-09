extends RefCounted

# CPU controllers share the existing Player scene and need no input binding.
enum PlayerMode { OFF, HUMAN, CPU }
var id: int
var mode: PlayerMode = PlayerMode.OFF
var binding: InputEvent

func _init(slot_id: int):
	id = slot_id

func copy():
	var config = get_script().new(id)
	config.mode = mode
	config.binding = binding.duplicate() if binding else null
	return config

static func input_id(event: InputEvent) -> String:
	if event is InputEventKey:
		var code = event.keycode if event.keycode != 0 else event.physical_keycode
		return "key_%d" % code if code != 0 else ""
	if event is InputEventMouseButton:
		return "mouse_%d" % event.button_index if event.button_index > 0 else ""
	return ""

static func input_text(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.keycode if event.keycode != 0 else event.physical_keycode).to_upper()
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LEFT CLICK"
			MOUSE_BUTTON_RIGHT: return "RIGHT CLICK"
			MOUSE_BUTTON_MIDDLE: return "MIDDLE CLICK"
			MOUSE_BUTTON_WHEEL_UP: return "WHEEL UP"
			MOUSE_BUTTON_WHEEL_DOWN: return "WHEEL DOWN"
			_: return "MOUSE %d" % event.button_index
	return "Press a key"

static func validation_message(configs: Array) -> String:
	var active = 0
	var ids = []
	var bindings = []
	for config in configs:
		if config.id < 0 or config.id > 3 or config.id in ids:
			return "Choose four unique player slots."
		ids.append(config.id)
		if config.mode == PlayerMode.CPU:
			active += 1
			continue
		if config.mode == PlayerMode.OFF:
			continue
		if config.mode != PlayerMode.HUMAN:
			return "Choose Human, CPU or Off for each player."
		active += 1
		var key = input_id(config.binding)
		if key.is_empty():
			return "Choose an input for P%d." % (config.id + 1)
		if key in ["key_%d" % KEY_ESCAPE, "key_%d" % KEY_TAB]:
			return "Escape and Tab are reserved for menus."
		if key in bindings:
			return "Each human needs a different input."
		bindings.append(key)
	if active == 0:
		return "Enable at least one player."
	return ""
