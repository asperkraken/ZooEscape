extends Control

@onready var credits := $RichTextLabel
@onready var back := $MarginContainer/BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	credits.connect("meta_clicked", OnNameClick)
	back.connect("button_up", BackClicked)
	back.grab_focus()


func OnNameClick(meta: Variant) -> void:
	OS.shell_open(meta)


func BackClicked() -> void:
	SceneManager.goToNewSceneString(Scenes.TITLE)
