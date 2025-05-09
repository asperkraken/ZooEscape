extends Node2D

@onready var newGamePos := Vector2(272, 240)
@onready var passwordPos := Vector2(272, 264)
@onready var selector := $Selector

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selector.position = newGamePos
	SoundControl.resetMusicFade() ## reset music state
	SceneManager.currentScene = self

# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	# TODO: Tell player that the "ActionButton" is <Z>, etc.
	# NOTE: Had to re-add the "ui_accept" action to allow keyboard use, as <Enter> and <Space> do not work with "ActionButton"
	if event.is_action_pressed("ActionButton"):
		if selector.position == newGamePos:
			SoundControl.playCue(SoundControl.start,1.0)
			SceneManager.GoToNewSceneString(Scenes.ZETutorial1)
			Globals.Game_Globals.set("player_score",0)
			### change bgm and fade on out
			SoundControl.levelChangeSoundCall(1.0,SoundControl.defaultBgm)
		elif selector.position == passwordPos:
			SceneManager.GoToNewSceneString(Scenes.ZEPassword)
			
	if Input.is_action_just_pressed("DigitalDown") || Input.is_action_just_pressed("DigitalUp"):
		swapSelectorPos()


func swapSelectorPos() -> void:
	if selector.position == newGamePos:
		selector.position = passwordPos
	else: 
		selector.position = newGamePos
