extends AnimatedSprite2D


# Track the state of the switch: 0 = off, 1 = on
@export_enum ("OFF", "ON") var buttonState: int = 0

# Array to store handles to controlled children in
var controlledChildren: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame = buttonState
	for child in self.get_children():
		if child != $ButtonArea:
			controlledChildren.append(child)

# Body entered the Button's Area
func _on_area_2d_body_entered(_body: Node2D) -> void:
		SoundControl.playCue(SoundControl.scratch,1.2)
		toggle_children()

# Body exited the Button's Area
func _on_area_2d_body_exited(_body: Node2D) -> void:
		SoundControl.playCue(SoundControl.scratch,1.5)
		toggle_children()


# for areas like box enter
func _on_button_area_area_entered(_area: Area2D) -> void:
	SoundControl.playCue(SoundControl.scuff,1.0)
	toggle_children()


# for areas like box exit
func _on_button_area_area_exited(_area: Area2D) -> void:
	SoundControl.playCue(SoundControl.scuff,0.9)
	toggle_children()


func toggle_children() -> void:
	frame = buttonState
	if controlledChildren:
		for child: Node in controlledChildren:
			child.changeState()
