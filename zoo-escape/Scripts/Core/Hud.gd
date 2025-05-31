class_name Hud extends CanvasLayer


signal RestartRoom # reload signal
signal QuitGame # quit to title signal

var resetBarVisible := false # is the resetBar visible?


# Called when the node first enters the scene tree
func _ready() -> void: # reset animations at ready, fetch volume values
	$HUDAnimation.play("RESET")
	$HUDAnimationAlt.play("RESET")
	# to avoid queueing error on prompt
	$OpenCue.volume_db = SoundControl.cueLevel
	$AlertCue.volume_db = SoundControl.cueLevel
	
	if $HudWindow.scale.x < 1: # window bug fixing # NOTE: To whomever put this in: when is this necessary?  Please discuss in Discord.
		$HudWindow.scale.x = 1


# Play animation when level begins
func playTimeTextReset() -> void:
	pass
	#$HUDAnimationAlt.play("time_text_reset") # reset time text


# Play animation when level begins
func playTimerStart() -> void:
	$HUDAnimationAlt.play("timer_start") # play timer ping on separate animator


# Play HUD close animation
func closeHud()  -> void: 
	$HUDAnimationAlt.play("close")


# Give visual and audio warnings when running low on time
func giveTimeWarning() -> void:
	$HUDIcons/TimerIcon.play("feedback")
	$HUDAnimation.play("warning")
	$OpenCue.play() # Audio warning cue


# Called to turn the timer text red for time warnings
func modulateTimerColor() -> void:
	$HUDIcons/TimerValue.modulate = Color.RED
	$HUDIcons/TimerIcon.modulate = Color.RED


# Show the Timeout window when out of time
func outOfTime() -> void:
	$HUDAnimationAlt.play("close")
	SoundControl.stopSounds()
	$RestartButton.disabled = false
	$QuitButton.disabled = false
	get_tree().paused = true
	SoundControl.playCue(SoundControl.fail, 3.0)
	$HUDAnimation.play("time_out")
	$AlertCue.pitch_scale = 0.5 # alert noise
	$AlertCue.play()
	$RestartButton.grab_focus()
	$RestartButton.grab_click_focus()


# Play the HUD open animation (when hud loaded, e.g.)
func onOpenTimerTimeout() -> void:
	$HUDAnimation.play("open")


# Function to disable buttons on input
func disableButtons()  -> void: 
	$RestartButton.disabled = true
	$QuitButton.disabled = true


# Functions to reveal reset bar
func resetBarReveal() -> void:
	if !resetBarVisible:
		$HUDAnimationAlt.play("reset_fader")
		resetBarVisible = true


# Function to fade out reset bar on release
func resetBarFade() -> void:
	$HUDAnimationAlt.play_backwards("reset_fader")
	resetBarVisible = false


# Function to show reload message on full reset bar
func resetPrompt() -> void: 
	$HUDAnimationAlt.play("close")
	$ResetBar/ResetLabel.text = "RELOADING..."


# Update the reset bar value (for filling the progress bar)
func resetBarUpdate(value: float) -> void:
	$ResetBar.value = value


# Set some text values if we're playing a tutorial
func setTutorialText():
	$HUDIcons/TimerValue.text = "NONE"


# Updates time text on hud
func updateTimeText(time: int) -> void:
	if !$HUDAnimationAlt.current_animation == "timer_start":
		$HUDIcons/TimerValue.text = str(time) + "s" # If not playing a tutorial, display how much time is left


# Updates score text on hud
func updateScoreText(value) -> void:
	$HUDIcons/ScoreValue.text = str(value)


# Updates move text on hud
func updateMovesText(count) -> void:
	$HUDIcons/MovesValue.text = str(count) + "m"


# Updates steak text on hud (play animations if count = 0)
func updateSteaksText(count: int) -> void:
	if count > 0: # If the new value is more than 0, show that
		$HUDIcons/SteaksValue.text = str(count) + "x"
		
	else: # If the new value is less than or equal to 0, goal has been met
		$HUDIcons/SteaksValue.text = "GOAL"
		$HUDIcons/SteakIcon.play("feedback")
		$HUDAnimationAlt.play("goal")


# updates password text on hud
func updatePasswordText(code: String) -> void:
	$HUDIcons/PasswordValue.text = code # Password value in the HUD
	$TimeOutCurtain/PasswordBox/PasswordLabel.text = "PASSWORD: " + str(code) # Password label in the Time Out window


# Open SettingsMenu in game (handled by MenuManager)
func onSettingsButtonPressed() -> void:
	SoundControl.playCue(SoundControl.blip, 3.0)
	MenuManager.setMenu(MenuManager.menuTypes.SETTINGS)


# Button emits signal to restart if time out
func onRestartButtonPressed() -> void:
	$HudWindow.visible = false # Hide HUD
	SoundControl.playCue(SoundControl.flutter, 3.0)
	disableButtons()
	SoundControl.resetMusicFade()
	RestartRoom.emit() # signal to levelManager to reload


# button for exiting the game if time out
func onQuitButtonPressed() -> void:
	$HudWindow.visible = false
	SoundControl.playCue(SoundControl.ruined, 0.5)
	disableButtons()
	SoundControl.resetMusicFade()
	QuitGame.emit() # signal to levelManager to exit to title


# Grab click focus for restart
func onRestartButtonMouseEntered() -> void:
	$RestartButton.grab_focus()


# Grab input focus for exit
func onQuitButtonMouseEntered() -> void:
	$QuitButton.grab_focus()
