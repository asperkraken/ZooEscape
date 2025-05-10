extends Control

## info to display for options
@export var masterInfo : String
@export var bgmInfo : String
@export var sfxInfo : String
@export var cueInfo : String
@export var deadzoneInfo : String
@export var exitInfo : String

## grab global value references
var masterVolume : int = Globals.Current_Options_Settings["master_volume"]
var bgmVolume : int = Globals.Current_Options_Settings["music_volume"]
var sfxVolume : int = Globals.Current_Options_Settings["sfx_volume"]
var cueVolume : int = Globals.Current_Options_Settings["cue_volume"]
var analogDeadzone : float = Globals.Current_Options_Settings["analog_deadzone"]

## set hard limits
const MAX_VOLUME = 0
const DEFAULT_VOLUME = SoundControl.DEFAULT_VOLUME
const SILENCE = -80
const DEADZONE_MAX = 1.0
const DEADZONE_MIN = 0.20

var focusGroup = FOCUS_GROUPS.MASTER
enum FOCUS_GROUPS {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE}


func _ready() -> void:
	## update text and set first button on master bgm down
	valueDisplayTextUpdate()
	$MasterGroup/MasterDown.grab_focus()


func _process(_delta: float) -> void:
	valueDisplayTextUpdate() ## update values every frame



func valueDisplayTextUpdate(): ## function to update all values at once
	## also updates settings to preview sound in real time
	$MasterGroup/MasterValue.text = str(masterVolume)
	$BGMGroup/BGMValue.text = str(bgmVolume)
	$SFXGroup/SFXValue.text = str(sfxVolume)
	$CueGroup/CueValue.text = str(cueVolume)
	$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	globalSettingsUpdate()



func globalSettingsUpdate(): ## update global settings
	Globals.Current_Options_Settings["master_volume"] = masterVolume
	Globals.Current_Options_Settings["music_volume"] = bgmVolume
	Globals.Current_Options_Settings["sfx_volume"] = sfxVolume
	Globals.Current_Options_Settings["cue_volume"] = cueVolume
	Globals.Current_Options_Settings["analog_deadzone"] = analogDeadzone
	## set deadzones
	InputMap.action_set_deadzone("DigitalDown",analogDeadzone)
	InputMap.action_set_deadzone("DigitalUp",analogDeadzone)
	InputMap.action_set_deadzone("DigitalLeft",analogDeadzone)
	InputMap.action_set_deadzone("DigitalRight",analogDeadzone)


func _on_master_down_pressed() -> void:
	var _downValue = masterVolume-1
	if _downValue < SILENCE:
		_downValue = SILENCE

	masterVolume = _downValue
	valueDisplayTextUpdate()


func _on_master_down_focus_entered() -> void:
	$MasterGroup/MasterDown.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.MASTER:
		focusGroup = FOCUS_GROUPS.MASTER
		$Description.visible_ratio = 0
		$Description.text = str(masterInfo)
		$Animator.play("roll_info")


func _on_master_down_mouse_entered() -> void:
	$MasterGroup/MasterDown.grab_focus()
	if focusGroup != FOCUS_GROUPS.MASTER:
		focusGroup = FOCUS_GROUPS.MASTER
		$Description.visible_ratio = 0
		$Description.text = str(masterInfo)
		$Animator.play("roll_info")


func _on_master_up_pressed() -> void:
	var _newValue = masterVolume+1
	if _newValue > MAX_VOLUME:
		_newValue = MAX_VOLUME

	masterVolume = _newValue
	valueDisplayTextUpdate()


func _on_master_up_focus_entered() -> void:
	$MasterGroup/MasterUp.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.MASTER:
		focusGroup = FOCUS_GROUPS.MASTER
		$Description.visible_ratio = 0
		$Description.text = str(masterInfo)
		$Animator.play("roll_info")


func _on_master_up_mouse_entered() -> void:
	$MasterGroup/MasterUp.grab_focus()
	if focusGroup != FOCUS_GROUPS.MASTER:
		focusGroup = FOCUS_GROUPS.MASTER
		$Description.visible_ratio = 0
		$Description.text = str(masterInfo)
		$Animator.play("roll_info")


