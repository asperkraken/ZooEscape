extends Control

signal SetMenu(menu: MenuManager.menuTypes)

enum menuButtons {
	NEWGAME,
	PASSWORD,
	SETTINGS,
	EXIT
}

# Variables
var areYouSure := false


# Handles to child nodes
@onready var buttons := [ $NewGameButton, $PasswordButton, $SettingsButton, $ExitButton ]
var lastButton := menuButtons.NEWGAME


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# If playing the web version, hide the Exit button
	if OS.get_name() == "Web":
		$ExitButton.hide()
	
	# Connect menu button signals to Event Handlers
	for i: int in buttons.size():
		buttons[i].pressed.connect(onButtonPressed.bind(i))
		buttons[i].mouse_entered.connect(onButtonMouseEntered.bind(i))
		buttons[i].focus_entered.connect(onButtonFocusEntered.bind(i))
	
	# Focus on the last button to be used in this window (New Game by default)
	lastButtonFocus()


# Reset exit warning state and roll out message
func areYouSureReset():
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


# Event handler for when a menu button is pressed
func onButtonPressed(i: int) -> void:
	#  Determine which button got pressed
	match i as menuButtons:
		# New Game button
		menuButtons.NEWGAME:
			lastButton = menuButtons.NEWGAME
			SoundControl.playCue(SoundControl.start, 1.0) # audio feedback
			SceneManager.goToNewSceneString(Scenes.TUTORIAL1) # Load the first tutorial level
			Data.saveGameData() # save options data
			Globals.currentGameData.set("player_score", 0) # This should be done in LevelManager
			# change bgm and fade on out
			SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm) # begin bgm fade in
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		# Password button
		menuButtons.PASSWORD:
			lastButton = menuButtons.PASSWORD
			SoundControl.playCue(SoundControl.zap, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.PASSWORD)
		
		# Settings button
		menuButtons.SETTINGS:
			lastButton = menuButtons.SETTINGS
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.SETTINGS)
		
		# Exit button
		menuButtons.EXIT:
			Data.saveGameData()
			if !areYouSure: # feedback and warning
				$ExitButton/RollText.speed_scale = 1.0
				areYouSure = true
				$ExitButton/RollText.play("roll_in")
			else: # close program
				get_tree().quit()


# Event handler for when the mouse hovers a menu button
func onButtonMouseEntered(i: int) -> void:
	# Make the button grab_focus
	buttons[i].grab_focus()
	

# Event handler for when a menu button receives focus
func onButtonFocusEntered(i: int) -> void:
	buttons[i].grab_click_focus()
	if areYouSure:
		areYouSureReset()


# Event handler for when Exit button loses focus (useful for confirming user wants to exit)
func onExitButtonFocusExited() -> void:
	if areYouSure: # if are you sure visible, reset
		areYouSureReset()


# Event handler for when mouse un-hovers the Exit button (useful for confirming user wants to exit)
func onExitButtonMouseExited() -> void:
	if areYouSure: # if leaving exit area, reset state
		areYouSureReset()


# Called by the MenuManaget to show the MainMenu
func showMenu() -> void:
	lastButtonFocus()
	self.visible = true


# Called to re-focus the last button used on the MainMenu
func lastButtonFocus() -> void:
	buttons[lastButton].call_deferred("grab_focus")


# Called to hide the MainMenu and reset the value entered
func hideMenu() -> void:
	self.visible = false
