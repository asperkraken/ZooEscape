extends Control

# queues of animations to pass to eyeballs
var defaultQueue := ["blink", "look", "sparkle", "roll"]
var animationQueue := ["blink", "look", "sparkle", "roll"]
@export var minTime := 4
@export var maxTime := 7


# play blink and shuffle the queue
func _ready() -> void:
	randomize()
	$EyeballLeft.play("blink")
	$EyeballRight.play("blink")
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
