extends Control
class_name UIController

@export var texty:Label
@export var resource_text:Label

@export var buy_supship_one_button:Button
@export var buy_supship_two_button:Button

@export var vbox_ship_one: VBoxContainer
@export var vbox_ship_two: VBoxContainer

func _ready():
	GameManager.ui = self
	update_ui()
	buy_supship_one_button.pressed.connect(buy_supship_one)
	buy_supship_two_button.pressed.connect(buy_supship_two)
	
	
func update_ui():
	texty.text = "Money: " + str( GameManager.state.moneyAmount)
	resource_text.text = "Resource: " + str(GameManager.resourceAmount)


func buy_supship_one():
	var succeed = PlayerController.purchase_ship_upgrade(5)
	if succeed:
		buy_supship_one_button.visible = false
		vbox_ship_one.visible = true

func buy_supship_two():
	var succeed = PlayerController.purchase_ship_upgrade(1000)
	if succeed:
		buy_supship_two_button.visible = false
		vbox_ship_two.visible = true
		
