extends Node2D


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Tell the SceneManager that I am the current scene
	SceneManager.currentScene = self
	
	# Tell the MenuManager to display the MainMenu
	MenuManager.setMenu(MenuManager.menuTypes.MAIN)
	
	# Load saved game data
	# TODO: Move this to Data.gd in _ready()
	Data.loadData()
	
	# set global sound
	# TODO: Move this to SoundControl.gd in _ready()
	if !AudioServer.is_bus_mute(3) and SoundControl.bgmLevel > -20:
		SoundControl.resetMusicFade() # reset music state