func _on_bgm_down_pressed() -> void:
	var _downValue = bgmVolume-1
	if _downValue < SILENCE:
		_downValue = SILENCE

	bgmVolume = _downValue
	valueDisplayTextUpdate()


func _on_bgm_down_focus_entered() -> void:
	$BGMGroup/BGMDown.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.BGM:
		focusGroup = FOCUS_GROUPS.BGM
		$Description.visible_ratio = 0
		$Description.text = str(bgmInfo)
		$Animator.play("roll_info")


func _on_bgm_down_mouse_entered() -> void:
	$BGMGroup/BGMDown.grab_focus()
	if focusGroup != FOCUS_GROUPS.BGM:
		focusGroup = FOCUS_GROUPS.BGM
		$Description.visible_ratio = 0
		$Description.text = str(bgmInfo)
		$Animator.play("roll_info")


func _on_bgm_up_pressed() -> void:
	var _newValue = bgmVolume+1
	if _newValue > MAX_VOLUME:
		_newValue = MAX_VOLUME

	bgmVolume = _newValue
	valueDisplayTextUpdate()


func _on_bgm_up_focus_entered() -> void:
	$BGMGroup/BGMUp.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.BGM:
		focusGroup = FOCUS_GROUPS.BGM
		$Description.visible_ratio = 0
		$Description.text = str(bgmInfo)
		$Animator.play("roll_info")


func _on_bgm_up_mouse_entered() -> void:
	$BGMGroup/BGMUp.grab_focus()
	if focusGroup != FOCUS_GROUPS.BGM:
		focusGroup = FOCUS_GROUPS.BGM
		$Description.visible_ratio = 0
		$Description.text = str(bgmInfo)
		$Animator.play("roll_info")


func _on_sfx_down_pressed() -> void:
	var _downValue = sfxVolume-1
	if _downValue < SILENCE:
		_downValue = SILENCE

	sfxVolume = _downValue
	valueDisplayTextUpdate()
	SoundControl.playSfx(SoundControl.blip)


func _on_sfx_down_focus_entered() -> void:
	$SFXGroup/SFXDown.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.SFX:
		focusGroup = FOCUS_GROUPS.SFX
		$Description.visible_ratio = 0
		$Description.text = str(sfxInfo)
		$Animator.play("roll_info")


func _on_sfx_down_mouse_entered() -> void:
	$SFXGroup/SFXDown.grab_focus()
	if focusGroup != FOCUS_GROUPS.SFX:
		focusGroup = FOCUS_GROUPS.SFX
		$Description.visible_ratio = 0
		$Description.text = str(sfxInfo)
		$Animator.play("roll_info")


func _on_sfx_up_pressed() -> void:
	var _newValue = sfxVolume+1
	if _newValue > MAX_VOLUME:
		_newValue = MAX_VOLUME

	sfxVolume = _newValue
	valueDisplayTextUpdate()
	SoundControl.playSfx(SoundControl.blip)


func _on_sfx_up_focus_entered() -> void:
	$SFXGroup/SFXUp.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.SFX:
		focusGroup = FOCUS_GROUPS.SFX
		$Description.visible_ratio = 0
		$Description.text = str(sfxInfo)
		$Animator.play("roll_info")


func _on_sfx_up_mouse_entered() -> void:
	$SFXGroup/SFXUp.grab_focus()
	if focusGroup != FOCUS_GROUPS.SFX:
		focusGroup = FOCUS_GROUPS.SFX
		$Description.visible_ratio = 0
		$Description.text = str(sfxInfo)
		$Animator.play("roll_info")


func _on_cue_down_pressed() -> void:
	var _downValue = cueVolume-1
	if _downValue < SILENCE:
		_downValue = SILENCE

	cueVolume = _downValue
	valueDisplayTextUpdate()
	SoundControl.playCue(SoundControl.start,2.0)


