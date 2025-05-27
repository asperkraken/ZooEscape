extends Node2D


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Tell the SceneManager that I am the current scene
	SceneManager.currentScene = self
	
	# Tell the MenuManager to display the MainMenu
	MenuManager.setMenu(MenuManager.menuTypes.MAIN)
