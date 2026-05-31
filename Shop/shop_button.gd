extends Button


@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	
	if GameManager.state.starter_grid_size < GameManager.state.full_grid_size - GameManager.max_number_size_upgrades:
			button.text = "Max Ship Size"
			GameOfLifeAudio.play_ui_disabled()
	else:
		PlayerController.purchase_grid_upgrade()
		
