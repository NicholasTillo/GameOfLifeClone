extends Button



@export var button: Button
@export var label: Label
func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	if GameManager.load_game():
		button.text = "Loaded Successfully"
	else:
		button.text = "Invalid Or Missing Save"
	label.update_ui()
	
