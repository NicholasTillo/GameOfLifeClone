extends Control


@export var name_label:Label
@export var description_label: Label
@export var okay_button: Button

 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	okay_button.pressed.connect(close) # Replace with function body.

func change_name(input_name):
	name_label.text = input_name
	
func change_text(input_text):
	description_label.text = input_text

func close():
	queue_free()
