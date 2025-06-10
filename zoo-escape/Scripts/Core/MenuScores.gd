extends Panel

# Signals
signal SetMenu(menu: MenuManager.menuTypes)
signal GoBack

# Enums
enum buttonTypes {
	CLOSE,
	PREV,
	NEXT,
	PLAY
}

enum starTypes {
	GOLD,
	SILVER,
	BRONZE
}

const STARS := {
	starTypes.GOLD: preload("res://Assets/Images/Icons/StarGold32.png"),
	starTypes.SILVER: preload("res://Assets/Images/Icons/StarSilver32.png"),
	starTypes.BRONZE: preload("res://Assets/Images/Icons/StarBronze32.png")
}

var scoreIndex := 0
var key := "9990"
var highScoresSize := Globals.highScores.size()

@onready var levelName := $Margin/Info/Header/LevelName
@onready var levelPass := $Margin/Info/Header/LevelCode
@onready var thresholds := [ $Margin/Info/Header/Thresholds/Gold/Label, $Margin/Info/Header/Thresholds/Silver/Label, $Margin/Info/Header/Thresholds/Bronze/Label ]
@onready var scoreLabels: Array[Label] = [ $Margin/Info/Scores/Data/ScoreTxt1, $Margin/Info/Scores/Data/ScoreTxt2, $Margin/Info/Scores/Data/ScoreTxt3 ]
@onready var moveBoxes: Array[Label] = [ $Margin/Info/Scores/Data/Moves1, $Margin/Info/Scores/Data/Moves2, $Margin/Info/Scores/Data/Moves3 ]
@onready var timeBoxes: Array[Label] = [ $Margin/Info/Scores/Data/Time1, $Margin/Info/Scores/Data/Time2, $Margin/Info/Scores/Data/Time3 ]
@onready var scoreBoxes: Array[Label] = [ $Margin/Info/Scores/Data/Score1, $Margin/Info/Scores/Data/Score2, $Margin/Info/Scores/Data/Score3 ]
@onready var ratingBoxes: Array[TextureRect] = [ $Margin/Info/Scores/Data/Rating1, $Margin/Info/Scores/Data/Rating2, $Margin/Info/Scores/Data/Rating3 ]
@onready var buttons := {
	buttonTypes.CLOSE: $Margin/CloseButton,
	buttonTypes.PREV: $Margin/PrevButton,
	buttonTypes.NEXT: $Margin/NextButton,
	buttonTypes.PLAY: $Margin/PlayButton,
}


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Connect button signals to Event Handlers
	for button in buttons.values():
		button.pressed.connect(onButtonPressed.bind(buttons.find_key(button)))
		button.mouse_entered.connect(onButtonMouseEntered.bind(buttons.find_key(button)))
		button.focus_entered.connect(onButtonFocusEntered.bind(buttons.find_key(button)))


func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("DigitalRight"):
			if !buttons[buttonTypes.NEXT].disabled: # If NextButton not disabled, focus and press it
				buttons[buttonTypes.NEXT].call_deferred("grab_focus")
				onButtonPressed(buttonTypes.NEXT)
				if buttons[buttonTypes.NEXT].disabled: # If NextButton now disabled, focus PrevButton
					buttons[buttonTypes.PREV].call_deferred("grab_focus")
		
		if event.is_action_pressed("DigitalLeft"):
			if !buttons[buttonTypes.PREV].disabled: # If PrevButton not disabled, focus and press it
				buttons[buttonTypes.PREV].call_deferred("grab_focus")
				onButtonPressed(buttonTypes.PREV)
				if buttons[buttonTypes.PREV].disabled: # If PrevButton now disabled, focus NextButton
					buttons[buttonTypes.NEXT].call_deferred("grab_focus")


