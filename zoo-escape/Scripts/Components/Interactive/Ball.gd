class_name ZEBall extends Area2D


# action states of object
enum STATES {
	IDLE,
	MOVING,
	SLIDING,
	FLOATING
}

# list for valid collision objects, checked in physics
var validColliders := ["Wall","Box","Switch","Player"]

# how long is time between tile moves
@export var moveWidthTime := 0.75
var currentState := STATES.IDLE
var moveDistance := Globals.TILESIZE
var dirCheck := Vector2.ZERO
var skidTime := moveWidthTime * 2 # time it takes to move on ice
var playerPresent := false
@onready var raycast := $RayCast2D


# Called to move the ball if possible
func move(dir:Vector2):
	$BallSprite.play("roll") # play animation
	raycast.target_position = dir * (Globals.TILESIZE * 4) # check directly outside position
	dirCheck = dir # capture player input direction
	raycast.force_raycast_update() # lock direction
	
	# begin movement if not colliding in raycast direction
	if currentState == STATES.IDLE && !raycast.is_colliding():
		if playerPresent == true and Input.is_action_just_pressed("ActionButton"):
			currentState = STATES.MOVING # change state
			SoundControl.playSfx(SoundControl.flutter) # TODO: Get better audio cue
			position += dir * Globals.TILESIZE # move in direction of player input
			$MoveTimer.start(moveWidthTime) # timer set to gap time


# Called to set the ball to Idle
func idle():
	SoundControl.playSfx(SoundControl.thump) # audio feedback
	$BallSprite.play("idle") # reset animation
	currentState = STATES.IDLE # reset state
	dirCheck = Vector2.ZERO # clear velocity
	$MoveTimer.stop() # stop movement timer


# Called every physics frame
func _physics_process(_delta: float) -> void:
	# if you hit a collider, stop movement if solid
	if $RayCast2D.is_colliding() and currentState != STATES.IDLE:
		var collider = $RayCast2D.get_collider() # get collision report
		if collider.name in validColliders: # check if not the player
			idle()


# Called to detect what the ball is colliding with
func _on_body_entered(body: Node2D) -> void:
	if currentState != STATES.IDLE && raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.name in validColliders: # audio feedback on stop
			SoundControl.playSfx(SoundControl.thump)
			idle() # stop movement
			if collider.name == "Player":
				playerPresent = true
		else:
			# check for ice or water state
			if body is TileMapLayer:
				var tilePos: Vector2i = body.local_to_map(self.global_position)
				if body.get_cell_tile_data(tilePos).get_custom_data("Water"):
					SoundControl.playCue(SoundControl.fail,3.0)
					currentState = STATES.FLOATING
				if body.get_cell_tile_data(tilePos).get_custom_data("Ice"):
					if(!raycast.is_colliding()):
						currentState = STATES.SLIDING
					else:
						currentState = STATES.IDLE



# Called when the move timer expires
func _on_move_timer_timeout() -> void:
	match currentState:
		STATES.IDLE:
			position = Vector2.ZERO # stop motion and timer
			$MoveTimer.stop()
		STATES.MOVING:
			position += dirCheck * Globals.TILESIZE # move on each timeout until collision
			$MoveTimer.start(moveWidthTime)
		STATES.SLIDING:
			position += dirCheck * Globals.TILESIZE
			$MoveTimer.start(skidTime)
		STATES.FLOATING:
			position += dirCheck * Globals.TILESIZE
			$MoveTimer.start(skidTime)
