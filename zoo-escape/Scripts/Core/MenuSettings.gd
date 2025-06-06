class_name SettingsMenu extends Control

# Signals
signal GoBack

# Enums
enum focusGroups {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE
}


# Info to display for options
const MASTERINFO := "Controls total volume of \nall sound."
const BGMINFO := "Controls volume level \nof background music."
const SFXINFO := "Controls volume level of \nsound effects."
const CUEINFO := "Controls volume of system \ncues like pause noises."
const DEADZONEINFO := "Controls the level at which \nanalog direction inputs trigger."
const EXITINFO := "Close this menu.  Settings \n are automatically saved."


# Variables
var settingsChanged := false # only save settings if any values were changed
var focusGroup := focusGroups.MASTER # shows which control area has focus


# Called when node enters the scene tree for the first time
func _ready() -> void:
	# update slider positions
	$VBox/MasterGroup/MasterSlider.value = Globals.currentSettings.masterVolume
	$VBox/BGMGroup/BGMSlider.value = Globals.currentSettings.musicVolume
	$VBox/SFXGroup/SFXSlider.value = Globals.currentSettings.sfxVolume
	$VBox/CueGroup/CueSlider.value = Globals.currentSettings.cueVolume
	
	# update percent texts
	$VBox/MasterGroup/MasterValue.text = str(percentageConversion(Globals.currentSettings.masterVolume)) + "%"
	$VBox/BGMGroup/BGMValue.text = str(percentageConversion(Globals.currentSettings.musicVolume)) + "%"
	$VBox/SFXGroup/SFXValue.text = str(percentageConversion(Globals.currentSettings.sfxVolume)) + "%"
	$VBox/CueGroup/CueValue.text = str(percentageConversion(Globals.currentSettings.cueVolume)) + "%"
	$VBox/DeadzoneGroup/DeadzoneValue.text = str(Globals.currentSettings.analogDeadzone)


# Called when InputEvent detected
func _input(event: InputEvent) -> void:
	# ONLY detect inputs when this menu is visible and ready
	if visible:
		# If Escape or other CancelButtton pressed, close the munu
		if event.is_action_pressed("CancelButton"):
			get_viewport().set_input_as_handled() # Prevent more nodes from processing this input
			if focusGroup != focusGroups.ESCAPE: # move to escape button on press
				_on_escape_button_mouse_entered()
				$VBox/Header/EscapeButton.call_deferred("grab_focus")
				$VBox/Header/EscapeButton.call_deferred("grab_click_focus")
			else:
				_on_escape_button_pressed() # trigger escape function
		
		# If activating a Deadzone adjustment button with ActionButton, adjust Deadzone
		if event.is_action_pressed("ActionButton") and focusGroup == focusGroups.DEADZONE:
				get_viewport().set_input_as_handled() # Prevent more nodes from processing this input
				if $VBox/DeadzoneGroup/DeadzoneDown.has_focus():
					_on_deadzone_down_pressed()
				if $VBox/DeadzoneGroup/DeadzoneUp.has_focus():
					_on_deadzone_up_pressed()
					
		# If Left or Right released after adjusting SFX or CUE sliders, play a sound
		if (event.is_action_released("DigitalLeft") or event.is_action_released("DigitalRight")) and not event.is_echo():
			if focusGroup == focusGroups.SFX: # add sound cues to test fx levels
				SoundControl.playSfx(SoundControl.scratch)
			if focusGroup == focusGroups.CUE:
				SoundControl.playCue(SoundControl.pickup, 1.0)


# Called by tthe MenuManager to show the SettingsMenu
func showMenu() -> void:
	$VBox/MasterGroup/MasterSlider.call_deferred("grab_focus")
	show()


func returnToLastMenu() -> void:
	if settingsChanged:
		Data.saveSettingsData()
		settingsChanged = false
	SoundControl.playCue(SoundControl.down, 1.4)
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
	SoundControl.muteAudioBusCheck()


# focus info widget to update info text on focus change
func focusInfoRelay(logic:String, info:String) -> void:
	if focusGroup != focusGroups[logic]:
		focusGroup = focusGroups[logic] # pull group and grab info
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
	updateSoundControl()
	Globals.currentSettings.masterVolume = value
	updateText("MASTER", value)
	settingsChanged = true

