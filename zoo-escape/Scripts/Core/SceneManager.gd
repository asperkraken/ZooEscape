extends Node


var gameRoot: GameRoot # This is set by gameroot when it is ready
var currentScene: Node # This is set by the level manager when it is ready

# this takes a loaded scene as argument and unpauses the tree
func goToNewScenePacked(newScene: PackedScene) -> void:
	
	# Switch the scenes
	gameRoot.goToNextScene(currentScene, newScene)
	get_tree().paused = false # Make sure the scene tree is unpaused for the next level to load in properly


# this takes a filename/string as argument and loads it with the previous function
func goToNewSceneString(newScene: String) -> void:
	# TODO: add error checking
	var scene: Resource = load(newScene)
	goToNewScenePacked(scene)