func _on_cue_down_focus_entered() -> void:
	$CueGroup/CueDown.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.CUE:
		focusGroup = FOCUS_GROUPS.CUE
		$Description.visible_ratio = 0
		$Description.text = str(cueInfo)
		$Animator.play("roll_info")


func _on_cue_down_mouse_entered() -> void:
	$CueGroup/CueDown.grab_focus()
	if focusGroup != FOCUS_GROUPS.CUE:
		focusGroup = FOCUS_GROUPS.CUE
		$Description.visible_ratio = 0
		$Description.text = str(cueInfo)
		$Animator.play("roll_info")


func _on_cue_up_pressed() -> void:
	var _newValue = cueVolume+1
	if _newValue > MAX_VOLUME:
		_newValue = MAX_VOLUME

	cueVolume = _newValue
	valueDisplayTextUpdate()
	SoundControl.playCue(SoundControl.start,2.0)


func _on_cue_up_focus_entered() -> void:
	$CueGroup/CueUp.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.CUE:
		focusGroup = FOCUS_GROUPS.CUE
		$Description.visible_ratio = 0
		$Description.text = str(cueInfo)
		$Animator.play("roll_info")


func _on_cue_up_mouse_entered() -> void:
	$CueGroup/CueUp.grab_focus()
	if focusGroup != FOCUS_GROUPS.CUE:
		focusGroup = FOCUS_GROUPS.CUE
		$Description.visible_ratio = 0
		$Description.text = str(cueInfo)
		$Animator.play("roll_info")


func _on_deadzone_down_pressed() -> void:
	var _downValue = analogDeadzone-0.01
	if _downValue < DEADZONE_MIN:
		_downValue = DEADZONE_MIN

	analogDeadzone = _downValue


func _on_deadzone_down_focus_entered() -> void:
	$DeadzoneGroup/DeadzoneDown.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.DEADZONE:
		focusGroup = FOCUS_GROUPS.DEADZONE
		$Description.visible_ratio = 0
		$Description.text = str(deadzoneInfo)
		$Animator.play("roll_info")


func _on_deadzone_down_mouse_entered() -> void:
	$DeadzoneGroup/DeadzoneDown.grab_focus()
	if focusGroup != FOCUS_GROUPS.DEADZONE:
		focusGroup = FOCUS_GROUPS.DEADZONE
		$Description.visible_ratio = 0
		$Description.text = str(deadzoneInfo)
		$Animator.play("roll_info")


func _on_deadzone_up_pressed() -> void:
	var _upValue = analogDeadzone+0.01
	if _upValue > DEADZONE_MAX:
		_upValue = DEADZONE_MAX

	analogDeadzone = _upValue


func _on_deadzone_up_focus_entered() -> void:
	$DeadzoneGroup/DeadzoneUp.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.DEADZONE:
		focusGroup = FOCUS_GROUPS.DEADZONE
		$Description.visible_ratio = 0
		$Description.text = str(deadzoneInfo)
		$Animator.play("roll_info")


func _on_deadzone_up_mouse_entered() -> void:
	$DeadzoneGroup/DeadzoneUp.grab_focus()
	if focusGroup != FOCUS_GROUPS.DEADZONE:
		focusGroup = FOCUS_GROUPS.DEADZONE
		$Description.visible_ratio = 0
		$Description.text = str(deadzoneInfo)
		$Animator.play("roll_info")


func _on_escape_button_pressed() -> void:
	globalSettingsUpdate() ## update global settings
	SceneManager.GoToTitle() ## go to title


func _on_escape_button_focus_entered() -> void:
	$EscapeButton.grab_click_focus()
	if focusGroup != FOCUS_GROUPS.ESCAPE:
		focusGroup = FOCUS_GROUPS.ESCAPE
		$Description.visible_ratio = 0
		$Description.text = str(exitInfo)
		$Animator.play("roll_info")


func _on_escape_button_mouse_entered() -> void:
	$EscapeButton.grab_focus()
	if focusGroup != FOCUS_GROUPS.ESCAPE:
		focusGroup = FOCUS_GROUPS.ESCAPE
		$Description.visible_ratio = 0
		$Description.text = str(exitInfo)
		$Animator.play("roll_info")
