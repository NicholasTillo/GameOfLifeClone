extends Node

@onready var start_money_upgrade1: Upgrade = load("res://Upgrades/StartingMoneyUpgrade.tres")
@onready var start_money_upgrade2: Upgrade = load("res://Upgrades/StartingMoneyUpgrade2.tres")
@onready var start_money_upgrade3: Upgrade = load("res://Upgrades/StartingMoneyUpgrade3.tres")
@onready var start_money_upgrade4: Upgrade = load("res://Upgrades/StartingMoneyUpgrade4.tres")
@onready var start_money_upgrade5: Upgrade = load("res://Upgrades/StartingMoneyUpgrade5.tres")


@onready var start_alive_count1: Upgrade = load("res://Upgrades/StartingChanceUpgrade.tres")
@onready var start_alive_count2: Upgrade = load("res://Upgrades/StartingChanceUpgrade2.tres")
@onready var start_alive_count3: Upgrade = load("res://Upgrades/StartingChanceUpgrade3.tres")
@onready var start_alive_count4: Upgrade = load("res://Upgrades/StartingChanceUpgrade4.tres")
@onready var start_alive_count5: Upgrade = load("res://Upgrades/StartingChanceUpgrade5.tres")


@onready var starting_cell_1: Upgrade = load("res://Upgrades/StartingCellUpgrade1.tres")
@onready var starting_cell_2: Upgrade = load("res://Upgrades/StartingCellUpgrade2.tres")
@onready var starting_cell_3: Upgrade = load("res://Upgrades/StartingCellUpgrade3.tres")
@onready var starting_cell_4: Upgrade = load("res://Upgrades/StartingCellUpgrade4.tres")
@onready var starting_cell_5: Upgrade = load("res://Upgrades/StartingCellUpgrade5.tres")


@onready var all_upgrades:Array = [start_money_upgrade1,start_money_upgrade2,start_money_upgrade3,start_money_upgrade4,start_money_upgrade5,start_alive_count1,start_alive_count2,start_alive_count3,start_alive_count4,start_alive_count5,starting_cell_1,starting_cell_2,starting_cell_3,starting_cell_4,starting_cell_5]

var chosen_upgrades:Array


func choose_upgrade(param_upgrade: Upgrade):
	chosen_upgrades.append(param_upgrade)

#Inside Of Game Upgrades
func purchase_grid_upgrade():
	var grid_upgrade: Upgrade = load("res://Upgrades/GridSizeUpgrade1.tres")
	if GameManager.state.how_much_money() > grid_upgrade.cost:
		GameManager.state.resize_grid(1)
		GameManager.state.change_money(-grid_upgrade.cost)

func purchase_ship_upgrade(sub_ship_upgrade_cost):
	if GameManager.state.how_much_money() > sub_ship_upgrade_cost:
		GameManager.state.add_ship(5)
		GameManager.state.change_money(-sub_ship_upgrade_cost)
		return 1
	else:
		return 0
		#Play Sound

#Outside Of Game Upgrades
func purchase_start_money_upgrade(upgrade:Upgrade):
		GameManager.chosen_upgrades["money_upgrades"].append(upgrade)
		GameManager.starting_money_increase += 10

func purchase_start_alive_count(upgrade:Upgrade):
	print(upgrade)
	GameManager.chosen_upgrades["chance_upgrades"].append(upgrade)
	GameManager.starting_alive_chance += 0.1

func purchase_start_count(upgrade:Upgrade):
	GameManager.chosen_upgrades["starter_upgrades"].append(upgrade)
	GameManager.starting_slots += 1
	GameManager.slots.append(Dead.new())
	
	
