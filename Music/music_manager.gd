# GlobalMusicManager.gd
# Add this as an AutoLoad singleton in Project Settings -> AutoLoad

extends Node

# Music players for crossfading
@onready var normal_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var powerup_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Current state
enum MusicMode { NORMAL, POWERUP }
var current_mode: MusicMode = MusicMode.NORMAL
var is_transitioning: bool = false

# Music resources - assign these in the editor or via code
var normal_music: AudioStream = preload("res://Music/normal.mp3")
var powerup_music: AudioStream= preload("res://Music/superstar.mp3")

# Transition settings
var crossfade_duration: float = 0.75  # seconds
var normal_volume: float = 0.0  # dB
var powerup_volume: float = 0.0  # dB

# Tween for smooth transitions
var tween: Tween

func _ready():
	# Add audio players to the scene tree
	add_child(normal_player)
	add_child(powerup_player)
	
	# Configure audio players
	normal_player.name = "NormalMusicPlayer"
	powerup_player.name = "PowerupMusicPlayer"
	
	# Set initial volumes
	normal_player.volume_db = normal_volume
	powerup_player.volume_db = -80  # Start silent
	
	# Create tween for smooth transitions
	tween = create_tween()
	
	# Connect finished signals for looping management
	normal_player.finished.connect(_on_normal_finished)
	powerup_player.finished.connect(_on_powerup_finished)
	
	setup_music(normal_music, powerup_music)
	start_music()

# Initialize with music resources
func setup_music(normal_track: AudioStream, powerup_track: AudioStream):
	normal_music = normal_track
	powerup_music = powerup_track
	
	# Set the normal music as default
	normal_player.stream = normal_music
	powerup_player.stream = powerup_music

# Start playing music (call this when the game starts)
func start_music():
	if normal_music == null:
		push_warning("GlobalMusicManager: No normal music assigned!")
		return
	
	normal_player.play()
	current_mode = MusicMode.NORMAL
	
	# Debug: Check if it's actually playing
	await get_tree().process_frame
	print("Music playing: ", normal_player.playing)

# Switch to powerup mode
func enter_powerup_mode():
	
	if current_mode == MusicMode.POWERUP:
		print("Already in powerup mode!")
		return
	
	if is_transitioning:
		print("Already transitioning!")
		return
	_transition_to_powerup()

# Switch back to normal mode
func exit_powerup_mode():
	
	if current_mode == MusicMode.NORMAL:
		print("Already in normal mode!")
		return
	
	if is_transitioning:
		print("Already transitioning!")
		return
	
	
	_transition_to_normal()

# Toggle between modes (useful for testing)
func toggle_mode():
	if current_mode == MusicMode.NORMAL:
		enter_powerup_mode()
	else:
		exit_powerup_mode()

# Internal transition to powerup
func _transition_to_powerup():
	if powerup_music == null:
		push_warning("GlobalMusicManager: No powerup music assigned!")
		return
	is_transitioning = true
	current_mode = MusicMode.POWERUP
	
	# Get current position - but handle edge case where normal player isn't playing
	var current_position = 0.0
	if normal_player.playing:
		current_position = normal_player.get_playback_position()
	
	
	# Start powerup music at current position (for seamless transition)
	powerup_player.play(current_position)
	powerup_player.volume_db = -80  # Start silent
	
	# Create new tween and crossfade: fade out normal, fade in powerup
	tween = create_tween()
	tween.tween_method(_crossfade_to_powerup, 0.0, 1.0, crossfade_duration)
	await tween.finished
	
	print("Powerup transition complete!")
	
	# Stop normal music to save resources
	normal_player.stop()
	is_transitioning = false

# Internal transition to normal
func _transition_to_normal():
	
	is_transitioning = true
	current_mode = MusicMode.NORMAL
	
	# Get current position - but handle edge case where powerup player isn't playing
	var current_position = 0.0
	if powerup_player.playing:
		current_position = powerup_player.get_playback_position()
	
	
	# Start normal music at current position
	normal_player.play(current_position)
	normal_player.volume_db = -80  # Start silent
	
	# Create new tween and crossfade: fade out powerup, fade in normal
	tween = create_tween()
	tween.tween_method(_crossfade_to_normal, 0.0, 1.0, crossfade_duration)
	await tween.finished
	
	
	# Stop powerup music to save resources
	powerup_player.stop()
	is_transitioning = false

# Crossfade interpolation functions
func _crossfade_to_powerup(progress: float):
	var normal_vol = lerp(normal_volume, -80.0, progress)
	var powerup_vol = lerp(-80.0, powerup_volume, progress)
	
	normal_player.volume_db = normal_vol
	powerup_player.volume_db = powerup_vol
	

func _crossfade_to_normal(progress: float):
	var powerup_vol = lerp(powerup_volume, -80.0, progress)
	var normal_vol = lerp(-80.0, normal_volume, progress)
	
	powerup_player.volume_db = powerup_vol
	normal_player.volume_db = normal_vol
	

# Handle music looping
func _on_normal_finished():
	if current_mode == MusicMode.NORMAL and not is_transitioning:
		normal_player.play()

func _on_powerup_finished():
	if current_mode == MusicMode.POWERUP and not is_transitioning:
		powerup_player.play()

# Utility functions
func set_master_volume(volume_db: float):
	normal_volume = volume_db
	powerup_volume = volume_db
	
	if current_mode == MusicMode.NORMAL and not is_transitioning:
		normal_player.volume_db = normal_volume
	elif current_mode == MusicMode.POWERUP and not is_transitioning:
		powerup_player.volume_db = powerup_volume

func set_crossfade_duration(duration: float):
	crossfade_duration = max(0.1, duration)  # Minimum 0.1 seconds

func stop_all_music():
	normal_player.stop()
	powerup_player.stop()

func pause_music():
	normal_player.stream_paused = true
	powerup_player.stream_paused = true

func resume_music():
	normal_player.stream_paused = false
	powerup_player.stream_paused = false

func get_current_mode() -> MusicMode:
	return current_mode

func is_music_playing() -> bool:
	return normal_player.playing or powerup_player.playing

# Debug/Test function - call this to test with built-in sounds
func test_with_builtin_sounds():
	print("Testing music manager with built-in sounds...")
	
	# Create simple test tones (you can replace with actual music files)
	var normal_test = AudioStreamGenerator.new()
	var powerup_test = AudioStreamGenerator.new()
	
	setup_music(normal_test, powerup_test)
	start_music()
	
	print("Test started. You should hear a tone.")
	print("Call GlobalMusicManager.toggle_mode() to test switching")
