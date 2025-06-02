class_name ZEBall extends Area2D


# all possible actions in state machine
enum STATES {
	IDLE,
	MOVING,
}
var currentState := STATES.IDLE


# list of items that will stop ball movement
var validCollisions := [
	"Player",
	"Wall",
	"Box",
	"Switch",
	"Gate",
	"Ball"
]

@export var moveWidthTime := 0.75 # time between moves, changes with terrain
var moveDistance := Globals.TILESIZE
var dirCheck := Vector2.ZERO
var modulatedTime := moveWidthTime
@onready var raycast := $RayCast2D
@onready var checkSpace := $EnvironmentCheck


# Called to move the ball if possible from player
func move(dir: Vector2):
	# check prevents "rolling in place" animation if facing same direction
	if raycast.target_position != dir * (Globals.TILESIZE * 4):
		$BallSprite.play("roll")
	
	# move ball in player facing direction
	raycast.target_position = dir * (Globals.TILESIZE * 4) # change direction
	dirCheck = dir
	raycast.force_raycast_update()

	
	# move if not colliding
	if currentState == STATES.IDLE && !raycast.is_colliding():
		currentState = STATES.MOVING
		$Cue.play()
		position += dir * Globals.TILESIZE
		$MoveTimer.start(modulatedTime)


# Called to set the ball to Idle, stop movement, call sound and idle animation
func idle() -> void:
	SoundControl.playSfx(SoundControl.thump)
	$BallSprite.play("idle")
	currentState = STATES.IDLE
	dirCheck = Vector2.ZERO
	$MoveTimer.stop()



# Called every physics frame, checks for collisions with valid objects
func _physics_process(_delta: float) -> void:
	if $RayCast2D.is_colliding() && currentState != STATES.IDLE:
		var collider = $RayCast2D.get_collider()
		if collider.name in validCollisions:
			idle()


# Called to detect what the ball is colliding with
func _on_body_entered(_body: Node2D) -> void:
	if currentState != STATES.IDLE && raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.name in validCollisions: # check collision list
			SoundControl.playSfx(SoundControl.thump)
			idle() # stop if in collision list


# Called when the move timer expires, determines whether to move or stop
func _on_move_timer_timeout() -> void:
	modulatedTime = moveWidthTime # reset time before modify for checking terrain state
	match currentState:
		STATES.IDLE: # hold all movement
			position = Vector2.ZERO
			$MoveTimer.stop()
		STATES.MOVING:
			position += dirCheck * Globals.TILESIZE
			$MoveTimer.start(modulatedTime) # this time is called if terrain in unchanged
			if modulatedTime == moveWidthTime*2:
				$BallSprite.play("float")
			if modulatedTime != moveWidthTime*2: # do not show water if out of water
				$BallSprite.play("roll")
			if modulatedTime != moveWidthTime*3: # return speed if not sliding
				$BallSprite.speed_scale = 1.0


# Called to detect which terrain the ball is on and impact speed of movement
func _on_environment_check_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		var pos := Vector2i(body.local_to_map(($EnvironmentCheck/CheckArea.global_position)))
		var tileData = body.get_cell_tile_data(pos)
		if tileData.get_custom_data("Water"):
			$BallSprite.play("float") # play float animation if in water
			modulatedTime = moveWidthTime*2 # call timer immediately or incorrect speed jump
		if tileData.get_custom_data("Ice"):
			modulatedTime = moveWidthTime*3
			$BallSprite.speed_scale = 3.0
