extends Control


var steakValue : int = 1 ## live monitor of steak total
var timerValue : int = 1 ## live monitor of timer
var movesValue : int = 0 ## live monitor of moves
var moveMonitoring : bool = false ## shows timer has started
var timesUp : bool = false ## shows time is out
var allSteaksCollected : bool = false ## shows goal is open
@export var warningTime : int = 10 ## value when warning cues
@export var timeLimit : int = 30 # value to change for each level


func _ready() -> void: ## reset animations at ready, fetch start values
	$HUDAnimation.play("RESET")
	$HUDAnimationAlt.play("RESET")
	steakValueFetch()
	timerValue = timeLimit
	

func _process(_delta: float) -> void:
	if !timesUp: ## if timer not out, update values and monitor inputs
		steakValueFetch()
		valueMonitoring()
		inputWatch()


	## level timer does not start until first input
	if !moveMonitoring and !timesUp:
		if Input.is_action_just_pressed("DigitalDown"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalLeft"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalRight"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalUp"):
			levelTimerStart()


## input start function and flip flop state
func levelTimerStart():
	$HUDAnimationAlt.play("time_text_reset") ## reset time text (bugfix)
	if $HudWindow.scale.x < 1: ## window bug fixing
		$HudWindow.scale.x = 1


	$HUDAnimationAlt.play("timer_start") ## play timer ping on separate animator
	moveMonitoring = true ## moves now monitored
	$LevelTimer.start(1) ## timer starts on first input


## update label values with strings
func valueMonitoring():
	if !allSteaksCollected:
		$HudWindow/SteaksValue.text = str(steakValue)+"x"
	else:
		$HudWindow/SteaksValue.text = "GOAL!!" ## if all captured, goal text
	$HudWindow/MovesValue.text = str(movesValue)+"m"
	$HudWindow/TimerValue.text = str(timerValue)+"s"

	if steakValue == 0 and !allSteaksCollected: ## if all collected, run animation
		allSteaksCollected = true
		$HUDAnimationAlt.play("goal") ## play on alt to prevent conflicts


func steakValueFetch(): ## count amount of steaks in scene
	var steakCount = get_tree().get_node_count_in_group("steaks")
	steakValue = steakCount


func inputWatch(): ## listen for moves and update total
	if Input.is_action_just_pressed("DigitalDown"):
		movesValue+=1
	if Input.is_action_just_pressed("DigitalUp"):
		movesValue+=1
	if Input.is_action_just_pressed("DigitalLeft"):
		movesValue+=1
	if Input.is_action_just_pressed("DigitalRight"):
		movesValue+=1

## time functionality
func _on_level_timer_timeout() -> void:
	if timerValue >= 1 and !timesUp: ## if time not up, clock counts down
		timerValue-=1
		$LevelTimer.start(1)
	else: ## on time up, flip state, stop non-system noises and trigger feedback
		SoundControl.stopSounds()
		get_tree().paused = true
		moveMonitoring = false
		$LevelTimer.stop()
		SoundControl.playCue(SoundControl.fail,3.0)
		$HUDAnimation.play("time_out")
		timesUp = true


	## warnings during period of time before time out (variable)
	if timerValue < warningTime and timerValue > 0:
		$HUDAnimation.play("warning")
		$OpenCue.play() ## additional warning cue every even second for dynamics


## buttons open when time out animation ends
func _on_hud_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "time_out":
		$HUDAnimation.stop()
		$RestartButton.grab_focus()


## time out animation triggers when time is up
func _on_open_timer_timeout() -> void:
	$HUDAnimation.play("open")


## button for restart
func _on_restart_button_pressed() -> void:
	SoundControl.playCue(SoundControl.flutter,3.0)
	buttonsDisabled()
	## TODO: connect to restartRoom function in ZELevelManager


func _on_exit_button_pressed() -> void:
	SoundControl.playCue(SoundControl.ruined,0.5)
	buttonsDisabled()
	## TODO: connect to returnToTitle function in GameRoot


func buttonsDisabled():
	$RestartButton.disabled = true
	$ExitButton.disabled = true
