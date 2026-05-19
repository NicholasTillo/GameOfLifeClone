extends Button



@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	GameManager.save_game()
	
