extends Control

@export var button1:Button
@export var button2:Button
@export var button3:Button
@export var close_button:Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_button.pressed.connect(func():queue_free()) # Replace with function body.
	
