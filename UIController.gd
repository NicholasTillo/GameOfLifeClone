extends Control
class_name UIController

@export var texty:Label
@export var resource_text:Label


func _ready():
	GameManager.ui = self
	update_ui()
	
func update_ui():
	texty.text = "Money: " + str( GameManager.state.moneyAmount)
	resource_text.text = "Resource: " + str(GameManager.resourceAmount)
