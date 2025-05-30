class_name Hud extends CanvasLayer


signal RestartRoom # reload signal
signal ExitGame # exit to title signal
signal ScoreProcessed # score processing signal for process score


enum SCORE_PROCESS_STATES {
	IDLE,
	TIME_PROCESS,
	MOVE_PROCESS,
	POST
}

var steakValue := 1 # live monitor of steak total
var timerValue := 1 # live monitor of timer
var movesValue := 0 # live monitor of moves
var scoreCurrent := 0  # player score
var secondBonus := 50 # values for abstraction from parent to apply
var movePenalty := 25 # score penalty per move
var moveMonitoring := false # shows timer has started
var timesUp := false # shows time is out
var allSteaksCollected := false # shows goal is open
var resetGauge := 0.0 # to compare with level manager
var password := "ABCD" # abstraction for password
var warningTime := 15 # value when warning cues
var timeLimit := 60 # value to change for each level
var scoreProcessState := SCORE_PROCESS_STATES.IDLE # state of score process function at level end
var tutorialMode := false # tutorial mode state (goes to hud)
var stepIconCount := 0


# Runs at the start set up
func _ready() -> void: # reset animations at ready, fetch start values
	## make sure to find level manager to double check level time
	$HUDAnimation.play("RESET")
	$HUDAnimationAlt.play("RESET")
	# to avoid queueing error on prompt
	$OpenCue.volume_db = SoundControl.cueLevel
	$AlertCue.volume_db = SoundControl.cueLevel


# Runs every frame
func _process(_delta: float) -> void:
	# fetch password from level manager and update
	$TimeOutCurtain/PasswordBox/PasswordLabel.text = "PASSWORD: "+str(password)
	if !timesUp: # if timer not out, update values and monitor inputs
		valueMonitoring()
	
	
	# this number taken from levelManager
	$ResetBar.value = resetGauge 
	$HUDIcons/MovesIcon.play("feedback") ## run animation, it has its own pause frames
	
	if !timesUp:
		## warning animation for low time
		if timerValue < warningTime and timerValue > 0:
			$HUDIcons/TimerIcon.play("feedback")
	
	## score processes when not idle or done
	if scoreProcessState != SCORE_PROCESS_STATES.IDLE:
		scoreProcessing()


# input start function and flip flop state
func levelTimerStart() -> void:
	$HUDAnimationAlt.play("time_text_reset") # reset time text (bugfix)
	if $HudWindow.scale.x < 1: # window bug fixing
		$HudWindow.scale.x = 1
	
	if !moveMonitoring:
		if !tutorialMode: ## check for tutorial state (given by level manager)
			$HUDAnimationAlt.play("timer_start") # play timer ping on separate animator
			moveMonitoring = true # moves now monitored
			$LevelTimer.start(1) # timer starts on first input
		else:
			$HUDIcons/TimerValue.text = "NONE" ## put tutorial time text


# update label values with strings
func valueMonitoring() -> void:
	# listen for steaks collected and update as needed
	if !allSteaksCollected:
		$HUDIcons/SteaksValue.text = str(steakValue) + "x"
	else:
		$HUDIcons/SteaksValue.text = "GOAL" # if all captured, goal text
	
	$HUDIcons/MovesValue.text = str(movesValue) + "m"
	
	# update timer as it counts down
	if timerValue < timeLimit:
		$HUDIcons/TimerValue.text = str(timerValue) + "s"
	if timerValue == 0 and scoreProcessState == SCORE_PROCESS_STATES.IDLE: # last second warning
		$HUDIcons/TimerValue.modulate = Color.RED
		$HUDIcons/TimerText.modulate = Color.RED


# if all collected, run animation
	if steakValue == 0 and !allSteaksCollected: 
		allSteaksCollected = true
		$HUDAnimationAlt.play("goal") # play on alt to prevent conflicts


# visual feedback for all steaks collected
func steakWiggle() -> void:
	$HUDIcons/SteakIcon.play("feedback")


