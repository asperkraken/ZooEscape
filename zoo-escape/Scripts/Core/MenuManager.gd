extends CanvasLayer

# Window BG Color: #61407A
# Window Border Color: #8F3DA7

# Enums
enum menuTypes {
	NONE,
	MAIN,
	PASSWORD,
	SETTINGS
}

# Variables
var currentMenu := menuTypes.NONE
var lastMenu := menuTypes.NONE
var menuOpen := false

# Handles to menus
@onready var main := $MainMenu
@onready var password := $PasswordMenu
@onready var settings := $SettingsMenu


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Prevent this Node and its children from being paused
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	main.SetMenu.connect(setMenu)
	password.SetMenu.connect(setMenu)
	#settings.SetMenu.connect(setMenu) # TODO: Add signal and emission to settings menu
	switchMenus()


# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	# Hide/Show the Password Menu
	if event.is_action_pressed("MenuButton"):
		# Mark InputEvent as handled so it only triggers once
		get_viewport().set_input_as_handled()
		if currentMenu == menuTypes.MAIN: # If MainMenu open...
			if Globals.currentAppState.gameRunning: # If a game is running, set the menu to NONE
				setMenu(menuTypes.NONE)
			else: # If game not running, set menu to MainMenu to prevent closing
				setMenu(menuTypes.MAIN)
		else: # If MainMenu not open, open it
			setMenu(menuTypes.MAIN)
	
	# Hide/Show the Password Menu
	if event.is_action_pressed("PasswordButton"):
		# Mark InputEvent as handled so it only triggers once
		get_viewport().set_input_as_handled()
		if currentMenu == menuTypes.PASSWORD:
			setMenu(lastMenu)
		else:
			setMenu(menuTypes.PASSWORD)
	
	# Hide/Show the Settings Menu
	elif event.is_action_pressed("SettingsButton"):
		# Mark InputEvent as handled so it only triggers once
		get_viewport().set_input_as_handled()
		if currentMenu == menuTypes.SETTINGS:
			setMenu(lastMenu)
		else:
			setMenu(menuTypes.SETTINGS)


# Called to switch menus
func switchMenus() -> void:
	match currentMenu:
		# Hide all menus
		menuTypes.NONE:
			main.hideMenu()
			password.hideMenu()
			settings.visible = false # TODO: Make showMenu and hideMenu functions for settings
		# Show main menu
		menuTypes.MAIN:
			main.showMenu()
			password.hideMenu()
			settings.visible = false # TODO: Make showMenu and hideMenu functions for settings
		# Show password menu
		menuTypes.PASSWORD:
			main.hideMenu()
			password.showMenu()
			settings.visible = false # TODO: Make showMenu and hideMenu functions for settings
		# Show settings menu
		menuTypes.SETTINGS:
			main.hideMenu()
			password.hideMenu()
			settings.visible = true # TODO: Make showMenu and hideMenu functions for settings
	
	# If no menu is showing, unpause the game
	if currentMenu == menuTypes.NONE:
		get_tree().paused = false
	# If any menu is showing, pause the game
	else:
		get_tree().paused = true

func setMenu(newMenu: menuTypes) -> void:
	lastMenu = currentMenu
	currentMenu = newMenu
	switchMenus()
