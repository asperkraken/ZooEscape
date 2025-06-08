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

const STARS := {
	"GOLD": "res://Assets/Images/Icons/StarGold32.png",
	"SILVER": "res://Assets/Images/Icons/StarSilver32.png",
	"BRONZE": "res://Assets/Images/Icons/StarBronze32.png"
}

var keys: Array[String]
var scoreIndex := 0
var key := "9990"

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


# Called to retrieve score data
func getScoreData() -> void:
	if !Globals.highScores.is_empty():
		keys = Globals.highScores.keys()
		key = keys[scoreIndex]
		print("High scores available!\n", keys)
		levelName.text = "Level Name" # TODO: Create a dictionary to store level names, threshold data
		levelPass.text = "Password: " + key
		
		# If threshold data exists, set the labels
		if !Globals.THRESHOLDS[key].is_empty() && Globals.THRESHOLDS[key].size() == 3:
			for i: int in 3:
				thresholds[i].text = str(Globals.THRESHOLDS[key][i])
		else:
			return


# Called by the MenuManager to show this window
func showMenu() -> void:
	getScoreData()
	show()


# Called to return to the last menu
func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	GoBack.emit() # Bye!


# Called when a button is pressed
func onButtonPressed(btn: int):
	match btn as buttonTypes:  #  Determine which button got pressed
		buttonTypes.NEXT: # Called to retrieve data for the next level
			if scoreIndex + 1 < Globals.highScores.size():
				SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback # TODO : Change sounds
				scoreIndex += 1
				getScoreData()

		buttonTypes.PREV: # Called to retrieve score data for the previous level # TODO : Change sounds
			if scoreIndex > 0:
				SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
				scoreIndex -= 1
				getScoreData()
		
		buttonTypes.PLAY: # Called to play the currently-viewed level
			SoundControl.playCue(SoundControl.start, 1.0)
			SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[key])
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		buttonTypes.CLOSE: # Called to close the window
			returnToLastMenu()


# Event handler for when the mouse hovers a menu button
func onButtonMouseEntered(i: int) -> void:
	# Make the button grab_focus
	buttons[i].grab_focus()


# Event handler for when a menu button receives focus
func onButtonFocusEntered(i: int) -> void:
	buttons[i].grab_click_focus()