# time functionality
func _on_level_timer_timeout() -> void:
	if scoreProcessState == SCORE_PROCESS_STATES.IDLE and !tutorialMode: # do not log timeouts during score processing
		if timerValue >= 1 and !timesUp: # if time not up, clock counts down
			timerValue -= 1
			$LevelTimer.start(1)
		
		if timerValue == 0: # on time up, flip state, stop non-system noises and trigger feedback
			$HUDAnimationAlt.play("close")
			SoundControl.stopSounds()
			$RestartButton.disabled = false
			$ExitButton.disabled = false
			get_tree().paused = true
			moveMonitoring = false
			$LevelTimer.stop()
			SoundControl.playCue(SoundControl.fail, 3.0)
			$HUDAnimation.play("time_out")
			timesUp = true
			$AlertCue.pitch_scale = 0.5 # alert noise
			$AlertCue.play()
			$RestartButton.grab_focus()
			$RestartButton.grab_click_focus()
			
		
		# warnings during period of time before time out (variable)
		if timerValue < warningTime and timerValue > 0:
			$HUDIcons/TimerIcon.play("feedback")
			$HUDAnimation.play("warning")
			$OpenCue.play() # additional warning cue every even second for dynamics


# buttons open when time out animation ends
func _on_hud_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "time_out":
		$RestartButton.disabled = false
		$ExitButton.disabled = false
		$RestartButton.grab_focus()
		$RestartButton.grab_click_focus()
		$HUDAnimation.stop()


# time out animation triggers when time is up
func _on_open_timer_timeout() -> void:
	$HUDAnimation.play("open")


# button emits signal to restart if time out
func _on_restart_button_pressed() -> void:
	$HudWindow.visible = false # hide window to avoid artifacting/bugs
	SoundControl.playCue(SoundControl.flutter, 3.0)
	buttonsDisabled()
	SoundControl.resetMusicFade()
	RestartRoom.emit() # signal to levelManager to reload


# button for exiting the game if time out
func _on_exit_button_pressed() -> void:
	$HudWindow.visible = false
	SoundControl.playCue(SoundControl.ruined, 0.5)
	buttonsDisabled()
	SoundControl.resetMusicFade()
	ExitGame.emit() # signal to levelManager to exit to title


# function to close buttons on input
func buttonsDisabled()  -> void: 
	$RestartButton.disabled = true
	$ExitButton.disabled = true


# remote hud close button
func closeHud()  -> void: 
	$HUDAnimationAlt.play("close")


# functions to hide and reveal reset bar
func resetBarReveal() -> void:
	$HUDAnimationAlt.play("reset_fader")


# remote function to fade out reset bar on release
func resetBarFade() -> void:
	$HUDAnimationAlt.play_backwards("reset_fader")


# remote function to show reload message on full reset bar
func resetPrompt() -> void: 
	$HUDAnimationAlt.play("close")
	$ResetBar/ResetLabel.text = "RELOADING..."


# score processing state machine
func scoreProcessing() -> void:
	match scoreProcessState:
		SCORE_PROCESS_STATES.TIME_PROCESS:
			if timerValue > 0: # timer adds bonus until zero
				timerValue -= 1
				Globals.currentGameData["playerScore"] += secondBonus
			else:
				scoreProcessState = SCORE_PROCESS_STATES.MOVE_PROCESS # then state flips
		SCORE_PROCESS_STATES.MOVE_PROCESS:
			if movesValue > 0: # moves subtract penalty until zero
				movesValue-=1
				Globals.currentGameData["playerScore"] -= movePenalty
			else: # then state flips back to off
				ScoreProcessed.emit() # after emitting one signal
				scoreProcessState = SCORE_PROCESS_STATES.POST


# grab click focus for restart
func _on_restart_button_mouse_entered() -> void:
	$RestartButton.grab_focus()


# grab input focus for exit
func _on_exit_button_mouse_entered() -> void:
	$ExitButton.grab_focus()


# opens settings in game (handled in settings)
func _on_settings_button_pressed() -> void:
	SoundControl.playCue(SoundControl.blip, 3.0)
	MenuManager.setMenu(MenuManager.menuTypes.SETTINGS)


# updates time text on hud
func updateTimeText(time: int) -> void:
	$HUDIcons/TimerValue.text = str(time) + "s"


# updates score text on hud
func updateScoreText(value) -> void:
	$HUDIcons/ScoreValue.text = str(value)


# updates move text on hud
func updateMovesText(count) -> void:
	$HUDIcons/MovesValue.text = str(count) + "m"


# updates steak text on hud
func updateSteaksText(count: int) -> void:
	$HUDIcons/SteaksValue.text = str(count) + "x"


# updates password text on hud
func updatePasswordText(code: String) -> void:
	$HUDIcons/PasswordValue.text = code
