extends Control

enum focusGroups {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE
}

# Constants
const DEADZONE_MAX := 1.0
const DEADZONE_MIN := 0.20

# Info to display for options -- Values are hard-coded in case they deleted in the editor
@export_multiline var masterInfo := "Controls total volume of \nall sound."
@export_multiline var bgmInfo := "Controls volume level \nof background music."
@export_multiline var sfxInfo := "Controls volume level of \nsound effects."
@export_multiline var cueInfo := "Controls volume of system \ncues like pause noises."
@export_multiline var deadzoneInfo := "Controls the level at which \nanalog direction inputs trigger."
@export_multiline var exitInfo := "Close this menu.  Settings \n are automatically saved."

# Grab global value references
var masterVolume: float = Globals.currentSettings["master_volume"]
var bgmVolume: float = Globals.currentSettings["music_volume"]
var sfxVolume: float = Globals.currentSettings["sfx_volume"]
var cueVolume: float = Globals.currentSettings["cue_volume"]
var analogDeadzone: float = Globals.currentSettings["analog_deadzone"]

# Holders for percentage values
var masterPercent: int
var bgmPercent: int
var sfxPercent: int
var cuePercent: int

# Variables
var bufferState := true # hold player input until timer flips
var settingsChanged := false # only save settings if any values were changed
var focusGroup := focusGroups.MASTER # shows which control area has focus


# Called when node enters the scene tree for the first time
func _ready() -> void:
	# update text and set first button on master bgm down
	# update all text and values with globals from load data
	
	# update percents
	masterPercent = percentageConversion(masterVolume)
	bgmPercent = percentageConversion(bgmVolume)
	sfxPercent = percentageConversion(sfxVolume)
	cuePercent = percentageConversion(cueVolume)
	
	# update slider positions
	$MasterGroup/MasterSlider.value = masterVolume
	$BGMGroup/BGMSlider.value = bgmVolume
	$SFXGroup/SFXSlider.value = sfxVolume
	$CueGroup/CueSlider.value = cueVolume
	
	# update percent texts
	$MasterGroup/MasterValue.text = str(masterPercent) + "%"
	$BGMGroup/BGMValue.text = str(bgmPercent) + "%"
	$SFXGroup/SFXValue.text = str(sfxPercent) + "%"
	$CueGroup/CueValue.text = str(cuePercent) + "%"
	$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	
	# grab first focus and roll in info text
	$MasterGroup/MasterSlider.grab_focus()
	focusInfoRelay("MASTER", masterInfo)
	$Description.text = masterInfo
	$Animator.play("roll_info")


# Called every render frame
func _process(_delta: float) -> void:
	# ONLY detect inputs when this menu is visible and ready
	if self.visible && !bufferState:
			if Input.is_action_pressed("ActionButton") and focusGroup == focusGroups.DEADZONE:
				if $DeadzoneGroup/DeadzoneDown.has_focus() and analogDeadzone > DEADZONE_MIN:
					analogDeadzone -= 0.01 # adjust deadzone and update text
					$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
				if $DeadzoneGroup/DeadzoneUp.has_focus() and analogDeadzone < DEADZONE_MAX:
					analogDeadzone += 0.01
					$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
			
			# If Left or Right released after adjusting SFX or CUE sliders, play a sound
			if Input.is_action_just_released("DigitalLeft") or Input.is_action_just_released("DigitalRight"):
				if focusGroup == focusGroups.SFX: # add sound cues to test fx levels
					SoundControl.playSfx(SoundControl.scratch)
				if focusGroup == focusGroups.CUE:
					SoundControl.playCue(SoundControl.pickup, 1.0)
			
			# If Escape or other CancelButtton pressed, close the munu
			if Input.is_action_just_pressed("CancelButton"):
				if focusGroup != focusGroups.ESCAPE: # move to escape button on press
					_on_escape_button_focus_entered()
					$EscapeButton.grab_focus()
				else:
					_on_escape_button_pressed() # trigger escape function


# update settings in global dictionary, update global volume buses and set deadzones
func globalSettingsUpdate() -> void: # update global settings
	Globals.currentSettings["master_volume"] = masterVolume
	Globals.currentSettings["music_volume"] = bgmVolume
	Globals.currentSettings["sfx_volume"] = sfxVolume
	Globals.currentSettings["cue_volume"] = cueVolume
	Globals.currentSettings["analog_deadzone"] = analogDeadzone
	# set sound levels
	SoundControl.setSoundPreferences(masterVolume, bgmVolume, sfxVolume, cueVolume)
	# set deadzones
	Globals.deadzoneUpdate()


# focus info widget to update info text on focus change
func focusInfoRelay(logic:String, info:String) -> void:
	if focusGroup != focusGroups[logic]:
		focusGroup = focusGroups[logic] # pull group and grab info
		$Description.visible_ratio = 0.0 # roll text back
		$Description.text = str(info) # update
		$Animator.play("roll_info") # roll in text


