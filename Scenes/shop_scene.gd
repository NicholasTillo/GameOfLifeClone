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
@export var button16:Button
@export var button17:Button
@export var button18:Button
@export var button19:Button
@export var button20:Button
@export var button21:Button
@export var button22:Button
@export var button23:Button
@export var button24:Button
@export var button25:Button
@export var button26:Button
@export var button27:Button
@export var button28:Button
@export var button29:Button
@export var button30:Button
@export var button31:Button
@export var button32:Button
@export var button33:Button
@export var button34:Button
@export var button35:Button

@export var label1:Label
@export var label2:Label
@export var label3:Label
@export var label4:Label
@export var label5:Label


@export var resource_label:Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_buttons()
	update_shop_ui()
	
func update_button(upgrade, button: Button, category: String, upgrade_name: String = ""):
	var prefix = upgrade_name + "\n" if upgrade_name != "" else ""
	if upgrade in GameManager.chosen_upgrades[category]:
		button.text = prefix + "Sold"
		button.disabled = true
	else:
		button.text = prefix + str(upgrade.cost)
		button.disabled = false

func update_shop_ui():
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
	update_button(PlayerController.max_ship_size_upgrade_1, button16, "max_ship_size_upgrade")
	update_button(PlayerController.max_ship_size_upgrade_2, button17, "max_ship_size_upgrade")
	update_button(PlayerController.max_ship_size_upgrade_3, button18, "max_ship_size_upgrade")
	update_button(PlayerController.max_ship_size_upgrade_4, button19, "max_ship_size_upgrade")
	update_button(PlayerController.max_ship_size_upgrade_5, button20, "max_ship_size_upgrade")
	update_button(PlayerController.starter_ship_size_upgrade_1, button21, "starter_ship_size_upgrade")
	update_button(PlayerController.starter_ship_size_upgrade_2, button22, "starter_ship_size_upgrade")
	update_button(PlayerController.starter_ship_size_upgrade_3, button23, "starter_ship_size_upgrade")
	update_button(PlayerController.starter_ship_size_upgrade_4, button24, "starter_ship_size_upgrade")
	update_button(PlayerController.starter_ship_size_upgrade_5, button25, "starter_ship_size_upgrade")


	update_button(PlayerController.unlock_chef_upgrade, button26, "unlock_cells", "Chef")
	update_button(PlayerController.unlock_innovator_upgrade, button27, "unlock_cells", "Innovator")

	#Only Chef and Innovator exist as profession upgrades; the remaining slots have no
	#Upgrade resource behind them, so don't show buttons that can't do anything.
	button28.visible = false
	button29.visible = false
	button30.visible = false

	update_button(PlayerController.unlock_rewind_upgrade, button31, "unlock_rewind")
	update_button(PlayerController.unlock_rewind_upgrade2, button32, "unlock_rewind")
	update_button(PlayerController.unlock_rewind_upgrade3, button33, "unlock_rewind")
	update_button(PlayerController.unlock_rewind_upgrade4, button34, "unlock_rewind")
	update_button(PlayerController.unlock_rewind_upgrade5, button35, "unlock_rewind")

	update_ui_shop()


#Wiring is done once from _ready(); update_shop_ui() re-runs after every purchase
#and must not reconnect these signals.
func connect_buttons():
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

	button16.pressed.connect(purchase_max_ship_size.bind(PlayerController.max_ship_size_upgrade_1, button16))
	button17.pressed.connect(purchase_max_ship_size.bind(PlayerController.max_ship_size_upgrade_2, button17))
	button18.pressed.connect(purchase_max_ship_size.bind(PlayerController.max_ship_size_upgrade_3, button18))
	button19.pressed.connect(purchase_max_ship_size.bind(PlayerController.max_ship_size_upgrade_4, button19))
	button20.pressed.connect(purchase_max_ship_size.bind(PlayerController.max_ship_size_upgrade_5, button20))

	button21.pressed.connect(purchase_starter_ship_size.bind(PlayerController.starter_ship_size_upgrade_1, button21))
	button22.pressed.connect(purchase_starter_ship_size.bind(PlayerController.starter_ship_size_upgrade_2, button22))
	button23.pressed.connect(purchase_starter_ship_size.bind(PlayerController.starter_ship_size_upgrade_3, button23))
	button24.pressed.connect(purchase_starter_ship_size.bind(PlayerController.starter_ship_size_upgrade_4, button24))
	button25.pressed.connect(purchase_starter_ship_size.bind(PlayerController.starter_ship_size_upgrade_5, button25))
	
	
	button26.pressed.connect(purchase_new_cell.bind(PlayerController.unlock_chef_upgrade, button26))
	button27.pressed.connect(purchase_new_cell.bind(PlayerController.unlock_innovator_upgrade, button27))

	button31.pressed.connect(purchase_rewind.bind(PlayerController.unlock_rewind_upgrade, button31))
	button32.pressed.connect(purchase_rewind.bind(PlayerController.unlock_rewind_upgrade2, button32))
	button33.pressed.connect(purchase_rewind.bind(PlayerController.unlock_rewind_upgrade3, button33))
	button34.pressed.connect(purchase_rewind.bind(PlayerController.unlock_rewind_upgrade4, button34))
	button35.pressed.connect(purchase_rewind.bind(PlayerController.unlock_rewind_upgrade5, button35))
	

func purchase_upgrade(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_start_money_upgrade(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()


func purchase_alive_count(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_start_alive_count(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()

func purchase_starting_cell(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_start_count(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()

func purchase_max_ship_size(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_max_ship_size_upgrade(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()

func purchase_starter_ship_size(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_starter_ship_size_upgrade(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()
	
func purchase_new_cell(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_unlock_cell(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()

func purchase_rewind(upgrade, button: Button):
	if GameManager.resourceAmount >= upgrade.cost:
		PlayerController.purchase_rewind(upgrade)
		GameManager.change_resource(-upgrade.cost)
		GameOfLifeAudio.play_purchase()
	else:
		GameOfLifeAudio.play_ui_disabled()

	update_shop_ui()


func update_ui_shop():
	label1.text = "Starting Money Increase: " + str(GameManager.starting_money_increase)
	label2.text = "Starting Alive Chance Per Cell: " + str(float(GameManager.starting_alive_chance))
	label3.text = "Starting Cell Slots: " + str(float(GameManager.starting_slots))
	label4.text = "Max Ship Size: " + str(float(GameManager.state.starter_grid_size + GameManager.max_number_size_upgrades))
	label5.text = "Starter Ship Size: " + str(float(GameManager.state.starter_grid_size))
	resource_label.update_ui()
	
