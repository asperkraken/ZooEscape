extends Control

# Signals
signal GoBack

# Enums
enum groups {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE
}

# Constants
const DEADZONE_MAX := 1.0
const DEADZONE_MIN := 0.2

# Info to display for options
const MASTERINFO := "Controls total volume of \nall sound."
const BGMINFO := "Controls volume level \nof background music."
const SFXINFO := "Controls volume level of \nsound effects."
const CUEINFO := "Controls volume of system \ncues like pause noises."
const DEADZONEINFO := "Controls the level at which \nanalog direction inputs trigger."
const EXITINFO := "Close this menu.  Settings \n are automatically saved."

# Grab global value references
var analogDeadzone: float = Globals.currentSettings.analog_deadzone

# Variables
var bufferState := true # hold player input until timer flips
var settingsChanged := false # only save settings if any values were changed
var group := groups.MASTER # shows which control area has focus


# Called when node enters the scene tree for the first time
func _ready() -> void:
	# update slider positions
	$VBox/MasterGroup/MasterSlider.value = Globals.currentSettings.master_volume
	$VBox/BGMGroup/BGMSlider.value = Globals.currentSettings.music_volume
	$VBox/SFXGroup/SFXSlider.value = Globals.currentSettings.sfx_volume
	$VBox/CueGroup/CueSlider.value = Globals.currentSettings.cue_volume
	
	# update percent texts
	$VBox/MasterGroup/MasterValue.text = str(percentageConversion(Globals.currentSettings.master_volume)) + "%"
	$VBox/BGMGroup/BGMValue.text = str(percentageConversion(Globals.currentSettings.music_volume)) + "%"
	$VBox/SFXGroup/SFXValue.text = str(percentageConversion(Globals.currentSettings.sfx_volume)) + "%"
	$VBox/CueGroup/CueValue.text = str(percentageConversion(Globals.currentSettings.cue_volume)) + "%"
	$VBox/DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)


# Called every render frame
func _process(_delta: float) -> void:
	# ONLY detect inputs when this menu is visible and ready
	if visible && !bufferState: # NOTE: Let's discuss whether we still need this buffer state with the new menu system
			if Input.is_action_pressed("ActionButton") and group == groups.DEADZONE:
				if $VBox/DeadzoneGroup/DeadzoneDown.has_focus() and analogDeadzone > DEADZONE_MIN:
					analogDeadzone -= 0.01 # adjust deadzone and update text
					$VBox/DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
				if $VBox/DeadzoneGroup/DeadzoneUp.has_focus() and analogDeadzone < DEADZONE_MAX:
					analogDeadzone += 0.01
					$VBox/DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
			
			# If Left or Right released after adjusting SFX or CUE sliders, play a sound
			if Input.is_action_just_released("DigitalLeft") or Input.is_action_just_released("DigitalRight"):
				if group == groups.SFX: # add sound cues to test fx levels
					SoundControl.playSfx(SoundControl.scratch)
				if group == groups.CUE:
					SoundControl.playCue(SoundControl.pickup, 1.0)
			
			# If Escape or other CancelButtton pressed, close the munu
			if Input.is_action_just_pressed("CancelButton"):
				if group != groups.ESCAPE: # move to escape button on press
					_on_escape_button_mouse_entered()
				else:
					_on_escape_button_pressed() # trigger escape function


# Called by tthe MenuManager to show the SettingsMenu
func showMenu() -> void:
	show()
	$VBox/MasterGroup/MasterSlider.call_deferred("grab_focus")


func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	if settingsChanged:
		Data.saveGameData()
		settingsChanged = false
	GoBack.emit()


# update settings in global dictionary, update global volume buses and set deadzones
func updateSoundControl() -> void: # update global settings
	# set sound levels
	SoundControl.setSoundPreferences(
		$VBox/MasterGroup/MasterSlider.value,
		$VBox/BGMGroup/BGMSlider.value,
		$VBox/SFXGroup/SFXSlider.value,
		$VBox/CueGroup/CueSlider.value
	)
	# set deadzones
	SoundControl.muteAudioBusCheck()


# focus info widget to update info text on focus change
func focusInfoRelay(logic:String, info:String) -> void:
	if group != groups[logic]:
		group = groups[logic] # pull group and grab info
		$VBox/Description.visible_ratio = 0.0 # roll text back
		$VBox/Description.text = str(info) # update
		$Animator.play("roll_info") # roll in text


# widget to convert audio level to visual percent feedback
func percentageConversion(_volumeLevel) -> int:
	var _volume: float = abs(_volumeLevel) # get volume level
	const _rate := 0.2 # 20/100
	var _percentage := 100 - roundi(abs(_volume / _rate)) # take total from 100 for rate, clean display
	return _percentage # return value and display in scene


#### SLIDER VALUES CHANGED
# update master volume on slide
func _on_master_slider_value_changed(value: float) -> void:
	if !bufferState: # if no buffer, change levels
		updateSoundControl()
		Globals.currentSettings.master_volume = value
		updateText("MASTER", value)
		settingsChanged = true

# update bgm levels
func _on_bgm_slider_value_changed(value: float) -> void:
	if !bufferState:
		updateSoundControl()
		Globals.currentSettings.music_volume = value
		SoundControl.muteAudioBusCheck()
		updateText("BGM", value)
		settingsChanged = true

