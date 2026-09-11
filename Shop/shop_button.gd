extends Button


@export var button: Button

func _ready():
	button.pressed.connect(_button_pressed)
	#Cost read from the same resource the purchase charges, so the hover cannot drift.
	var grid_upgrade: Upgrade = load("res://Upgrades/GridSizeUpgrade1.tres")
	button.tooltip_text = \
			"Size Upgrade - %d money\nAdds one row and column to the main ship. Limited by Max Ship Size." \
			% grid_upgrade.cost

func _button_pressed():
	
	#Upgrades bought so far vs. the allowance. The old form (starter < full - max) was
	#off by one and let the player buy max + 1.
	if GameManager.state.full_grid_size - GameManager.state.starter_grid_size >= GameManager.max_number_size_upgrades:
			button.text = "Max Ship Size"
			GameOfLifeAudio.play_ui_disabled()
	else:
		PlayerController.purchase_grid_upgrade()
		
