extends Control

# Signals
signal SetMenu(menu: MenuManager.menuTypes)

# Enums
enum buttonTypes {
	RESUME,
	NEWGAME,
	PASSWORD,
	SETTINGS,
	BACK,
	EXIT
}

# Variables
var areYouSure := false
var lastButton := buttonTypes.NEWGAME

# Handles to child nodes
@onready var bgRect := $Background
@onready var pausedHint := $PausedHint
@onready var buttons: Dictionary[buttonTypes, Button] = {
	buttonTypes.RESUME: $ResumeButton,
	buttonTypes.NEWGAME: $NewGameButton,
	buttonTypes.PASSWORD: $PasswordButton,
	buttonTypes.SETTINGS: $SettingsButton,
	buttonTypes.BACK: $BackButton,
	buttonTypes.EXIT: $ExitButton
}


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# If playing the web version, hide the Exit button
	if OS.get_name() == "Web":
		$ExitButton.hide()
	
	# Connect menu button signals to Event Handlers
	for button in buttons.values():
		button.pressed.connect(onButtonPressed.bind(buttons.find_key(button)))
		button.mouse_entered.connect(onButtonMouseEntered.bind(buttons.find_key(button)))
		button.focus_entered.connect(onButtonFocusEntered.bind(buttons.find_key(button)))
	
	# Focus on the last button to be used in this window (New Game by default)
	lastButtonFocus()

func _input(event: InputEvent) -> void:
	# ONLY detect inputs if MainMenu is visible
	if visible:
		# Only handle single, intentional 'press' events
		if !event.is_pressed() || event.is_echo():
			return
		
		# Hide all menus if a game is running
		if event.is_action("CancelButton"):
			get_viewport().set_input_as_handled() # Mark InputEvent as handled
			if Globals.currentGameData["gameRunning"]:
				onButtonMouseEntered(buttonTypes.RESUME)
				onButtonPressed(buttonTypes.RESUME)
			else:
				onButtonMouseEntered(buttonTypes.EXIT)
				onButtonPressed(buttonTypes.EXIT)


# Reset exit warning state and roll out message
func areYouSureReset():
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


# Event handler for when a menu button is pressed
func onButtonPressed(i: int) -> void:
	#  Determine which button got pressed
	match i as buttonTypes:
		# Resume button
		buttonTypes.RESUME:
			lastButton = buttonTypes.RESUME
			SoundControl.playCue(SoundControl.zap, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.NONE)
			
		# New Game button
		buttonTypes.NEWGAME:
			lastButton = buttonTypes.NEWGAME
			SoundControl.playCue(SoundControl.start, 1.0) # audio feedback
			Data.saveGameData() # save options data
			Globals.currentGameData.set("player_score", 0) # This should be done in LevelManager
			SceneManager.call_deferred("goToNewSceneString", Scenes.TUTORIAL1) # Load the first tutorial level
			# change bgm and fade on out
			SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm) # begin bgm fade in
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		# Password button
		buttonTypes.PASSWORD:
			lastButton = buttonTypes.PASSWORD
			SoundControl.playCue(SoundControl.zap, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.PASSWORD)
		
		# Settings button
		buttonTypes.SETTINGS:
			lastButton = buttonTypes.SETTINGS
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.SETTINGS)
			
		# Back button
		buttonTypes.BACK:
			lastButton = buttonTypes.NEWGAME # Set to NEWGAME since quitting to the title scene
			SoundControl.playCue(SoundControl.down, 1.4)
			Data.saveGameData()
			Globals.currentGameData["gameRunning"] = false
			SceneManager.call_deferred("goToNewSceneString", Scenes.TITLE) # Go to title scene
			SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm) # begin bgm fade in
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		# Exit button
		buttonTypes.EXIT:
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
	

# Event handler for when Exit button loses focus (useful for confirming user wants to exit)
func onExitButtonFocusExited() -> void:
	if areYouSure: # if are you sure visible, reset
		areYouSureReset()


# Event handler for when mouse un-hovers the Exit button (useful for confirming user wants to exit)
func onExitButtonMouseExited() -> void:
	if areYouSure: # if leaving exit area, reset state
		areYouSureReset()


# Called to re-focus the last button used on the MainMenu
func lastButtonFocus() -> void:
	buttons[lastButton].call_deferred("grab_focus")


# Called by the MenuManager to show the MainMenu
func showMenu() -> void:
	if Globals.currentGameData["gameRunning"]: # If a game is running, use all these settings
		bgRect.visible = false
		pausedHint.visible = true
		buttons[buttonTypes.RESUME].visible = true
		buttons[buttonTypes.NEWGAME].visible = false
		buttons[buttonTypes.BACK].visible = true
		buttons[buttonTypes.EXIT].visible = false
		buttons[buttonTypes.PASSWORD].position.y = 224
		buttons[buttonTypes.PASSWORD].focus_neighbor_top = "../ResumeButton"
		buttons[buttonTypes.PASSWORD].focus_previous = "../ResumeButton"
		buttons[buttonTypes.PASSWORD].focus_neighbor_right = ""
		buttons[buttonTypes.SETTINGS].position.y = 264
		buttons[buttonTypes.SETTINGS].focus_neighbor_bottom = "../BackButton"
		buttons[buttonTypes.SETTINGS].focus_next = "../BackButton"
		buttons[buttonTypes.SETTINGS].focus_neighbor_right = ""
		onButtonMouseEntered(buttonTypes.RESUME)
	
	else: # If a game is not running, use all these settings
		bgRect.visible = true
		pausedHint.visible = false
		buttons[buttonTypes.RESUME].visible = false
		buttons[buttonTypes.NEWGAME].visible = true
		buttons[buttonTypes.BACK].visible = false
		buttons[buttonTypes.EXIT].visible = true
		buttons[buttonTypes.PASSWORD].position.y = 264
		buttons[buttonTypes.PASSWORD].focus_neighbor_top = "../NewGameButton"
		buttons[buttonTypes.PASSWORD].focus_previous = "../NewGameButton"
		buttons[buttonTypes.PASSWORD].focus_neighbor_right = "../ExitButton"
		buttons[buttonTypes.SETTINGS].position.y = 304
		buttons[buttonTypes.SETTINGS].focus_neighbor_bottom = "../ExitButton"
		buttons[buttonTypes.SETTINGS].focus_next = "../ExitButton"
		buttons[buttonTypes.SETTINGS].focus_neighbor_right = "../ExitButton"
		if lastButton == buttonTypes.BACK:
			lastButton = buttonTypes.NEWGAME
		lastButtonFocus()
	show()
