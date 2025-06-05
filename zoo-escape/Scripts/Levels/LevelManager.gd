class_name LevelManager extends Node2D


enum processingStates {
	NONE,
	IDLE,
	PREP,
	TIME,
	MOVES
}

@export var levelCode := "----" # stores as password
@export var timeLimit := 60 # level time limit relayed to hud
@export var warningTime := 15 # time out warning threshold
@export var exitBonus := 500 # points for winning the level
@export var timeBonus := 100 # bonus points per second remaining on the clock
@export var movePenalty := 25 # penalty for every move made
@export var isLevelTutorial := false # Is this a tutorial level?
@export var levelBgm := "res://Assets/Sound/Theme.ogg" # Background music for this level

var hud: Hud = preload(Scenes.HUD).instantiate() # instantiate a new hud when this level is initialized
var processDelay := 0.15 # how long to wait between rounds of time and move processing (should be around 0.15)
var elapsedTime := 0.0 # how long the level has been running (a level timer)
var timeLeft := 0 # how long before this level times out (rounded to nearest second)
var resetTime := 0.0 # how long the player has held the "RightBumper" action
var timesUp := false # has the level's time run out?
var hasPlayerMoved := false # has the player moved yet?
var score := 0 # the player's score for this level
var moveCount := 0 # number of moves player has made this level
var steakCount := 0 # number of steaks present in the level
var processingState := processingStates.IDLE

@onready var player := $Player # Handle to the player
@onready var exitTile := $ExitTile # Handle to the exitTile
@onready var nextLevel: String = exitTile.nextLevelCode # pointer for next scene string


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE # Allow the LevelManager to be paused when the scene tree is paused
	SceneManager.currentScene = self
	add_to_group("LevelManager")
	MenuManager.updatePassword(levelCode)
	MenuManager.RestartGame.connect(restartRoom)
	MenuManager.QuitGame.connect(quitGame)
	player.InWater.connect(restartRoom)
	player.PlayerMoved.connect(updateMoveCount)
	exitTile.PlayerExits.connect(exitLevel)
	
	# Set currentGameData in Globals
	if !Globals.currentGameData.gameRunning:
		Globals.currentGameData.gameRunning = true # Critical for MenuManager to work as intended in-game
		Globals.currentGameData.playerScore = 0 # Reset the carry-over score if a game was not running (usually after quitting a previous game)
	score = Globals.currentGameData.playerScore # If there's a carry-over score, set score to that (or 0 if not)
	
	setupSteaks()
	setupHud()
	
	if isLevelTutorial:
		player.showMoveThought() # Show tutorial bubble if in tutorial stage
	
	# check to ensure bgm fade level is consistent
	# if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME or SoundControl.currentBgm != levelBgm:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match processingState:
		# If done processing, exit early (wait for other processes to finish)
		processingStates.NONE:
			return
		
		# Normal level logic
		processingStates.IDLE:
			if hasPlayerMoved && !timesUp && !isLevelTutorial: # The player has moved but still has time, so do things!
				elapsedTime += delta
				timeLeft = roundi(timeLimit - elapsedTime) # Calculate how much time is left, and update the HUD
				hud.updateTimeText(timeLeft) # If we're not playing a tutorial, update the time
					
				if timeLeft <= warningTime && timeLeft % 2 == 0: # If the remaining time is less than warning time, give warnings
					hud.giveTimeWarning()
				
				if elapsedTime >= timeLimit: # If elapsedTime is greater than timeLimit, time's up!
					timesUp = true
				
			elif timesUp: # If time has run out, change processing mode and display Timeout window
				processingState = processingStates.NONE
				#hud.outOfTime()
				hud.closeHud()
				MenuManager.setMenu(MenuManager.menuTypes.TIMEOUT)
			
			# If player just released "RightBumper," reset resetTime and hide resetBar
			if Input.is_action_just_released("RightBumper"):
				resetTime = 0
				hud.resetBarFade()
			
			# If player is pressing "RightBumper," show resetBar and update its value
			if Input.is_action_pressed("RightBumper") and !timesUp: # do not allow reload when time up!
				resetTime += delta
				hud.resetBarReveal()
				hud.resetBarUpdate(resetTime)
			
			# If resetTime has been met, reset the level
			if resetTime >= 2:
				processingState = processingStates.NONE
				timesUp = true
				SoundControl.playCue(SoundControl.down, 2.0)
				hud.resetPrompt() # Update restartBar prompt on HUD
				restartRoom()
		
		# Prepare to process TIME and MOVES
		processingStates.PREP:
			timeLimit -= roundi(elapsedTime)
			updateScore(exitBonus) # Apply exitBonus score and save score to Globals
			Globals.currentGameData.playerScore = score
			if !isLevelTutorial:
				processingState = processingStates.TIME # If playing regular level, process TIME and MOVES
			else:
				processingState = processingStates.NONE # if playing tutorial, wait for the next level to load
				await get_tree().create_timer(processDelay * 10).timeout # Small delay before going to the next level
				loadNextLevel()
				
		
		# Add bonus points for remaining time
		processingStates.TIME:
			if timeLimit > 0: # timer adds bonus until zero
				timeLimit -= 1
				updateScore(timeBonus) # Adding bonus
				hud.updateTimeText(timeLimit)
				await get_tree().create_timer(processDelay).timeout # Create a small delay to visually count down
				return
			else:
				processingState = processingStates.MOVES # When done processing TIME, process MOVES
		
		# Subtract moveCount penalties from the score
		processingStates.MOVES:
			if moveCount > 0:
				moveCount -= 1
				updateScore(-movePenalty) # Subtracting penalty
				hud.updateMovesText(moveCount)
				await get_tree().create_timer(processDelay).timeout # Create a small delay to visually count down
				return
			else:
				Globals.currentGameData.playerScore = score # Update the carry-over score in Globals
				processingState = processingStates.NONE # When done processing MOVES, wait for next level to load
				await get_tree().create_timer(processDelay * 10).timeout # Small delay before going to the next level
				loadNextLevel() # Load the next level


# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	if !hasPlayerMoved: # If the player hasn't moved, listen for moves, as this triggers the elapsedTime counter to begin
		if event.is_action("DigitalUp") || event.is_action("DigitalDown") || event.is_action("DigitalLeft") || event.is_action("DigitalRight"):
			hasPlayerMoved = true
			startLevel()


# Initialize the HUD for this level
func setupHud() -> void:
	# Setup initial values on HUD
	hud.updateScoreText(score)
	hud.updatePasswordText(levelCode)
	hud.updateSteaksText(steakCount)
	hud.updateMovesText(moveCount)
	add_child(hud)


# Called to play some animations on the HUD when the player first moves (indicating level has begun)
func startLevel() -> void:
	if !isLevelTutorial:
		hud.playTimerStart() # If playing a regular level, set time value to "START" and play an icon animation
	else:
		hud.setTutorialText() # If playing a tutorial level, set the TimeValue text to "NONE"


# Updates the score with the provided value (can be positive or negative)
func updateScore(value) -> void:
	score += value
	if score < 0: # Score will not fall below zero
		score = 0
	hud.updateScoreText(score)


# Updates the moveCount variable
func updateMoveCount() -> void:
	moveCount += 1 # Update the move counter
	hud.updateMovesText(moveCount)


# Updates the steaksCollected variable
func steakCollected(value: int) -> void:
	steakCount -= 1
	hud.updateSteaksText(steakCount)
	updateScore(value)
	
	if steakCount <= 0: # If steakCount dropped to 0, activate the exitTile
		exitTile.activateExit()


# When a level loads count all steaks
func setupSteaks() -> void:
	var steaks := findChildrenInGroup("steaks")
	if steaks:
		steakCount = steaks.size()
		for steak: Steak in steaks:
			steak.Collected.connect(steakCollected)


# Find all children in a given group
func findChildrenInGroup(group := "", which: Node = self, arr := []) -> Array:
	for child in which.get_children():
		if child.is_in_group(group):
			arr.push_back(child)
		
		# If the child has children, see if that child has nodes in the group
		if child.get_children().size() >= 1:
			arr = findChildrenInGroup(group, child, arr)
	
	return arr


# Exit the level function - hold player, process score then go to next room
func exitLevel() -> void:
	player.currentState = player.playerState.ONEXIT
	SoundControl.playCue(SoundControl.success, 2.0) # sound trigger
	processingState = processingStates.PREP


# Load the next level
func loadNextLevel() -> void:
	hud.closeHud()
	if nextLevel != Globals.PASSWORDS.find_key(Scenes.TITLE):
		SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[nextLevel])
	else:
		quitGame()


# Function to close hud
func restartRoom() -> void:
	hud.closeHud()
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[levelCode])


# Game quit function, returns to title scene
func quitGame() -> void:
	Data.saveGameData()
	hud.closeHud()
	Globals.currentGameData.gameRunning = false
	SceneManager.call_deferred("goToNewSceneString", Scenes.TITLE)
