extends Control

# queues of animations to pass to eyeballs
var defaultQueue := ["blink", "look", "sparkle", "roll"]
var animationQueue := ["blink", "look", "sparkle", "roll"]
@export var minTime := 4
@export var maxTime := 7
const snakeOrigin := Vector2(1352,104)
var snakeIsPositioned := false

# play blink and shuffle the queue
func _ready() -> void:
	$Snake.global_position = snakeOrigin
	randomize()
	$EyeballLeft.play("blink")
	$EyeballRight.play("blink")
	$SnakeMover.play("slither")
	animationQueue.shuffle()


# if game is running, randomly select an animation
func _on_eyeball_timer_timeout() -> void:
	if !Globals.currentGameData.gameRunning:
		if animationQueue.size() > 0: # pick one from the queue
			var nextAnimation = animationQueue.pop_front()
			$EyeballLeft.play(nextAnimation)
			$EyeballRight.play(nextAnimation)
		else: # or play idle and refill the queue, resetting timer
			animationQueue = defaultQueue.duplicate()
			$EyeballLeft.play("idle")
			$EyeballRight.play("idle")
			$EyeballTimer.start(2)
	else:
		$EyeballLeft.play("idle")
		$EyeballRight.play("idle")


# every animation finish, if game is running, reset the timer between anims with random value
func _on_eyeball_left_animation_finished() -> void:
	if !Globals.currentGameData.gameRunning:
		$EyeballLeft.play("idle")
		$EyeballRight.play("idle")
		randomize()
		var _roll := randi_range(minTime, maxTime)
		$EyeballTimer.start(_roll)
	else:
		$EyeballTimer.stop()


# this switches the snake to stay still after movement animation
func _on_snake_mover_animation_finished(_anim_name: StringName) -> void:
	if _anim_name == "slither" and !snakeIsPositioned:
		snakeIsPositioned = true


# this controls the snake idle animation
# note: animation only processes when paused
func _process(_delta: float) -> void:
	if !snakeIsPositioned:
		$Snake.play("slither")
	else:
		$Snake.play("idle")
