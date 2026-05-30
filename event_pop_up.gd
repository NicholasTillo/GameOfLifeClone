extends Control


@export var name_label:Label
@export var description_label: Label
@export var okay_button: Button

var stored_popup_value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	okay_button.pressed.connect(close) # Replace with function body.\
	stored_popup_value = GameManager.autoplay_enabled
	GameManager.autoplay_enabled = false
func change_name(input_name):
	name_label.text = input_name
	
func change_text(input_text):
	description_label.text = input_text

func close():
	GameManager.autoplay_enabled = stored_popup_value
	queue_free()
