extends Button



@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	if GameManager.save_game():
		button.text = "Saved!"
	
