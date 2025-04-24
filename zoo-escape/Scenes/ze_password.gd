extends Node2D

@onready var Pos1 := Vector2(272, 160)
@onready var Pos2 := Vector2(304, 160)
@onready var Pos3 := Vector2(336, 160)
@onready var Pos4 := Vector2(272, 184)
@onready var Pos5 := Vector2(304, 184)
@onready var Pos6 := Vector2(336, 184)
@onready var Pos7 := Vector2(272, 208)
@onready var Pos8 := Vector2(304, 208)
@onready var Pos9 := Vector2(336, 208)
@onready var PosClear := Vector2(272, 232)
@onready var Pos0 := Vector2(304, 232)
@onready var PosEnter := Vector2(336, 232)
@onready var buttonMatrix := [[Pos1, Pos2, Pos3], [Pos4, Pos5, Pos6], [Pos7, Pos8, Pos9], [PosClear, Pos0, PosEnter]]
@onready var cursorPos := Vector2i.ZERO

@onready var selector := $Selector


func _ready() -> void:
	selector.position = buttonMatrix[cursorPos.y][cursorPos.x]

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("DigitalUp"):
		if cursorPos.y == 0:
			cursorPos.y = 3
		else:
			cursorPos.y -= 1
		
	if Input.is_action_just_pressed("DigitalRight"):
		if cursorPos.x == 2:
			cursorPos.x = 0
		else:
			cursorPos.x += 1
		
	if Input.is_action_just_pressed("DigitalDown"):
		if cursorPos.y == 3:
			cursorPos.y = 0
		else:
			cursorPos.y += 1
			
	if Input.is_action_just_pressed("DigitalLeft"):
		if cursorPos.x == 0:
			cursorPos.x = 2
		else:
			cursorPos.x -= 1
	
	selector.position = buttonMatrix[cursorPos.y][cursorPos.x]
