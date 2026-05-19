extends Button

@export var button: Button
@export var ui_Controller: UIController
var flip: bool
func _ready(): 
	button.pressed.connect(_button_pressed)

func _button_pressed():
	if flip:
		flip = false
		button.text = "Stop"
		GameManager.autoplay_enabled = true
	else:
		flip = true
		button.text = "Play"
		GameManager.autoplay_enabled = false
	
