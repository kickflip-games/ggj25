extends Control
signal input_chosen(slot_id: int, event: InputEvent)
signal cancelled
var capturing_slot: int = -1
var _opened_frame: int
@onready var prompt = $Center/Prompt/Player
@onready var warning = $Center/Prompt/Warning
@onready var cancel_button = $Center/Prompt/Cancel

func _ready():
	cancel_button.pressed.connect(cancel_capture)

func start_capture(slot_id: int):
	capturing_slot = slot_id
	_opened_frame = Engine.get_process_frames()
	prompt.text = "P%d — choose your input" % (slot_id + 1)
	prompt.modulate = Globals.PLAYER_COLORS[slot_id]
	warning.text = ""
	show()

func finish_capture():
	capturing_slot = -1
	hide()
	cancel_button.release_focus()

func cancel_capture():
	finish_capture()
	cancelled.emit()

func _input(event: InputEvent):
	if capturing_slot == -1 or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			cancel_capture()
		elif event.keycode == KEY_TAB:
			warning.text = "Tab is reserved for menu navigation."
		else:
			# Store a single logical key, without transient pressed/modifier flags.
			var binding = InputEventKey.new()
			binding.keycode = event.keycode if event.keycode != 0 else event.physical_keycode
			input_chosen.emit(capturing_slot, binding)
	elif event is InputEventMouseButton and event.pressed:
		if cancel_button.get_global_rect().has_point(event.position):
			return
		get_viewport().set_input_as_handled()
		if Engine.get_process_frames() <= _opened_frame:
			return
		# Visible buttons below the overlay cannot be assigned or clicked through.
		if _over_button(get_parent(), event.position):
			warning.text = "Click empty paper to bind a mouse button."
			return
		var binding = InputEventMouseButton.new()
		binding.button_index = event.button_index
		input_chosen.emit(capturing_slot, binding)

func _over_button(node: Node, point: Vector2) -> bool:
	if node is BaseButton and node.is_visible_in_tree() and node.get_global_rect().has_point(point):
		return true
	for child in node.get_children():
		if _over_button(child, point):
			return true
	return false
