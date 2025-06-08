extends CanvasLayer

# Signals
signal RestartGame
signal QuitGame

# Enums
enum menuTypes {
	NONE,
	MAIN,
	PASSWORD,
	SCORES,
	SETTINGS,
	CREDITS,
	TIMEOUT
}

# Variables
var currentMenu: menuTypes = menuTypes.NONE
var menuHeap: Array[menuTypes] = []

# Handles to menus
@onready var menus: Dictionary[menuTypes, Control] = {
	menuTypes.MAIN: $MainMenu,
	menuTypes.PASSWORD: $PasswordMenu,
	menuTypes.SCORES: $ScoresMenu,
	menuTypes.SETTINGS: $SettingsMenu,
	#menuTypes.CREDITS: $CreditsMenu,
	menuTypes.TIMEOUT: $TimeoutWindow
}

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Prevent this Node and its children from being paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect all menu signals
	for menu in menus.values():
		# Connect menu signals to 'setMenu'
		if menu.has_signal("SetMenu"):
			menu.SetMenu.connect(setMenu)
		
		# Connect menu signals to 'goBack'
		if menu.has_signal("GoBack"):
			menu.GoBack.connect(goBack)
		
		if menu.has_signal("RestartGame"):
			menu.RestartGame.connect(func(): RestartGame.emit())
		
		if menu.has_signal("QuitGame"):
			menu.QuitGame.connect(func(): QuitGame.emit())
	
	# Open the MainMenu by default
	if get_tree().current_scene == GameRoot: # This keeps the menu from appearing automatically if running a scene independently.
		setMenu(menuTypes.MAIN)


# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	if !event.is_pressed() || event.is_echo():
		return # Only handle single, intentional 'press' events
	
	if currentMenu == menuTypes.TIMEOUT:
		return # If TimeOut window is showing, exit early and wait for input
	
	# Hide all menus, situationally
	if event.is_action("CancelButton"):
		get_viewport().set_input_as_handled()
		if Globals.currentGameData.gameRunning && currentMenu == menuTypes.NONE:
			setMenu(menuTypes.MAIN) # If a game is running and no menu is open, open MainMenu
		
		if currentMenu != menuTypes.MAIN && currentMenu != menuTypes.NONE:
			goBack() # If a any menu other than MainMenu is open, go back in the menuHeap
	
	# Show/Hide the MainMenu
	if event.is_action("MenuButton"):
		get_viewport().set_input_as_handled()
		if currentMenu != menuTypes.MAIN:
			setMenu(menuTypes.MAIN) # if MainMenu is not open, open it
		
		elif Globals.currentGameData.gameRunning:
			setMenu(menuTypes.NONE) # If MainMenu is open and a game is running, close it
	
	# Show/Hide the PasswordMenu
	if event.is_action("PasswordButton"):
		get_viewport().set_input_as_handled()
		if currentMenu != menuTypes.PASSWORD:
			setMenu(menuTypes.PASSWORD) # If PasswordMenu is not open, open it
		
		else:
			goBack() # If PasswordMenu is open, go back in the menuHeap
	
	# Show/Hide the SettingsMenu
	elif event.is_action("SettingsButton"):
		get_viewport().set_input_as_handled()
		if currentMenu != menuTypes.SETTINGS: # If SettingsMenu is not open, open it
			setMenu(menuTypes.SETTINGS)
		
		else:
			goBack() # If SettingsMenu is open, go back in the menuHeap


# Called to switch menus
func switchMenu() -> void:
	# Hide all menus
	hideMenus()
	
	# Open the correct menu
	if currentMenu != menuTypes.NONE:
		var menu = menus[currentMenu]
		if menu && menu.has_method("showMenu"):
			menu.showMenu()
		else:
			setMenu(menuTypes.MAIN)
		
	# If no menu is showing, unpause the game
	if currentMenu == menuTypes.NONE:
		get_tree().paused = false
	
	# If any menu is showing, pause the game
	else:
		get_tree().paused = true


# Called to hide all menus
func hideMenus() -> void:
	for menu in menus.values():
			menu.hide()


# Called by all functions everywhere to change menus
func setMenu(newMenu: menuTypes) -> void:
	# Check newMenu against various scenarios
	match newMenu:
		menuTypes.NONE: # If requested menu is NONE, close all menus
			menuHeap.clear()
			currentMenu = menuTypes.NONE
			switchMenu()
			return
		
		currentMenu: # If requested menu is same as current menu, do nothing
			return
		
		menuTypes.MAIN: # If requested menu is MAIN, clear the heap
			menuHeap.clear()
	
	# If newMenu is in the heap, remove all elements on the top of the array
	if menuHeap.has(newMenu):
		while menuHeap.has(newMenu):
			menuHeap.pop_back()
	
	# Finally, open the requested menu
	menuHeap.push_back(newMenu)
	currentMenu = newMenu
	switchMenu()


# Called to reverse the menuHeap (useful for when ESC is used to close menus)
func goBack() -> void:
	if menuHeap.size() > 1:  # Ensure there's a previous menu to go back to
		menuHeap.pop_back()  # Remove the current menu
		currentMenu = menuHeap.back()  # Set currentMenu to the last menu in the heap
		switchMenu()
	else:
		if !Globals.currentGameData.gameRunning:
			setMenu(menuTypes.MAIN)
			return
		setMenu(menuTypes.NONE)  # If no previous menu, close all menus


# Called by LevelManager to update password string on TimeoutWindow when new level loads
func updatePassword(levelCode) -> void:
	menus[menuTypes.TIMEOUT].updatePassword(levelCode)


func enableHighScores(yesno: bool) -> void:
	menus[menuTypes.MAIN].enableHighScores(yesno)
