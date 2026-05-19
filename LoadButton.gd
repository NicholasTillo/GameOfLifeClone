extends Button



@export var button: Button
@export var label: Label
func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	GameManager.load_game()
	label.update_ui()
	
