extends Control
const SlotConfig = preload("res://HUD/GameStart/player_slot_config.gd")
signal match_requested(configuration: Array)
signal capture_requested(slot_id: int)
var configuration: Array = []
@onready var slots = $Margin/Contents/Grid.get_children()
@onready var start_button = $Margin/Contents/Start
@onready var status = $Margin/Contents/Status

func _ready():
	for i in range(4):
		var config = SlotConfig.new(i)
		config.mode = SlotConfig.PlayerMode.HUMAN if i == 0 else SlotConfig.PlayerMode.OFF
		configuration.append(config)
		InputMap.action_erase_events("player%d" % i)
		slots[i].enable_requested.connect(_enable.bind(i))
		slots[i].disable_requested.connect(_disable.bind(i))
		slots[i].binding_requested.connect(_request_binding.bind(i))
		slots[i].cpu_requested.connect(_use_cpu.bind(i))
		slots[i].human_requested.connect(_enable.bind(i))
	start_button.pressed.connect(request_start)
	refresh()

func _request_binding(id: int):
	capture_requested.emit(id)

func _enable(id: int):
	configuration[id].mode = SlotConfig.PlayerMode.HUMAN
	refresh()
	slots[id].celebrate()
	capture_requested.emit(id)

func _use_cpu(id: int):
	configuration[id].mode = SlotConfig.PlayerMode.CPU
	configuration[id].binding = null
	InputMap.action_erase_events("player%d" % id)
	refresh()
	slots[id].celebrate()

func _disable(id: int):
	configuration[id].mode = SlotConfig.PlayerMode.OFF
	configuration[id].binding = null
	InputMap.action_erase_events("player%d" % id)
	refresh()

func refresh():
	for i in range(4):
		var config = configuration[i]
		slots[i].display(i, config.mode != SlotConfig.PlayerMode.OFF, SlotConfig.input_text(config.binding), config.mode == SlotConfig.PlayerMode.CPU)
	var reason = SlotConfig.validation_message(configuration)
	start_button.disabled = not reason.is_empty()
	status.text = reason if not reason.is_empty() else "Ready! One button to move. Avoid skulls; collect stars."

func assign_input(id: int, event: InputEvent) -> String:
	var key = SlotConfig.input_id(event)
	if configuration[id].mode != SlotConfig.PlayerMode.HUMAN or key.is_empty():
		return "Enable this human slot and choose a key or mouse button."
	if key in ["key_%d" % KEY_ESCAPE, "key_%d" % KEY_TAB]:
		return "Escape and Tab are reserved for menus."
	for config in configuration:
		if config.id != id and config.mode == SlotConfig.PlayerMode.HUMAN and SlotConfig.input_id(config.binding) == key:
			return "%s is already used by P%d. Try another input." % [SlotConfig.input_text(event), config.id + 1]
	var binding = event.duplicate()
	binding.pressed = false
	if binding is InputEventKey:
		binding.echo = false
	configuration[id].binding = binding
	InputMap.action_erase_events("player%d" % id)
	InputMap.action_add_event("player%d" % id, binding)
	refresh()
	slots[id].celebrate()
	return ""

func request_start():
	var reason = SlotConfig.validation_message(configuration)
	if not reason.is_empty():
		status.text = reason
		return
	var selected = []
	for config in configuration:
		selected.append(config.copy())
	match_requested.emit(selected)
