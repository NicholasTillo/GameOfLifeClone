extends Button

@export var button: Button
@export var ui_Controller: UIController

func _ready(): 
	button.pressed.connect(_button_pressed)

func _button_pressed():
	GameOfLifeAudio.play_do_one()
	GameManager.do_next_round()
	ui_Controller.update_ui()
	
