class_name ZELevelManager extends Node2D

@export var LevelCode: String = ""
@onready var player := $Player
@onready var resetTime := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## check to ensure bgm fade level is consistent
	## if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("RightBumper"):
		resetTime += delta
	
	if Input.is_action_just_released("RightBumper"):
		resetTime = 0

	if resetTime > 2:
		resetTime = 0
		restartRoom()

func _on_exit_tile_player_exits(LevelToGoTo: String) -> void:
	SoundControl.playCue(SoundControl.success,2.0)
	player.currentState = player.PlayerState.OnExit
	SceneManager.call_deferred("GoToNewSceneString",self, Globals.Game_Globals[LevelToGoTo])


func _on_steak_manager_all_steak_collected() -> void:
	$ExitTile.ActavateExit()


func restartRoom() -> void:
	SoundControl.playCue(SoundControl.fail,3.0) ## game over noise
	SceneManager.call_deferred("GoToNewSceneString",self, Globals.Game_Globals[LevelCode])


func _exitGame() -> void:
	var _root = get_parent()
	_root.ReturnToTitle()


func _on_player_in_water() -> void:
	restartRoom()
