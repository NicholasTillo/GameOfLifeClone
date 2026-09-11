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

@onready var max_ship_size_upgrade_1: Upgrade = load("res://Upgrades/MaxShipSizeUpgrade.tres")
@onready var max_ship_size_upgrade_2: Upgrade = load("res://Upgrades/MaxShipSizeUpgrade2.tres")
@onready var max_ship_size_upgrade_3: Upgrade = load("res://Upgrades/MaxShipSizeUpgrade3.tres")
@onready var max_ship_size_upgrade_4: Upgrade = load("res://Upgrades/MaxShipSizeUpgrade4.tres")
@onready var max_ship_size_upgrade_5: Upgrade = load("res://Upgrades/MaxShipSizeUpgrade5.tres")



@onready var starter_ship_size_upgrade_1: Upgrade = load("res://Upgrades/StarterShipSizeUpgrade.tres")
@onready var starter_ship_size_upgrade_2: Upgrade = load("res://Upgrades/StarterShipSizeUpgrade2.tres")
@onready var starter_ship_size_upgrade_3: Upgrade = load("res://Upgrades/StarterShipSizeUpgrade3.tres")
@onready var starter_ship_size_upgrade_4: Upgrade = load("res://Upgrades/StarterShipSizeUpgrade4.tres")
@onready var starter_ship_size_upgrade_5: Upgrade = load("res://Upgrades/StarterShipSizeUpgrade5.tres")

@onready var unlock_chef_upgrade: Upgrade = load("res://Upgrades/UnlockChef.tres")
@onready var unlock_innovator_upgrade: Upgrade = load("res://Upgrades/UnlockInnovator.tres")

@onready var unlock_rewind_upgrade: Upgrade = load("res://Upgrades/unlock_rewind.tres")
@onready var unlock_rewind_upgrade2: Upgrade = load("res://Upgrades/unlock_rewind2.tres")
@onready var unlock_rewind_upgrade3: Upgrade = load("res://Upgrades/unlock_rewind3.tres")
@onready var unlock_rewind_upgrade4: Upgrade = load("res://Upgrades/unlock_rewind4.tres")
@onready var unlock_rewind_upgrade5: Upgrade = load("res://Upgrades/unlock_rewind5.tres")



@onready var all_upgrades:Array = [start_money_upgrade1,start_money_upgrade2,start_money_upgrade3,start_money_upgrade4,start_money_upgrade5,
									start_alive_count1,start_alive_count2,start_alive_count3,start_alive_count4,start_alive_count5,
									starting_cell_1,starting_cell_2,starting_cell_3,starting_cell_4,starting_cell_5,
									max_ship_size_upgrade_1,max_ship_size_upgrade_2,max_ship_size_upgrade_3,max_ship_size_upgrade_4,max_ship_size_upgrade_5,
									starter_ship_size_upgrade_1,starter_ship_size_upgrade_2,starter_ship_size_upgrade_3,starter_ship_size_upgrade_4,starter_ship_size_upgrade_5,
									unlock_chef_upgrade,unlock_innovator_upgrade,
									unlock_rewind_upgrade, unlock_rewind_upgrade2, unlock_rewind_upgrade3,unlock_rewind_upgrade4,unlock_rewind_upgrade5]


var UI_controller: UIController
var chosen_upgrades:Array

var main_ship_size_upgrade_number: int
var sub_ship_size_upgrade_number: Array = [0,0]
var sub_ship_taxes_upgrade_number: Array = [0,0]



func choose_upgrade(param_upgrade: Upgrade):
	chosen_upgrades.append(param_upgrade)

#Inside Of Game Upgrades
func purchase_grid_upgrade():
	var grid_upgrade: Upgrade = load("res://Upgrades/GridSizeUpgrade1.tres")
	#>=, not >: the subship path already charges on exactly the price, and with a round
	#cost like 50 the player lands on it exactly all the time.
	if GameManager.state.how_much_money() >= grid_upgrade.cost:
		if GameManager.renderer.popup_enabled:
			GameManager.renderer.popup.queue_free()
			GameManager.renderer.popup_enabled = false
		
		GameManager.state.cells = GameManager.state.resize_grid(1,  GameManager.state.cells, GameManager.state.full_grid_size)
		GameManager.state.full_grid_size += 1
		
		GameManager.state.change_money(-grid_upgrade.cost)
		GameOfLifeAudio.play_purchase()
		return 1
	else:
		GameOfLifeAudio.play_ui_disabled()
		return 0


