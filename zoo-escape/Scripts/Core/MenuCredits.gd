extends Control

# Signals
signal GoBack

@onready var credits := $RichTextLabel
@onready var back := $MarginContainer/BackButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	credits.connect("meta_clicked", OnNameClick)
	back.connect("button_up", returnToLastMenu)
	back.grab_focus()


# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	if !visible || !event.is_pressed() || event.is_echo():
		return


# Called when user clicks a link in RichTextLabel
func OnNameClick(meta: Variant) -> void:
	OS.shell_open(meta)


# Called by the MenuManager to show this window
func showMenu() -> void:
	back.call_deferred("grab_focus")
	show()


# Called to return to the last menu
func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	GoBack.emit() # Bye!