# update sfx level
func _on_sfx_slider_value_changed(value: float) -> void:
	if !bufferState:
		updateSoundControl()
		Globals.currentSettings.sfx_volume = value
		SoundControl.muteAudioBusCheck()
		updateText("SFX", value)
		settingsChanged = true

# update cue levels
func _on_cue_slider_value_changed(value: float) -> void:
	if !bufferState:
		updateSoundControl()
		Globals.currentSettings.cue_volume = value
		SoundControl.muteAudioBusCheck()
		updateText("CUE", value)
		settingsChanged = true


#### TEXT UPDATES
func updateText(which: String, value: float):
	match which:
		"MASTER":
			$VBox/MasterGroup/MasterValue.text = str(abs(percentageConversion(value))) + "%"
		"BGM":
			$VBox/BGMGroup/BGMValue.text = str(abs(percentageConversion(value))) + "%"
		"SFX":
			$VBox/SFXGroup/SFXValue.text = str(abs(percentageConversion(value))) + "%"
		"CUE":
			$VBox/CueGroup/CueValue.text = str(abs(percentageConversion(value))) + "%"
		"DEADZONE":
			$VBox/DeadzoneGroup/DeadzoneValue.text = str(value)



#### MOUSE ENTERED
# mouse hovering master slider
func _on_master_slider_mouse_entered() -> void:
	focusInfoRelay("MASTER", MASTERINFO) # focus grab


# mouse hovering bgm slider
func _on_bgm_slider_mouse_entered() -> void:
	focusInfoRelay("BGM", BGMINFO)


# mouse hovering sfx slider
func _on_sfx_slider_mouse_entered() -> void:
	focusInfoRelay("SFX", SFXINFO)


# grab cue focus
func _on_cue_slider_mouse_entered() -> void:
	focusInfoRelay("CUE", CUEINFO)


# grab deadzone focus
func _on_deadzone_up_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)


# grab deadzone focus
func _on_deadzone_down_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)


# grab escape button focus
func _on_escape_button_mouse_entered() -> void:
	focusInfoRelay("ESCAPE", EXITINFO)



#### FOCUS ENTERED
# grab master group focus
func _on_master_slider_focus_entered() -> void:
	focusInfoRelay("MASTER", MASTERINFO) # focus grab


# grab bgm focus
func _on_bgm_slider_focus_entered() -> void:
	focusInfoRelay("BGM", BGMINFO)


# grab sfx focus
func _on_sfx_slider_focus_entered() -> void:
	focusInfoRelay("SFX", SFXINFO)


# grab cue group focus
func _on_cue_slider_focus_entered() -> void:
	focusInfoRelay("CUE", CUEINFO)


# grab deadzone focus
func _on_deadzone_up_focus_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)


# grab deadzone focus
func _on_deadzone_down_focus_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)


# grab escape button focus
func _on_escape_button_focus_entered() -> void:
	focusInfoRelay("ESCAPE", EXITINFO)



#### DRAG STARTED
# on drag grab and release, check values for mute
func _on_bgm_slider_drag_started() -> void:
	if !SoundControl.bgm.has_stream_playback():
		SoundControl.playBgm()


# sound fx test on starting drag
func _on_sfx_slider_drag_started() -> void:
	SoundControl.playSfx(SoundControl.scratch) # audio cue for testing on grab


# cue test on drag
func _on_cue_slider_drag_started() -> void:
	SoundControl.playCue(SoundControl.pickup, 1.0) # audio cue for testing on grab



#### DRAG ENDED
# on drag grab and release, check values for mute
func _on_bgm_slider_drag_ended(_value_changed: bool) -> void:
	if !SoundControl.bgm.has_stream_playback():
		SoundControl.playBgm()


# sound fx test on releasing drag
func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playSfx(SoundControl.scratch) # audio cue for testing after release


# cue test on release
func _on_cue_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playCue(SoundControl.pickup, 1.0) # audio cue for testing after release



#### ON PRESSED
# update deadzone levels
func _on_deadzone_down_pressed() -> void:
	if !bufferState:
		var _downValue := analogDeadzone - 0.01
		if _downValue < DEADZONE_MIN:
			_downValue = DEADZONE_MIN
		
		analogDeadzone = _downValue
		Globals.currentSettings.analog_deadzone = analogDeadzone
		updateText("DEADOZNE", analogDeadzone)
		Globals.deadzoneUpdate()
		settingsChanged = true


# update deadzone levels
func _on_deadzone_up_pressed() -> void:
	if !bufferState:
		var _upValue := analogDeadzone + 0.01
		if _upValue > DEADZONE_MAX:
			_upValue = DEADZONE_MAX
		
		analogDeadzone = _upValue
		Globals.currentSettings.analog_deadzone = analogDeadzone
		updateText("DEADOZNE", analogDeadzone)
		Globals.deadzoneUpdate()
		settingsChanged = true


# save data on escape
func _on_escape_button_pressed() -> void:
	if !bufferState:
		returnToLastMenu()



#### TIMER TIMEOUT
# input buffer added to avoid accidental input on load
func _on_input_buffer_timeout() -> void:
	bufferState = false
