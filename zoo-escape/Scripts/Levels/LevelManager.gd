class_name LevelManager extends Node2D

@export var levelCode := "" # stores as password
@export var levelTime := 60 # level time limit relayed to hud
@export var warningTime := 15 # time out warning threshold
@export var exitScoreBonus := 500 # local editor variables to effect bonuses
@export var perSecondBonus := 100
@export var perMovePenalty := 25
@export var tutorialScoreBypass := false
@onready var player := $Player
@onready var exitTile := $ExitTile
@onready var resetTime := 0.0
@onready var nextLevel: String = exitTile.nextLevelCode # pointer for next scene string
var loadingScore: int = Globals.currentGameData.get("player_score") # compare score for reloads
var localHud = null # pointer for hud
var timeUp := false # to monitor local hud timer
var steakCount := 0
@export var levelBgm := "res://Assets/Sound/Theme.ogg"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.currentScene = self
	Globals.currentGameData["gameRunning"] = true # A game is now running.  It's official!
	self.process_mode = Node.PROCESS_MODE_PAUSABLE # Allow the LevelManager to be paused when the scene tree is paused
	self.add_to_group("LevelManager")
	player.InWater.connect(restartRoom)
	player.PlayerMoved.connect(updateMoveCount)
	
	if tutorialScoreBypass: ## show tutorial bubble if in tutorial stage
		player.showMoveThought()
	
	exitTile.PlayerExits.connect(exitLevel)
	setupSteaks()
	hudFetch()
	
	# check to ensure bgm fade level is consistent
	# if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME or SoundControl.currentBgm != levelBgm:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER


# this function grabs the hud elements and adds them to the level
func hudFetch() -> void:
	localHud = load(Scenes.HUD).instantiate()
	localHud.RestartRoom.connect(restartRoom)
	localHud.ExitGame.connect(exitGame)
	localHud.ScoreProcessed.connect(nextRoom)
	# update global data report and local UI visual feedback
	localHud.timeLimit = levelTime
	localHud.warningTime = warningTime
	localHud.timerValue = levelTime
	localHud.secondBonus = perSecondBonus
	localHud.movePenalty = perMovePenalty
	localHud.passwordReport(levelCode)
	localHud.tutorialMode = tutorialScoreBypass
	localHud.steakValue = steakCount
	
	self.add_child(localHud)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if localHud != null:
		timeUp = localHud.timesUp # watch timer
		localHud.resetGauge = resetTime # compare gauge with HUD meter
		localHud.password = str(levelCode) # update hud password text
	
	if Input.is_action_pressed("RightBumper") and !timeUp:
		resetTime += delta # do not allow reload when time up!
		if !localHud.resetBarVisible: # show bar
			localHud.resetBarReveal()
	
	if Input.is_action_just_released("RightBumper"):
		resetTime = 0 # fade bar and reset
		if localHud != null: # check for bar before call or errors
			if localHud.resetBarVisible:
				localHud.resetBarFade()
	
	if resetTime > 2:
		resetTime = -10 # added to avoid crash from input overload
		timeUp = true # flip cursor to avoid retriggering
		SoundControl.playCue(SoundControl.down, 2.0)
		localHud.resetPrompt() # prompt updates on hud
		restartRoom()


# exit the level function - hold player, process score then go to next room
func exitLevel() -> void:
	player.currentState = player.playerState.ONEXIT
	SoundControl.playCue(SoundControl.success, 2.0) # sound trigger
	if !tutorialScoreBypass: # process score before exit
		localHud.scoreProcessState = Hud.SCORE_PROCESS_STATES.TIME_PROCESS
	else: # if tutorial, do not apply score bonuses/penalties
		nextRoom()


# load next level and free previous hud elements
func nextRoom() -> void:
	if nextLevel != "9990":
		hudClosing()
		SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[nextLevel])
	else:
		exitGame()


# this function is to free hud elements or they will not overlay or place correctly
# and to prevent stack overflow of hud scenes
func hudClosing() -> void:
	localHud.queue_free()


# update score and apply exit score and bonus
func allSteaksCollected() -> void:
	exitTile.activateExit()
	Globals.scoreUpdate(exitScoreBonus, true)
	localHud.steakWiggle() ## call for steak collected animation from hud


# function to close hud and compare original score before reloading the level
func restartRoom() -> void:
	localHud.closeHud()
	var _score : int = Globals.currentGameData.get("player_score")
	if _score != loadingScore: ## load score from first level boot
		Globals.currentGameData.set("player_score", loadingScore)
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[levelCode])
	get_tree().paused = false ## double check to make sure tree is not paused or load error


# game exit function, returns to title after cleaming out hud
func exitGame() -> void:
	hudClosing()
	Data.saveGameData()
	Globals.currentGameData["gameRunning"] = false
	SceneManager.call_deferred("goToNewSceneString", Scenes.TITLE)


# updates the move count on the hud
func updateMoveCount() -> void:
	localHud.movesValue += 1


# updaes the stake counter on the hud
func steakCollected() -> void:
	steakCount -= 1
	localHud.steakValue = steakCount
	
	if steakCount == 0:
		allSteaksCollected()


# when a level loads count all steaks
func setupSteaks() -> void:
	var steaks := findChildrenInGroup("steaks")
	if steaks:
		steakCount = steaks.size()
		for steak: Steak in steaks:
			steak.Collected.connect(steakCollected)


# find all children in a given group
func findChildrenInGroup(group := "", which: Node = self, arr := []) -> Array:
	for child in which.get_children():
		if child.is_in_group(group):
			arr.push_back(child)
		
		# If the child has children, see if that child has nodes in the group
		if child.get_children().size() >= 1:
			arr = findChildrenInGroup(group, child, arr)
	
	return arr
