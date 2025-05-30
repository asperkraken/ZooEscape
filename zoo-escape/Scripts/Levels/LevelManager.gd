class_name LevelManager extends Node2D


@export var levelCode := "----" # stores as password
@export var levelTime := 60 # level time limit relayed to hud
@export var warningTime := 15 # time out warning threshold
@export var exitScoreBonus := 500 # points for winning the level
@export var perSecondBonus := 100 # bonus points per second remaining on the clock
@export var perMovePenalty := 25 # penalty for every move made
@export var isLevelTutorial := false # Is this a tutorial level?
@export var levelBgm := "res://Assets/Sound/Theme.ogg" # Background music for this level

var hud: Hud = preload(Scenes.HUD).instantiate() # instantiate a new hud when this level is initialized
var loadingScore: int = Globals.currentGameData["playerScore"] # compare score for reloads
var elapsedTime := 0.0 # how long the level has been running (a level timer)
var resetTime := 0.0 # time counter until level reload is triggered (increases when "RightBumper" held)
var timesUp := false # has the level's time run out?
var hasPlayerMoved := false
var score := 0 # the player's score this level
var moveCount := 0 # number of moves player has made this level
var steakCount := 0 # number of steaks present in the level

@onready var player := $Player # Handle to the player
@onready var exitTile := $ExitTile
@onready var nextLevel: String = exitTile.nextLevelCode # pointer for next scene string


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.currentScene = self
	Globals.currentGameData["gameRunning"] = true # A game is now running.  It's official!
	self.process_mode = Node.PROCESS_MODE_PAUSABLE # Allow the LevelManager to be paused when the scene tree is paused
	self.add_to_group("LevelManager")
	player.InWater.connect(restartRoom)
	player.PlayerMoved.connect(updateMoveCount)
	
	if isLevelTutorial:
		player.showMoveThought() # show tutorial bubble if in tutorial stage
	
	exitTile.PlayerExits.connect(exitLevel)
	setupSteaks()
	setupHud()
	
	# check to ensure bgm fade level is consistent
	# if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME or SoundControl.currentBgm != levelBgm:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hasPlayerMoved && !timesUp: # The player has moved but still has time, so do things!
		elapsedTime += delta
		hud.updateTimeText(roundi(levelTime - elapsedTime))
		if elapsedTime >= levelTime:
			timesUp = true
		
	elif timesUp:
		# TODO: Process scoring goes here
		pass


	if Input.is_action_pressed("RightBumper") and !timesUp:
		resetTime += delta # do not allow reload when time up!
		if hud:
			timesUp = hud.timesUp # watch timer
			hud.resetGauge = resetTime # compare gauge with HUD meter
			hud.resetBarReveal()
	
	if Input.is_action_just_released("RightBumper"):
		resetTime = 0 # fade bar and reset
		if hud: # check for bar before call or errors
			hud.resetBarFade()
	
	if resetTime > 2:
		resetTime = -10 # added to avoid crash from input overload
		timesUp = true # flip cursor to avoid retriggering
		SoundControl.playCue(SoundControl.down, 2.0)
		hud.resetPrompt() # prompt updates on hud
		restartRoom()


# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	if !hasPlayerMoved: # If the player hasn't moved, listen for moves, as this triggers the elapsedTime counter to begin
		if event.is_action("DigitalUp") || event.is_action("DigitalUp") || event.is_action("DigitalUp") || event.is_action("DigitalUp"):
			hasPlayerMoved = true



# this function grabs the hud elements and adds them to the level
func setupHud() -> void:
	# Connect HUD signals to LevelManager functions
	hud.RestartRoom.connect(restartRoom)
	hud.ExitGame.connect(exitGame)
	hud.ScoreProcessed.connect(nextRoom)
	# Setup initial values on HUD
	hud.updateScoreText(score)
	hud.updateTimeText(levelTime) # update the hud time display
	hud.updatePasswordText(levelCode) # update hud password text
	hud.tutorialMode = isLevelTutorial
	add_child(hud)


# exit the level function - hold player, process score then go to next room
func exitLevel() -> void:
	player.currentState = player.playerState.ONEXIT
	SoundControl.playCue(SoundControl.success, 2.0) # sound trigger
	if !isLevelTutorial: # process score before exit
		hud.scoreProcessState = hud.SCORE_PROCESS_STATES.TIME_PROCESS
	else: # if tutorial, do not apply score bonuses/penalties
		nextRoom()


# load next level and free previous hud elements
func nextRoom() -> void:
	if nextLevel != "9990":
		SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[nextLevel])
	else:
		exitGame()


# update score and apply exit score and bonus
func allSteaksCollected() -> void:
	exitTile.activateExit()
	hud.steakWiggle() # call for steak collected animation from hud


# function to close hud and compare original score before reloading the level
func restartRoom() -> void:
	hud.closeHud()
	if Globals.currentGameData["playerScore"] != loadingScore: # load score from first level boot
		Globals.currentGameData["playerScore"] = loadingScore
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[levelCode])
	get_tree().paused = false ## double check to make sure tree is not paused or load error


# game exit function, returns to title after cleaming out hud
func exitGame() -> void:
	Data.saveGameData()
	Globals.currentGameData["gameRunning"] = false
	SceneManager.call_deferred("goToNewSceneString", Scenes.TITLE)

func updateScore(value) -> void:
	score += value
	if score < 0:
		score = 0
	hud.updateScoreText(score)

# Updates the moveCount variable
func upateMoveCount() -> void:
	moveCount += 1
	hud.updateMovesText(moveCount)


# Updates the steaksCollected variable
func steakCollected() -> void:
	steakCount -= 1
	hud.updateSteaksText(steakCount)
	
	if steakCount <= 0:
		allSteaksCollected()


# when a level loads count all steaks
func setupSteaks() -> void:
	var steaks := findChildrenInGroup("steaks")
	if steaks:
		Globals.currentGameData["steakCount"] = steaks.size()
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
