extends Control
class_name UIController

@export var texty:Label
@export var resource_text:Label

@export var buy_supship_one_button:Button
@export var buy_supship_one_size_upgrade_button:Button
@export var buy_supship_two_button:Button
@export var buy_supship_two_size_upgrade_button:Button

@export var vbox_ship_one: VBoxContainer
@export var vbox_ship_two: VBoxContainer

func _ready():
	GameManager.ui = self
	update_ui()
	buy_supship_one_button.pressed.connect(buy_supship_one)
	buy_supship_one_size_upgrade_button.pressed.connect(buy_supship_one_size_upgrade.bind(0))
	buy_supship_two_size_upgrade_button.pressed.connect(buy_supship_two_size_upgrade.bind(1))
	
	PlayerController.UI_controller = self
	
func update_ui():
	texty.text = "Money: " + str( GameManager.state.moneyAmount)
	resource_text.text = "Resource: " + str(GameManager.resourceAmount)


func buy_supship_one():
	var succeed = PlayerController.purchase_ship_upgrade(5)
	if succeed:
		buy_supship_one_button.visible = false
		vbox_ship_one.visible = true
		buy_supship_two_button.text =  "Purchase 
Subship 2:
1000 "
		buy_supship_two_button.pressed.connect(buy_supship_two)





func buy_supship_one_size_upgrade(value):
	var succeed = PlayerController.purchase_ship_size_upgrade(50, value)
	if succeed:
		#Play Sound
		pass 
	
func buy_supship_two_size_upgrade(value):
	var succeed = PlayerController.purchase_ship_size_upgrade(50, value)
	if succeed:
		#Play Sound
		pass 
		

func buy_supship_two():
	var succeed = PlayerController.purchase_ship_upgrade(10)
	if succeed:
		buy_supship_two_button.visible = false
		vbox_ship_two.visible = true


func diable_subship_size_upgrade(ship_num):
	if ship_num == 0:
		buy_supship_one_size_upgrade_button.text = "MAX SIZE"
		buy_supship_one_size_upgrade_button.pressed.disconnect((buy_supship_one_size_upgrade))
	else:
		buy_supship_two_size_upgrade_button.text = "MAX SIZE"
		buy_supship_two_size_upgrade_button.pressed.disconnect((buy_supship_two_size_upgrade))