# widget to convert audio level to visual percent feedback
func percentageConversion(_volumeLevel) -> int:
	var _volume: float = abs(_volumeLevel) # get volume level
	const _rate := 0.2 # 20/100
	var _percentage := 100 - roundi(abs(_volume / _rate)) # take total from 100 for rate, clean display
	return _percentage # return value and display in scene


# update master volume on slide
func _on_master_slider_value_changed(_value: float) -> void:
	if !bufferState: # if no buffer, change levels
		masterTextUpdate()
		$MasterGroup/MasterValue.text = str(masterPercent) + "%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# update text for master volume level
func masterTextUpdate() -> void:
	masterVolume = $MasterGroup/MasterSlider.value
	masterPercent = abs(percentageConversion(masterVolume))
	$MasterGroup/MasterValue.text = str(masterPercent) + "%"


# grab master group focus
func _on_master_slider_focus_entered() -> void:
	focusInfoRelay("MASTER", masterInfo) # focus grab


# mouse hovering master slider
func _on_master_slider_mouse_entered() -> void:
	focusInfoRelay("MASTER", masterInfo) # focus grab


# update bgm levels
func _on_bgm_slider_value_changed(_value: float) -> void:
	if !bufferState:
		bgmTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# on drag grab and release, check values for mute
func _on_bgm_slider_drag_ended(_value_changed: bool) -> void:
	if $BGMGroup/BGMSlider.value <= -20:
		SoundControl.stopBgm()
	else:
		SoundControl.playBgm()


# on drag grab and release, check values for mute
func _on_bgm_slider_drag_started() -> void:
	if $BGMGroup/BGMSlider.value <= -20:
		SoundControl.stopBgm()
	else:
		SoundControl.playBgm()


# update text for bgm volume level
func bgmTextUpdate() -> void:
	bgmVolume = $BGMGroup/BGMSlider.value
	bgmPercent = percentageConversion(bgmVolume)
	$BGMGroup/BGMValue.text = str(bgmPercent) + "%"


# grab bgm focus
func _on_bgm_slider_focus_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


# mouse hovering bgm slider
func _on_bgm_slider_mouse_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


# update sfx level
func _on_sfx_slider_value_changed(_value: float) -> void:
	if !bufferState:
		sfxTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# update text for sfx volume level
func sfxTextUpdate() -> void:
	sfxVolume = $SFXGroup/SFXSlider.value
	sfxPercent = percentageConversion(sfxVolume)
	$SFXGroup/SFXValue.text = str(sfxPercent) + "%"


# grab sfx focus
func _on_sfx_slider_focus_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


# mouse hovering sfx slider
func _on_sfx_slider_mouse_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


# sound fx test on starting drag
func _on_sfx_slider_drag_started() -> void:
	SoundControl.playSfx(SoundControl.scratch) # audio cue for testing on grab


# sound fx test on releasing drag
func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playSfx(SoundControl.scratch) # audio cue for testing after release


# update cue levels
func _on_cue_slider_value_changed(_value: float) -> void:
	if !bufferState:
		cueTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# update text for cue volume level
func cueTextUpdate() -> void:
	cueVolume = $CueGroup/CueSlider.value
	cuePercent = percentageConversion(cueVolume)
	$CueGroup/CueValue.text = str(cuePercent) + "%"


# grab cue group focus
func _on_cue_slider_focus_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


# grab cue focus
func _on_cue_slider_mouse_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


# cue test on drag
func _on_cue_slider_drag_started() -> void:
	SoundControl.playCue(SoundControl.pickup, 1.0) # audio cue for testing on grab


# cue test on release
func _on_cue_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playCue(SoundControl.pickup, 1.0) # audio cue for testing after release


# update deadzone levels
func _on_deadzone_down_pressed() -> void:
	if !bufferState:
		var _downValue := analogDeadzone - 0.01
		if _downValue < DEADZONE_MIN:
			_downValue = DEADZONE_MIN

		analogDeadzone = _downValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		Globals.deadzoneUpdate()


# grab deadzone focus
func _on_deadzone_down_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# grab deadzone focus
func _on_deadzone_down_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# update deadzone levels
func _on_deadzone_up_pressed() -> void:
	if !bufferState:
		var _upValue := analogDeadzone + 0.01
		if _upValue > DEADZONE_MAX:
			_upValue = DEADZONE_MAX

		analogDeadzone = _upValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		Globals.deadzoneUpdate()


# grab deadzone focus
func _on_deadzone_up_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# grab deadzone focus
func _on_deadzone_up_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# save data on escape
func _on_escape_button_pressed() -> void:
	if !bufferState:
		Data.saveGameData()
		globalSettingsUpdate() # update global settings


# grab escape button focus
func _on_escape_button_focus_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


# grab escape button focus
func _on_escape_button_mouse_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


# input buffer added to avoid accidental input on load
func _on_input_buffer_timeout() -> void:
	bufferState = false