# update bgm levels
func _on_bgm_slider_value_changed(value: float) -> void:
	updateSoundControl()
	Globals.currentSettings.musicVolume = value
	SoundControl.muteAudioBusCheck()
	updateText("BGM", value)
	settingsChanged = true

# update sfx level
func _on_sfx_slider_value_changed(value: float) -> void:
	updateSoundControl()
	Globals.currentSettings.sfxVolume = value
	SoundControl.muteAudioBusCheck()
	updateText("SFX", value)
	settingsChanged = true

# update cue levels
func _on_cue_slider_value_changed(value: float) -> void:
	updateSoundControl()
	Globals.currentSettings.cueVolume = value
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
	$VBox/MasterGroup/MasterSlider.call_deferred("grab_focus")


# mouse hovering bgm slider
func _on_bgm_slider_mouse_entered() -> void:
	focusInfoRelay("BGM", BGMINFO)
	$VBox/BGMGroup/BGMSlider.call_deferred("grab_focus")


# mouse hovering sfx slider
func _on_sfx_slider_mouse_entered() -> void:
	focusInfoRelay("SFX", SFXINFO)
	$VBox/SFXGroup/SFXSlider.call_deferred("grab_focus")


# grab cue focus
func _on_cue_slider_mouse_entered() -> void:
	focusInfoRelay("CUE", CUEINFO)
	$VBox/CueGroup/CueSlider.call_deferred("grab_focus")


# grab deadzone focus
func _on_deadzone_up_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)
	$VBox/DeadzoneGroup/DeadzoneUp.call_deferred("grab_focus")


# grab deadzone focus
func _on_deadzone_down_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)
	$VBox/DeadzoneGroup/DeadzoneDown.call_deferred("grab_focus")


# grab escape button focus
func _on_escape_button_mouse_entered() -> void:
	focusInfoRelay("ESCAPE", EXITINFO)
	$VBox/Header/EscapeButton.call_deferred("grab_focus")



#### FOCUS ENTERED
# grab master group focus
func _on_master_slider_focus_entered() -> void:
	focusInfoRelay("MASTER", MASTERINFO) # focus grab
	$VBox/MasterGroup/MasterSlider.call_deferred("grab_click_focus")


# grab bgm focus
func _on_bgm_slider_focus_entered() -> void:
	focusInfoRelay("BGM", BGMINFO)
	$VBox/BGMGroup/BGMSlider.call_deferred("grab_click_focus")


# grab sfx focus
func _on_sfx_slider_focus_entered() -> void:
	focusInfoRelay("SFX", SFXINFO)
	$VBox/SFXGroup/SFXSlider.call_deferred("grab_click_focus")


# grab cue group focus
func _on_cue_slider_focus_entered() -> void:
	focusInfoRelay("CUE", CUEINFO)
	$VBox/CueGroup/CueSlider.call_deferred("grab_click_focus")


# grab deadzone focus
func _on_deadzone_up_focus_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)
	$VBox/DeadzoneGroup/DeadzoneUp.call_deferred("grab_click_focus")


# grab deadzone focus
func _on_deadzone_down_focus_entered() -> void:
	focusInfoRelay("DEADZONE", DEADZONEINFO)
	$VBox/DeadzoneGroup/DeadzoneDown.call_deferred("grab_click_focus")


# grab escape button focus
func _on_escape_button_focus_entered() -> void:
	focusInfoRelay("ESCAPE", EXITINFO)
	$VBox/Header/EscapeButton.call_deferred("grab_click_focus")



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
	if Globals.currentSettings.analogDeadzone - 0.01 >= Globals.MINDEADZONE:
		Globals.currentSettings.analogDeadzone -= 0.01
		updateText("DEADZONE", Globals.currentSettings.analogDeadzone)
		Globals.deadzoneUpdate()
		settingsChanged = true


# update deadzone levels
func _on_deadzone_up_pressed() -> void:
	if Globals.currentSettings.analogDeadzone + 0.01 <= Globals.MAXDEADZONE:
		Globals.currentSettings.analogDeadzone += 0.01
		updateText("DEADZONE", Globals.currentSettings.analogDeadzone)
		Globals.deadzoneUpdate()
		settingsChanged = true


# save data on escape
func _on_escape_button_pressed() -> void:
	returnToLastMenu()