# Called to retrieve score data
func getScoreData() -> void:
	if !Globals.highScores.is_empty():
		highScoresSize = Globals.highScores.size()
		key = Globals.highScores.keys()[scoreIndex]
		var lName = Globals.LEVELNAMES[key]
		var tHolds = Globals.THRESHOLDS[key].duplicate()
		var hScores = Globals.highScores[key]
		
		if lName.is_empty() || tHolds.is_empty() || hScores.is_empty():
			return # If required data is missing, exit early
		resetWindow()
		levelName.text = lName
		levelPass.text = "Password: " + key
		
		# Set the threshold labels
		tHolds.sort() # Sort and reverse thresholds to ensure ordered from greatest to least
		tHolds.reverse()
		for i: int in tHolds.size():
			if tHolds[i] == 0: # If threshold is 0, leave the text reset
				continue
			thresholds[i].text = str(tHolds[i]) # [ Gold, Silver, Bronze ]
		
		# Set the score-related labels/textures
		for i: int in hScores.size(): # [ [ score, time, moves ], ... ]
			scoreBoxes[i].text = str(hScores[i][0]) # Set score text
			moveBoxes[i].text = str(hScores[i][2]) # Set moves text
			timeBoxes[i].text = str(hScores[i][1]) # Set time text
			
			# Set rating texture
			if hScores[i][0] >= tHolds[0]:
				ratingBoxes[i].texture = STARS[starTypes.GOLD]
			elif hScores[i][0] >= tHolds[1]:
				ratingBoxes[i].texture = STARS[starTypes.SILVER]
			elif hScores[i][0] >= tHolds[2]:
				ratingBoxes[i].texture = STARS[starTypes.BRONZE]
			else:
				ratingBoxes[i].texture = null
			
		toggleButtons()


# Called by the MenuManager to show this window
func showMenu() -> void:
	getScoreData() # Update variables and retrieve the first set of score data
	show()


# Called to return to the last menu
func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	GoBack.emit() # Bye!


# Called to reset the window text to default values
func resetWindow() -> void:
	levelName.text = "Unnamed Level"
	levelPass.text = "Password: ----"
	for tHold in thresholds:
		tHold.text = "--"
	for mBox in moveBoxes:
		mBox.text = "--"
	for tBox in timeBoxes:
		tBox.text = "--"
	for sBox in scoreBoxes:
		sBox.text = "--"
	for rBox in ratingBoxes:
		rBox.texture = null


# Called to enable/disable NextButton / PrevButton when appropriate
func toggleButtons() -> void:
	var isFirst = scoreIndex == 0
	var isLast = scoreIndex == highScoresSize - 1
	var isSingle = highScoresSize == 1
	var nextNeighbor = "../NextButton"
	var prevNeighbor = "../PrevButton"

	# Enable/disable buttons
	buttons[buttonTypes.PREV].disabled = isSingle || isFirst
	buttons[buttonTypes.NEXT].disabled = isSingle || isLast

	# Set focus neighbors
	if isLast:
		nextNeighbor = "../PrevButton"
	if isFirst:
		prevNeighbor = "../NextButton"

	buttons[buttonTypes.NEXT].focus_neighbor_left = prevNeighbor
	buttons[buttonTypes.PREV].focus_neighbor_right = nextNeighbor
	if isSingle:
		buttons[buttonTypes.PLAY].focus_neighbor_top = "../CloseButton"
		buttons[buttonTypes.CLOSE].focus_neighbor_bottom = "../PlayButton"
	else:
		buttons[buttonTypes.PLAY].focus_neighbor_top = nextNeighbor
		buttons[buttonTypes.CLOSE].focus_neighbor_bottom = nextNeighbor

	# Set focus
	if isSingle:
		buttons[buttonTypes.PLAY].call_deferred("grab_focus")
	elif isFirst:
		buttons[buttonTypes.NEXT].call_deferred("grab_focus")


# Called when a button is pressed
func onButtonPressed(btn: int) -> void:
	match btn as buttonTypes:
		buttonTypes.NEXT, buttonTypes.PREV:
			if (btn == buttonTypes.NEXT && scoreIndex < highScoresSize - 1) || (btn == buttonTypes.PREV && scoreIndex > 0):
				scoreIndex += 1 if btn == buttonTypes.NEXT else -1
				SoundControl.playCue(SoundControl.blip, 1.0)
				getScoreData()

		buttonTypes.PLAY:
			SoundControl.playCue(SoundControl.start, 1.0)
			SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[key])
			SetMenu.emit(MenuManager.menuTypes.NONE)
			
		buttonTypes.CLOSE:
			returnToLastMenu()


# Event handler for when the mouse hovers a menu button
func onButtonMouseEntered(i: int) -> void:
	# Make the button grab_focus
	buttons[i].grab_focus()


# Event handler for when a menu button receives focus
func onButtonFocusEntered(i: int) -> void:
	buttons[i].grab_click_focus()
