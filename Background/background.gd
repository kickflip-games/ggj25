extends Node2D

@onready var static_background = $StaticBackground
@onready var color_rect = $MovingBars
var shader_mat: Material 
var tween: Tween

const C1: Color = Color(0.122, 0.122, 0.122, 1.0)
const C2: Color = Color(0.09, 0.09, 0.09, 1.0)
const SPEED: float = 3.0
const LINES: int = 20
const FADE_DURATION: float = 0.5
const MAX_ALPHA = 1.0


var is_powerup_mode: bool = false

func _ready():
	var mat = color_rect.material
	if mat is ShaderMaterial:
		shader_mat = mat
	else:
		push_error("Material is not a ShaderMaterial!")
	
	reset()
	setup_initial_state()

	#test_shader()

func setup_initial_state():
	# ColorRect can now stay visible, we just control shader alpha
	color_rect.modulate.a = 1.0
	static_background.modulate.a = 1.0
	
	# Start with shader invisible (alpha = 0)
	set_shader_alpha(0.0)
	is_powerup_mode = false

func reset():
	set_shader(SPEED, LINES, C1, C2, 0.0)  # Start with alpha 0

func set_color(c: Color):
	print("Set background color based on player")
	var c1 = c.darkened(0.8)
	var c2 = c.darkened(0.6)
	var current_alpha = shader_mat.get_shader_parameter("alpha")
	set_shader(SPEED * 2, LINES * 2, c1, c2, current_alpha)

func set_shader(_speed: float, _lines: int, _c1: Color, _c2: Color, _alpha: float = 1.0):
	if shader_mat:
		shader_mat.set_shader_parameter("speed", _speed)
		shader_mat.set_shader_parameter("line_count", float(_lines))
		shader_mat.set_shader_parameter("color_one", _c1)
		shader_mat.set_shader_parameter("color_two", _c2)
		shader_mat.set_shader_parameter("alpha", _alpha)

func set_shader_alpha(_alpha: float):
	if shader_mat:
		shader_mat.set_shader_parameter("alpha", _alpha)

func enter_powerup_mode():
	if is_powerup_mode:
		return
	
	print("background entere power mode")
	is_powerup_mode = true
	fade_shader_in()

func exit_powerup_mode():
	if not is_powerup_mode:
		return
	
	is_powerup_mode = false
	fade_shader_out()

func fade_shader_in():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_method(set_shader_alpha, 0.0, MAX_ALPHA, FADE_DURATION)
	tween.set_ease(Tween.EASE_IN)

func fade_shader_out():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_method(set_shader_alpha, MAX_ALPHA, 0.0, FADE_DURATION)
	tween.set_ease(Tween.EASE_OUT)

# Public interface functions
func start_powerup():
	enter_powerup_mode()

func end_powerup():
	exit_powerup_mode()

# Instant switching for debugging
func instant_show_shader():
	set_shader_alpha(MAX_ALPHA)
	is_powerup_mode = true

func instant_hide_shader():
	set_shader_alpha(0.0)
	is_powerup_mode = false

	
