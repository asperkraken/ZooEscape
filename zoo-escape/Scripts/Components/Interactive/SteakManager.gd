class_name SteakManager extends Node2D

@onready var steakTotal := 0

signal SteakCollected
signal AllSteaksCollected


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	steakTotal = get_child_count()
	for child in get_children():
		child.Collected.connect(steakCollected)


# called when a steak is collected
func steakCollected() -> void:
	steakTotal -= 1
	SteakCollected.emit()
	
	if steakTotal == 0:
		AllSteaksCollected.emit()
