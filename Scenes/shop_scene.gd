extends Control


@export var button1:Button
@export var button2:Button
@export var button3:Button
@export var button4:Button
@export var button5:Button
@export var button6:Button
@export var button7:Button
@export var button8:Button
@export var button9:Button

@export var label1:Label
@export var label2:Label


@export var resource_label:Label





# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	
	
	if  PlayerController.start_money_upgrade1 in GameManager.chosen_upgrades["money_upgrades"]:
		button1.text = "Sold"
		button1.disabled = true
	else: 
		button1.text = str( PlayerController.start_money_upgrade1.cost)
		button1.disabled = false

	if  PlayerController.start_money_upgrade2 in GameManager.chosen_upgrades["money_upgrades"]:
		button2.text = "Sold"
		button2.disabled = true
	else:
		button2.text = str(PlayerController.start_money_upgrade2.cost)
		button2.disabled = false
		
	if  PlayerController.start_alive_count1 in GameManager.chosen_upgrades["chance_upgrades"]:
		button6.text = "Sold"
		button6.disabled = true
	else: 
		button6.text = str( PlayerController.start_alive_count1.cost)
		button6.disabled = false
	
	label1.text = "Starting Money Increase: " + str(GameManager.starting_money_increase)
	label2.text = "Starting Alive Chance Per Cell: " + str(GameManager.starting_alive_chance)
	
	button1.pressed.connect(purchase_start_money_upgrade1)
	button2.pressed.connect(purchase_start_money_upgrade2)
	
	button6.pressed.connect(purchase_start_alive_count1)
	



func purchase_start_money_upgrade1():
	if GameManager.resourceAmount >=   PlayerController.start_money_upgrade1.cost:
		PlayerController.purchase_start_money_upgrade( PlayerController.start_money_upgrade1)
		GameManager.change_resource(- PlayerController.start_money_upgrade1.cost)
		button1.text = "Sold"
		button1.disabled = true
	else:
		pass
	label1.text = "Starting Money Increase: " + str(GameManager.starting_money_increase)
	resource_label.update_ui()
	
func purchase_start_money_upgrade2():
	if GameManager.resourceAmount >=   PlayerController.start_money_upgrade2.cost:
		PlayerController.purchase_start_money_upgrade( PlayerController.start_money_upgrade2)
		GameManager.change_resource(- PlayerController.start_money_upgrade2.cost)
		button2.text = "Sold"
		button2.disabled = true
	else:
		pass
	label1.text = "Starting Money Increase: " + str(GameManager.starting_money_increase)
	resource_label.update_ui()

func purchase_start_money_upgrade3():
	resource_label.update_ui()
	
func purchase_start_money_upgrade4():
	resource_label.update_ui()
func purchase_start_money_upgrade5():
	resource_label.update_ui()
	
func purchase_start_alive_count1():
	if GameManager.resourceAmount >=   PlayerController.start_alive_count1.cost:
		PlayerController.purchase_start_alive_count( PlayerController.start_alive_count1)
		GameManager.change_resource(- PlayerController.start_alive_count1.cost)
		button6.text = "Sold"
		button6.disabled = true
	else:
		pass
	label2.text = "Starting Alive Chance Per Cell: " + str(float(GameManager.starting_alive_chance))
	
	
	resource_label.update_ui()
	
	resource_label.update_ui()

		
