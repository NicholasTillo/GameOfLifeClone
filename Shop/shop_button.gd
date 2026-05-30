extends Button


@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	PlayerController.purchase_grid_upgrade()
	if GameManager.state.starter_grid_size < GameManager.state.full_grid_size - GameManager.max_number_size_upgrades:
			button.pressed.disconnect(_button_pressed)
			button.text = "Max Ship Size"