#Outside Game Upgrades
func purchase_ship_upgrade(sub_ship_upgrade_cost):
	if GameManager.state.how_much_money() >= sub_ship_upgrade_cost:
		GameManager.state.add_ship(5)
		GameManager.state.change_money(-sub_ship_upgrade_cost)
		GameManager.renderer.redraw()
		GameOfLifeAudio.play_purchase()
		return 1
	else:
		GameOfLifeAudio.play_ui_disabled()
		return 0
		#Play Sound

func purchase_ship_size_upgrade(sub_ship_upgrade_cost, subship_num):
	#Subships share the main ship's size-upgrade allowance, so the Max Ship Size
	#shop upgrades raise the cap here too.
	if GameManager.state.how_much_money() >= sub_ship_upgrade_cost && sub_ship_size_upgrade_number[subship_num] < GameManager.max_number_size_upgrades:
		if GameManager.renderer.popup_enabled:
			GameManager.renderer.popup.queue_free()
			GameManager.renderer.popup_enabled = false
		GameManager.state.change_money(-sub_ship_upgrade_cost)
		GameManager.state.subgrids[subship_num] = GameManager.state.resize_grid(1, GameManager.state.subgrids[subship_num], GameManager.state.subgrid_sizes[subship_num])
		GameManager.state.subgrid_sizes[subship_num] += 1
		sub_ship_size_upgrade_number[subship_num] += 1
		if sub_ship_size_upgrade_number[subship_num] >= GameManager.max_number_size_upgrades:
			#Disable Button
			UI_controller.diable_subship_size_upgrade(subship_num)
		GameOfLifeAudio.play_purchase()
		return 1
	else:
		GameOfLifeAudio.play_ui_disabled()
		return 0


#Taxes Upgrade
func purchase_main_ship_taxes_upgrade(upgrade_cost):
	if GameManager.state.how_much_money() > upgrade_cost:
		if GameManager.renderer.popup_enabled:
			GameManager.renderer.popup.queue_free()
			GameManager.renderer.popup_enabled = false
			
		GameManager.money_per_alive += 0.1
		GameManager.state.change_money(-upgrade_cost)
		GameOfLifeAudio.play_purchase()
		return 1
	else:
		GameOfLifeAudio.play_ui_disabled()
		return 0


#Free in-run upgrades, granted by the Spaceship Upgrade Bay event.
func grant_free_grid_upgrade():
	GameManager.state.cells = GameManager.state.resize_grid(1, GameManager.state.cells, GameManager.state.full_grid_size)
	GameManager.state.full_grid_size += 1
	GameManager.renderer.redraw()
	GameOfLifeAudio.play_purchase()


func grant_free_ship_upgrade():
	GameManager.state.add_ship(5)
	GameManager.renderer.redraw()
	GameOfLifeAudio.play_purchase()


func grant_free_ship_taxes_upgrade():
	GameManager.money_per_alive += 0.1
	GameOfLifeAudio.play_purchase()


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
	
	
func purchase_max_ship_size_upgrade(upgrade:Upgrade):
	GameManager.chosen_upgrades["max_ship_size_upgrade"].append(upgrade)
	GameManager.max_number_size_upgrades += 1
	
func purchase_starter_ship_size_upgrade(upgrade:Upgrade):
	GameManager.chosen_upgrades["starter_ship_size_upgrade"].append(upgrade)
	GameManager.state.starter_grid_size += 1

func purchase_unlock_cell(upgrade:Upgrade):
	GameManager.chosen_upgrades["unlock_cells"].append(upgrade)


func purchase_rewind(upgrade:Upgrade):
	GameManager.chosen_upgrades["unlock_rewind"].append(upgrade)
	GameManager.rewind_number += 1
	
	
