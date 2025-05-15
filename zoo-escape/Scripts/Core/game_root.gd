class_name GameRoot extends Node2D

@onready var aniPlayer: AnimationPlayer = $AnimationPlayer
var title = load(Scenes.ZETITLE)
var bgmLevel : float
var sfxLevel : float
var cueLevel : float
var masterLevel : float

func _ready() -> void:
	SceneManager.gameRoot = self
	aniPlayer.play("RESET")
	SoundControl.resetMusicFade() ## reset music state
	Globals.Game_Globals["player_score"] = 0
	bgmLevel = SoundControl.bgmLevel
	sfxLevel = SoundControl.sfxLevel
	cueLevel = SoundControl.cueLevel
	masterLevel = SoundControl.masterLevel


func _process(_delta: float) -> void:
	pass

func GoToNextScene(OldScene: Node, NewScene: PackedScene) -> void:
	# start the Fade out , close processing
	set_process_input(false)
	set_physics_process(false)
	aniPlayer.play("FadeOut")
	await aniPlayer.animation_finished ## wait until animation finish before change
	
	SoundControl.setSoundPreferences(masterLevel,bgmLevel,sfxLevel,cueLevel)
	OldScene.queue_free() # free old scene
	var newCurrentScene := NewScene.instantiate()
	add_child(newCurrentScene) # add new scene
	SceneManager.currentScene = newCurrentScene
	
	aniPlayer.play("FadeIn") ## start animation
	await aniPlayer.animation_finished ## and when it finishes
	set_process_input(true) ## restore processing
	set_physics_process(true)


func ReturnToTitle() -> void:
	set_process_input(false) ## end processing, just like new scene
	set_physics_process(false)
	aniPlayer.play("FadeOut")
	await aniPlayer.animation_finished

	SoundControl.setSoundPreferences(masterLevel,bgmLevel,sfxLevel,cueLevel)
	get_tree().reload_current_scene()

	aniPlayer.play("FadeIn") ## restore processing on animation end
	await aniPlayer.animation_finished
	set_process_input(true)
	set_physics_process(true)
