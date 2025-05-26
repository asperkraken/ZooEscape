extends Control

signal SetMenu(menu: MenuManager.menuTypes)

# Window BG Color: #61407A
# Window Border Color: #8F3DA7


# materials for shader changes on password entry
const correctShader := preload("res://Assets/Shaders/WobblyMaterial.tres")
const failShader := preload("res://Assets/Shaders/ErrorShakeX.tres")
const empty := "----"

# states to control focus and input
enum focusStates {
	ZERO,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	CLEAR,
	ENTER
}

@export var loadSceneBufferTime := 1 # Buffer until password scene loads
var focusState := 1 # current focus
var codeTextPos := 0 # position in code
var tempCode := "9990"
var inputBufferActive := true # hold input until window fades in

# Handles to child nodes
@onready var code := $Window/Code # text ref for code
@onready var buttons: Array[Button] = [
	# The button order in the scene tree can change, but this array must be in the same order as the focusStates enum
	$Window/Buttons/Row4/Button0, $Window/Buttons/Row1/Button1, $Window/Buttons/Row1/Button2,
	$Window/Buttons/Row1/Button3, $Window/Buttons/Row2/Button4, $Window/Buttons/Row2/Button5,
	$Window/Buttons/Row2/Button6, $Window/Buttons/Row3/Button7, $Window/Buttons/Row3/Button8,
	$Window/Buttons/Row3/Button9, $Window/Buttons/Row4/ButtonClear, $Window/Buttons/Row4/ButtonEnter
]


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Connect buttons to event handlers
	for i: int in buttons.size():
		buttons[i].pressed.connect(onButtonPressed.bind(i))
		buttons[i].focus_entered.connect(onButtonFocusEntered.bind(i))
		buttons[i].mouse_entered.connect(onButtonMouseEntered.bind(i))
		
	startInputBuffer()


# Called when input is detected
func _input(event: InputEvent) -> void:
	# ONLY detect inputs if Password window is visible and ready
	if self.visible && !inputBufferActive:
		# Check for ActionButton inputs to press whichever button has focus
		if event.is_action_pressed("ActionButton"):
			# Prevent more nodes from processing this input
			get_viewport().set_input_as_handled()
			print("PasswordMenu: ActionButton pressed!")
			onButtonPressed(focusState)
		
		# Check for CancelButton inputs to erase the last input from the code
		if event.is_action_pressed("CancelButton"):
			# Prevent more nodes from processing this input
			get_viewport().set_input_as_handled()
			print("PasswordMenu: CancelButton pressed!")
			onButtonMouseEntered(focusStates.CLEAR)
			onButtonPressed(focusStates.CLEAR)
		
		# Check for Numeric input events for keyboard typing of code
		for i: int in range(10):
			if event.is_action_pressed("Numeric_" + str(i)):
				# Prevent more nodes from processing this input
				get_viewport().set_input_as_handled()
				onButtonMouseEntered(i)
				onButtonPressed(i)


# sound cue for input sounds
func randomBlipCue() -> void:
	var _variant := randf_range(-0.7, 0.7) # random blips
	SoundControl.playCue(SoundControl.blip, (3.0 + _variant))


# Called to reset the code input field
func codeReset() -> void:
	code.text = empty
	codeTextPos = 0


# code deletion function
func codeEraseDigit() -> void:
	if codeTextPos > 0 && codeTextPos <= 4:
		codeTextPos -= 1
		code.text[codeTextPos] = "-"
	else:
		returnToLastMenu()


# Called to check if the code input field has 4 digits
func codeCompleteCheck() -> void:
	if codeTextPos >= 3:
		# Make the 'E' (Enter) button grab_focus
		onButtonMouseEntered(focusStates.ENTER)


# get number by state and input
func codeSetDigit(num: int) -> void: # if there are dashes, accept input
	# Play sound
	randomBlipCue()
	codeCompleteCheck()
	
	# Set the value in the password string, at the current position
	if codeTextPos < 4: # add code until full
		code.text[codeTextPos] = str(num)
		codeTextPos += 1
	# other functions will handle code once codeTestPos is full (4)


# check code for answer
func codeCheck() -> void:
	if !code.text.contains("-") && Globals.PASSWORDS.has(code.text): # yay
		startInputBuffer()
		tempCode = code.text # Store the entered code
		code.material = correctShader
		code.modulate = Color.GREEN_YELLOW
		SoundControl.playCue(SoundControl.success, 1.5)
		$TextEffectTimer.start(0.5)
		$LoadSceneBuffer.start(loadSceneBufferTime) # begin buffer to load
	else: # nay, code clears out and timer sets for shader reset
		startInputBuffer()
		codeTextPos = 0
		code.text = "XXXX"
		code.material = failShader
		code.modulate = Color.CRIMSON
		SoundControl.playCue(SoundControl.down, 1.5)
		$TextEffectTimer.start(0.5)


func startInputBuffer() -> void:
	inputBufferActive = true
	$InputBufferTimer.start(loadSceneBufferTime)

# Reset the modulation and material on the code text
func codeEffectReset() -> void:
	code.modulate = Color.WHITE
	code.material = null


# Called by the MenuManager to show the PasswordMenu
func showMenu() -> void:
	codeReset()					
	startInputBuffer()
	onButtonMouseEntered(focusStates.ONE) # set focusState and grab_focus
	self.visible = true


# Called to hide the PasswordMenu and reset the value entered
func hideMenu() -> void:
	self.visible = false


# Called to return to the last menu
func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	SetMenu.emit(MenuManager.lastMenu)


### Timer Event Handlers
# this effect resets the password box to default material and style
func onTextEffectTimerTimeout() -> void:
	codeEffectReset()


# turns off input buffer, timer runs on window open
func onInputBufferTimerTimeout() -> void:
	inputBufferActive = false
	codeReset()


# load scene at end of load buffer timer
func onLoadSceneBufferTimeout() -> void:
	print("Password Menu: Attempting to change levels!")
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[tempCode])
	SetMenu.emit(MenuManager.menuTypes.NONE)

### Button Event Handlers
# Called when a button is pressed
func onButtonPressed(i: int) -> void:
	match i as focusStates:
		# If a Numeric_ buttons was pressed 
		focusStates.ZERO, \
		focusStates.ONE, \
		focusStates.TWO, \
		focusStates.THREE, \
		focusStates.FOUR, \
		focusStates.FIVE, \
		focusStates.SIX, \
		focusStates.SEVEN, \
		focusStates.EIGHT, \
		focusStates.NINE:
			# Try add one didgt to code
			codeSetDigit(i)
		
		# If Clear button was pressed
		focusStates.CLEAR: # 10
			# Try to delete digit from end of code
			codeEraseDigit()
		
		# If Enter button was pressed
		focusStates.ENTER: # 11
			# Check for correct code
			codeCheck()

# Called when mouse hovers a button, have that button grab_focus
func onButtonMouseEntered(i: int) -> void:
	focusState = i # grab state
	buttons[i].call_deferred("grab_focus")

# Called when a button is focused, have that button grab_click_focus
func onButtonFocusEntered(i: int) -> void:
	focusState = i # grab state
	buttons[i].call_deferred("grab_click_focus")
