# player_data.gd
extends RefCounted  # Use RefCounted for a lightweight, reusable class
class_name PlayerData

var name: String
var x0: Vector2 # start pos
var ui: PlayerUi
var color: Color
var id:int






# Constructor
func _init(id: int, x0: Vector2, ui:PlayerUi) -> void:
	self.id = id 
	self.name = "player" + str(id)
	self.x0 = x0
	self.ui = ui
	self.color = color
