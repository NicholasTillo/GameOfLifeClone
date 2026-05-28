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
@export var button10:Button
@export var button11:Button
@export var button12:Button
@export var button13:Button
@export var button14:Button
@export var button15:Button



@export var label1:Label
@export var label2:Label
@export var label3:Label

@export var resource_label:Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui_shopeeeeee()
	
func update_button(upgrade, button: Button, category: String):
	if upgrade in GameManager.chosen_upgrades[category]:
		button.text = "Sold"
		button.disabled = true
	else:
		button.text = str(upgrade.cost)
		button.disabled = false

func update_ui_shopeeeeee():
	update_button(PlayerController.start_money_upgrade1, button1, "money_upgrades")
	update_button(PlayerController.start_money_upgrade2, button2, "money_upgrades")
	update_button(PlayerController.start_money_upgrade3, button3, "money_upgrades")
	update_button(PlayerController.start_money_upgrade4, button4, "money_upgrades")
	update_button(PlayerController.start_money_upgrade5, button5, "money_upgrades")
	update_button(PlayerController.start_alive_count1, button6, "chance_upgrades")
	update_button(PlayerController.start_alive_count2, button7, "chance_upgrades")
	update_button(PlayerController.start_alive_count3, button8, "chance_upgrades")
	update_button(PlayerController.start_alive_count4, button9, "chance_upgrades")
	update_button(PlayerController.start_alive_count5, button10, "chance_upgrades")
	update_button(PlayerController.starting_cell_1, button11, "starter_upgrades")
	update_button(PlayerController.starting_cell_2, button12, "starter_upgrades")
	update_button(PlayerController.starting_cell_3, button13, "starter_upgrades")
	update_button(PlayerController.starting_cell_4, button14, "starter_upgrades")
	update_button(PlayerController.starting_cell_5, button15, "starter_upgrades")
	
	
	button1.pressed.connect(purchase_upgrade.bind(PlayerController.start_money_upgrade1, button1))
	button2.pressed.connect(purchase_upgrade.bind(PlayerController.start_money_upgrade2, button2))
	button3.pressed.connect(purchase_upgrade.bind(PlayerController.start_money_upgrade3, button3))
	button4.pressed.connect(purchase_upgrade.bind(PlayerController.start_money_upgrade4, button4))
	button5.pressed.connect(purchase_upgrade.bind(PlayerController.start_money_upgrade5, button5))
	
	button6.pressed.connect(purchase_alive_count.bind(PlayerController.start_alive_count1, button6))
	button7.pressed.connect(purchase_alive_count.bind(PlayerController.start_alive_count2, button7))
	button8.pressed.connect(purchase_alive_count.bind(PlayerController.start_alive_count3, button8))
	button9.pressed.connect(purchase_alive_count.bind(PlayerController.start_alive_count4, button9))
	button10.pressed.connect(purchase_alive_count.bind(PlayerController.start_alive_count5, button10))
	
	button11.pressed.connect(purchase_starting_cell.bind(PlayerController.starting_cell_1, button11))
	button12.pressed.connect(purchase_starting_cell.bind(PlayerController.starting_cell_2, button12))
	button13.pressed.connect(purchase_starting_cell.bind(PlayerController.starting_cell_3, button13))
	button14.pressed.connect(purchase_starting_cell.bind(PlayerController.starting_cell_4, button14))
	button15.pressed.connect(purchase_starting_cell.bind(PlayerController.starting_cell_5, button15))
	
	update_ui_shop()
	

func purchase_upgrade(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_start_money_upgrade(upgrade)
		GameManager.change_resource(-upgrade.cost)
		button.text = "Sold"
		button.disabled = true
	update_ui_shop()


func purchase_alive_count(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_start_alive_count(upgrade)
		GameManager.change_resource(-upgrade.cost)
		button.text = "Sold"
		button.disabled = true
	update_ui_shop()

func purchase_starting_cell(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_start_count(upgrade)
		GameManager.change_resource(-upgrade.cost)
		button.text = "Sold"
		button.disabled = true
	update_ui_shop()

func update_ui_shop():
	label1.text = "Starting Money Increase: " + str(GameManager.starting_money_increase)
	label2.text = "Starting Alive Chance Per Cell: " + str(float(GameManager.starting_alive_chance))
	label3.text = "Starting Cell Slots: " + str(float(GameManager.starting_slots))
	resource_label.update_ui()
	
