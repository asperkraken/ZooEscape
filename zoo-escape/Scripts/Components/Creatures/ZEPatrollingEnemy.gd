class_name PatrollingEnemy
extends CharacterBody2D


# Enums
## Enemy will either patrol or stand still
enum behaviors {
	PATROL, ## Creature will follow a path comprising a series of wapoints (must use Marker2D, added to the WaypointManager node)
	STATIONARY ## Creature will remain where placed in the editor
} 

## The PatrollingEnemy can be Idle, Patrolling, or Approaching
enum state {
	IDLE, ## Creature is not moving (either resting at a way point or stationary)
	PATROL, ## Creature is actively patrolling (moving toward a waypoint)
	APPROACH ## Creature is approaching the Player (moving toward the waypoint nearest the player)
}

# Constants
const dirToAnimtionName := {
	Vector2.UP: "IdleUp",
	Vector2.RIGHT: "IdleRight",
	Vector2.DOWN: "IdleDown",
	Vector2.LEFT: "IdleLeft"
} ## Directional movement-to-animation converter

# Behavior-related variables
@export var behavior: behaviors = behaviors.PATROL ## Do I patrol, or am I stationary?
@export var makeALoop := false ## Is the defined path supposed to be a loop?  If so, Enemy will take a circular path instead of moving back and forth.
@export_range(0.1, 5.0, 0.1) var waitTime := 0.3 ## How long do I wait at waypoints?
@export var autoApproach := true ## Do I move toward the Player, along my path, if it gets near my path?
@export_range(0.0, 96.0, 16.0) var approachProximity := 16.0 ## How close does the Player get to my path before I approach it?
@export var moveSpeed := 0.3 ## Time to delay between movements
var currentState: state = state.IDLE ## The current state of the Enemy
var timeWaited := 0.0 ## How long the Enemy has been waiting
var waypoints: Array[Marker2D] ## An array of waypoints for the Enemy to move to
var lastWaypoint: int ## The last waypoint's index within the waypoints array
var currentWaypoint := 0 ## The current waypoint's index within the waypoints array
var savedPosition := Vector2.ZERO ## The position from which the Enemy came
var iterationDirection := 1 ## The direction along the path we're traveling (1 = counting up, -1 = counting down)
var isPlayerNear := false ## Indicates whether the Player is near Enemy waypoints

# Additional variables
@onready var terrainDetector := $Area2D
@onready var sprite := $AnimatedSprite2D
@onready var ray := $RayCast2D
@onready var waypointManager := $WaypointManager


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	self.add_to_group("Enemies")
	if behavior == behaviors.PATROL:
		# Make an array of waypoints
		for waypoint in waypointManager.get_children():
			waypoints.push_back(waypoint)
			print("Waypoint: ", waypoint.global_position)
		# If there are waypoints, pick the first one
		if waypoints:
			currentWaypoint = 0
			self.global_position = waypoints[currentWaypoint].global_position
			
		else:
			print(self.name, ": No waypoints!  Standing still instead.")
			behavior = behaviors.STATIONARY
			autoApproach = false


# Called every frame
func _process(delta: float) -> void:
	# TODO: If the enemy is supposed to approach nearby Player, detect if Player is near path
	# This should interrupt normal patrolling
	if autoApproach:
		pass
	
	match behavior:
		# If the Enemy is set to Stationary, be still
		behaviors.STATIONARY:
			print("Hey! You wanted me to wait here, so I'm waiting!")
			return
	
		# If the Enemy is set to Patrol, do that
		behaviors.PATROL:
			# Add time since last frame
			timeWaited += delta
			# If not enough time has elapsed since the last move, exit the process early
			if !timeWaited >= waitTime:
				return
			# If enough time has elapsed, make sure you haven't reached your destination, then try to move
			else:
				timeWaited = 0
				# If I have not reached my waypoint, move toward it
				if !self.global_position == waypoints[currentWaypoint].global_position:
					# TODO: Move TOWARD the currentWaypoint
					print("Moving toward: ", currentWaypoint, " | ", waypoints[currentWaypoint].global_position)
					self.global_position = waypoints[currentWaypoint].global_position
				# If I have reached my waypoint, get a new one and move toward that
				else:
					print("Reached destination: ", currentWaypoint)
					lastWaypoint = currentWaypoint
					# When I reach the end of the waypoints array, where do I go?
					if currentWaypoint >= waypoints.size() - 1:
						# Do I go back the other direction?
						if !makeALoop:
							iterationDirection = -1
						# Or do I make a loop?
						else:
							iterationDirection = 1
							currentWaypoint = -1
					# 
					if currentWaypoint <= 0:
						iterationDirection = 1
					
					currentWaypoint += iterationDirection
					
						
					print("Moving to: ", currentWaypoint)
					self.global_position = waypoints[currentWaypoint].global_position



# Called to face the direction of movement or the player
func faceDirection(dir: Vector2) -> void:
	sprite.play(dirToAnimtionName[dir])
	ray.target_position = dir * Globals.ZETileSize


# Called to move the enemy
func move(dir: Vector2) -> void:
	faceDirection(dir)
