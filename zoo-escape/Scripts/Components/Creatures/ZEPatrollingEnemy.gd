class_name PatrollingEnemy
extends CharacterBody2D


# Behavior-related variables
enum behaviors {
	PATROL, ## Creature will follow a path comprising a series of wapoints (must use Marker2D, added to the WaypointManager node)
	STATIONARY ## Creature will remain where placed in the editor
}
@export var behavior: behaviors = behaviors.PATROL ## Do I patrol, or am I stationary?
@export var waitTime := 2.0 ## How long do I wait at waypoints?
@export var autoApproach := true ## Do I move toward the Player, along my path, if it gets near my path?
@export var approachProximity := 10.0 ## How close does the Player get to my path before I approach it?
@export var moveSpeed := 0.3 ## Delay between movements

# Waypoint-related variables
@onready var waypointManager := $WayPointManager
var waypoints: Array[Marker2D]
var lastWaypoint: Marker2D
var currentWaypoint: Marker2D
var savedPosition := Vector2.ZERO


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	self.add_to_group("Creatures")
	for waypoint in waypointManager.get_children():
		waypoints.push_back(waypoint)
		print(waypoint.global_position)


# Called every frame
func _process(_delta: float) -> void:
	if (behavior == behaviors.PATROL):
		pass


# Called to move the enemy toward the next waypoint
func moveTowardWayPoint() -> void:
	pass


# Called to find the nearest waypoint
func findNearestWayPoint() -> void:
	pass
