extends Node2D


# The tutorial images, shown one at a time in this order. Assign the 10 images
# here in the Inspector (drag them into the array). The tutorial advances on
# each mouse click and returns to the main menu after the last image.
@export var images: Array[Texture2D] = []

@onready var texture_rect: TextureRect = $Control/TextureRect

var index: int = 0


func _ready() -> void:
	# This scene's root is a Node2D, so Control anchors don't resolve to the
	# viewport size. Size the image to the viewport explicitly instead.
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)
	if not images.is_empty():
		texture_rect.texture = images[index]


func _fit_to_viewport() -> void:
	texture_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	texture_rect.position = Vector2.ZERO
	texture_rect.size = get_viewport().get_visible_rect().size


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		index += 1
		if index >= images.size():
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		else:
			texture_rect.texture = images[index]
