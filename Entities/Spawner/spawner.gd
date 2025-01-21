extends Area2D

@export var pickup_scene: PackedScene
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var max_pickups: int = 5
@export var max_enemies:int = 3

@onready var collider := $CollisionShape2D
@onready var pickup_timer := $PickupTimer
@onready var enemy_timer := $EnemyTimer

# TODO: later, change this to enemy_waves
# waves can be something like (5 static enemies, 1 second apart), (2 static, 2 arrow enemies, 0 seconds apart)
# etc... 


var _active_pickups: Array[Node2D] = []
var _active_enemies: Array[Node2D] = []

func _ready() -> void:
	
	_spawn_entity(pickup_scene, _active_pickups, max_pickups)
	pickup_timer.wait_time = spawn_interval
	pickup_timer.start()
	pickup_timer.timeout.connect(func():_spawn_entity(pickup_scene, _active_pickups, max_pickups))
	
	_spawn_entity(enemy_scene, _active_enemies, max_enemies)
	enemy_timer.wait_time = spawn_interval
	enemy_timer.start()
	enemy_timer.timeout.connect(func():_spawn_entity(enemy_scene, _active_enemies, max_enemies))

func _spawn_entity(packed_scene:PackedScene, current_list:Array[Node2D], max_amount:int) -> void:
	if packed_scene and current_list.size() < max_amount:
		var _instance = packed_scene.instantiate()
		add_child(_instance)
		
		
			# Get the RectangleShape2D
		var rectangle_shape = collider.shape as RectangleShape2D
		if not rectangle_shape:
			push_error("CollisionShape2D does not have a RectangleShape2D")
			return

		# Calculate spawn position
		var extents = rectangle_shape.extents
		var spawn_position = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)

		# Apply the collision shape's position offset
		spawn_position += collider.position


		_instance.position = spawn_position
		
		current_list.append(_instance)
		_instance.tree_exiting.connect(_on_instance_removed.bind(_instance, current_list))
		
		#print("Pickup spawned! Total: ", _active_pickups.size(), " Position: ", pickup_instance.position)

func _on_instance_removed(instance: Node2D,scene_list:Array[Node2D]) -> void:
	scene_list.erase(instance)
