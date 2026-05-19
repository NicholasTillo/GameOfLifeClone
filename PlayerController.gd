extends Node

@onready var start_money_upgrade1: Upgrade = load("res://Upgrades/StartingMoneyUpgrade.tres")
@onready var start_money_upgrade2: Upgrade = load("res://Upgrades/StartingMoneyUpgrade2.tres")
@onready var start_alive_count1: Upgrade = load("res://Upgrades/StartingChanceUpgrade.tres")


@onready var all_upgrades:Array = [start_money_upgrade1,start_money_upgrade2,start_alive_count1]

var chosen_upgrades:Array

func choose_upgrade(param_upgrade: Upgrade):
	chosen_upgrades.append(param_upgrade)

#Inside Of Game Upgrades
func purchase_grid_upgrade():
	var grid_upgrade: Upgrade = load("res://Upgrades/GridSizeUpgrade1.tres")
	if GameManager.state.how_much_money() > grid_upgrade.cost:
		chosen_upgrades.append(grid_upgrade)
		GameManager.state.resize_grid(1)
		GameManager.state.change_money(-grid_upgrade.cost)
		



#Outside Of Game Upgrades
func purchase_start_money_upgrade(upgrade:Upgrade):
		GameManager.chosen_upgrades["money_upgrades"].append(upgrade)
		GameManager.starting_money_increase += 10

	
func purchase_start_alive_count(upgrade:Upgrade):
	GameManager.chosen_upgrades["chance_upgrades"].append(upgrade)
	GameManager.starting_alive_chance += 0.1


	
	
