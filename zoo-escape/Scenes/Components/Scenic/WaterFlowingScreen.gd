extends Node2D


func _ready() -> void:
	randomize()
	var children = get_children()
	for child in children:
		child.play("default")
		child.speed_scale = (1+randf_range(-0.20,0.20))
