extends Control

enum NUMBER_FOCUS_STATES {
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
	ENTER}
var numberFocusState : int = 1

@onready var code := $Code
var codeTextPos : int = 0

@export var inGameMode : bool = false ## used to determine behavior in-game
var windowOpenFlag : bool = false ## flag for checking if window is open
var inputBufferActive : bool = true ## hold input until window fades in
@export var loadSceneBufferTime : int = 1


## materials for shader changes on password entry
const correctShader = preload("res://Assets/Shaders/wobbly_material.tres")
const failShader = preload("res://Assets/Shaders/error_shake_x.tres")
const title = "res://Scenes/ZETitle.tscn"
const empty = "----"


func _ready() -> void:
	code.text = empty
	if !inGameMode:
		$Animator.play("fade_in")
		$InputBufferTimer.start()
		$ButtonBox/Button1.grab_focus()


func _input(_event: InputEvent) -> void:
	if !inGameMode and !inputBufferActive:
		fetchInput()
	
	if inGameMode:
		if Input.is_action_just_pressed("ui_cancel") and !inputBufferActive:
			if windowOpenFlag == false:
				get_tree().paused = true
				windowOpenFlag = true
				$Animator.play("fade_in")
			else:
				$Animator.play_backwards("fade_in")
				windowOpenFlag = false
				get_tree().paused = false


	if inGameMode and windowOpenFlag == true:
		fetchInput()


func randomBlipCue():
	var _variant = randf_range(-0.7,0.7) ## random blips
	SoundControl.playCue(SoundControl.blip,(3.0+_variant))


func fetchInput():
	if Input.is_action_just_pressed("PasswordButton"):
		SoundControl.playCue(SoundControl.down,2.0)
		if !inGameMode:
			returnToTitle()
		else:
			$Animator.play_backwards("fade_in")
			code.text = empty
			codeTextPos = 0
			inputBufferActive = true
			windowOpenFlag = false

		
	if Input.is_action_just_pressed("ActionButton"):
		if numberFocusState == NUMBER_FOCUS_STATES.ENTER:
			answerCheck()
			
		if Globals.Game_Globals.has(code.text):
			SoundControl.playCue(SoundControl.success,2.5)
			$Code.material = correctShader
			$Code.modulate = Color.GREEN_YELLOW
			$LoadSceneBuffer.start(loadSceneBufferTime)


		if !"-" in code.text:
			numberFocusState = NUMBER_FOCUS_STATES.ENTER
			$ButtonBox/ButtonEnter.grab_focus()


	if Input.is_action_just_pressed("CancelButton"):
		if codeTextPos > -1:
			numberFocusState = NUMBER_FOCUS_STATES.CLEAR
			$ButtonBox/ButtonClear.grab_focus()
			codeRemoval()
		else:
			returnToTitle()


func codeRemoval():
	if codeTextPos != 0:
		codeTextPos -= 1
		code.text[codeTextPos] = "-"
	if codeTextPos <= 0:
		codeTextPos = 0
		code.text = empty


func returnToTitle():
	SoundControl.playCue(SoundControl.down,1.4)
	SceneManager.call_deferred("GoToNewSceneString",self, title)


func answerCheck():
	if !code.text.contains("-") and Globals.Game_Globals.has(code.text):
		$Code.material = correctShader
		$Code.modulate = Color.GREEN_YELLOW
		SoundControl.playCue(SoundControl.success,1.5)
		$LoadSceneBuffer.start(1)
	else:
		codeTextPos = 0
		$Code.text = "XXXX"
		$Code.material = failShader
		$Code.modulate = Color.CRIMSON
		SoundControl.playCue(SoundControl.down,1.5)
		$TextEffectTimer.start(0.5)


func _on_load_scene_buffer_timeout() -> void:
	SceneManager.call_deferred("GoToNewSceneString",self, Globals.Game_Globals[code.text])


## if there are dashes, accept input
func SetNum():
	randomBlipCue()
	var num := ""
	match numberFocusState:
		0:
			num = "0"
		1:
			num = "1"
		2:
			num = "2"
		3:
			num = "3"
		4:
			num = "4"
		5:
			num = "5"
		6:
			num = "6"
		7:
			num = "7"
		8:
			num = "8"
		9:
			num = "9"
	
	if codeTextPos < 4:
		code.text[codeTextPos] = num
		codeTextPos += 1



## this effect resets the password box to default material and style
func _on_effect_timer_timeout() -> void:
	codeTextPos = 0
	$Code.modulate = Color.WHITE
	$Code.material = null
	$Code.text = empty


## turns off input buffer, timer runs on window open
func _on_buffer_timer_timeout() -> void:
	inputBufferActive = false


func _on_button_1_pressed() -> void:
	SetNum()


func _on_button_1_focus_entered() -> void:
	numberFocusState = 1


func _on_button_1_mouse_entered() -> void:
	numberFocusState = 1


func _on_button_2_pressed() -> void:
	SetNum()


func _on_button_2_focus_entered() -> void:
	numberFocusState = 2


func _on_button_2_mouse_entered() -> void:
	numberFocusState = 2


func _on_button_3_pressed() -> void:
	SetNum()


func _on_button_3_focus_entered() -> void:
	numberFocusState = 3


func _on_button_3_mouse_entered() -> void:
	numberFocusState = 3


func _on_button_4_pressed() -> void:
	SetNum()


func _on_button_4_focus_entered() -> void:
	numberFocusState = 4


func _on_button_4_mouse_entered() -> void:
	numberFocusState = 4


func _on_button_5_pressed() -> void:
	SetNum()


func _on_button_5_focus_entered() -> void:
	numberFocusState = 5


func _on_button_5_mouse_entered() -> void:
	numberFocusState = 5


func _on_button_6_pressed() -> void:
	SetNum()


func _on_button_6_focus_entered() -> void:
	numberFocusState = 6


func _on_button_6_mouse_entered() -> void:
	numberFocusState = 6


func _on_button_7_pressed() -> void:
	SetNum()


func _on_button_7_focus_entered() -> void:
	numberFocusState = 7


func _on_button_7_mouse_entered() -> void:
	numberFocusState = 7


func _on_button_8_pressed() -> void:
	SetNum()


func _on_button_8_focus_entered() -> void:
	numberFocusState = 8


func _on_button_8_mouse_entered() -> void:
	numberFocusState = 8


func _on_button_9_pressed() -> void:
	SetNum()


func _on_button_9_focus_entered() -> void:
	numberFocusState = 9


func _on_button_9_mouse_entered() -> void:
	numberFocusState = 9


func _on_button_0_pressed() -> void:
	SetNum()


func _on_button_0_focus_entered() -> void:
	numberFocusState = 0


func _on_button_0_mouse_entered() -> void:
	numberFocusState = 0


func _on_button_clear_pressed() -> void:
	if codeTextPos > 0:
		codeRemoval()
	else:
		returnToTitle()


func _on_button_clear_focus_entered() -> void:
	numberFocusState = 10


func _on_button_clear_mouse_entered() -> void:
	numberFocusState = 10


func _on_button_enter_pressed() -> void:
	answerCheck()


func _on_button_enter_focus_entered() -> void:
	numberFocusState = 11


func _on_button_enter_mouse_entered() -> void:
	numberFocusState = 11
