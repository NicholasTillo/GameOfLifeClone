extends Control
class_name UIController

@export var texty:Label
@export var resource_text:Label

@export var buy_supship_one_button:Button
@export var buy_supship_one_size_upgrade_button:Button
@export var buy_supship_two_button:Button
@export var buy_supship_two_size_upgrade_button:Button

@export var buy_supship_one_taxes_upgrade_button:Button
@export var buy_supship_two_taxes_upgrade_button:Button

@export var buy_ship_taxes_upgrade_button:Button


@export var do_rewind_button: Button

@export var vbox_ship_one: VBoxContainer
@export var vbox_ship_two: VBoxContainer

func _ready():
	GameManager.ui = self
	update_ui()
	buy_supship_one_button.pressed.connect(buy_supship_one)
	buy_supship_one_size_upgrade_button.pressed.connect(buy_supship_one_size_upgrade.bind(0))
	buy_supship_two_size_upgrade_button.pressed.connect(buy_supship_two_size_upgrade.bind(1))
	
	buy_ship_taxes_upgrade_button.pressed.connect(buy_ship_taxes_upgrade)
	
	
	
	print(GameManager.rewind_number)
	if GameManager.rewind_number > 0:
		do_rewind_button.disabled = false
		do_rewind_button.visible = true
		do_rewind_button.pressed.connect(do_rewind)
		
	
	
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
	else: 
		GameOfLifeAudio.play_ui_disabled()


func buy_supship_one_size_upgrade(value):
	var succeed = PlayerController.purchase_ship_size_upgrade(50, value)
	if succeed:
		pass
	else: 
		GameOfLifeAudio.play_ui_disabled()
	
func buy_supship_two_size_upgrade(value):
	var succeed = PlayerController.purchase_ship_size_upgrade(50, value)
	if succeed:
		#Play Sound
		pass 
	else: 
		GameOfLifeAudio.play_ui_disabled()
		
		
func buy_ship_taxes_upgrade():
	var succeed = PlayerController.purchase_main_ship_taxes_upgrade(50)
	if succeed:
		#Play Sound
		pass 
	else: 
		GameOfLifeAudio.play_ui_disabled()
		
		
func buy_supship_two():
	var succeed = PlayerController.purchase_ship_upgrade(10)
	if succeed:
		buy_supship_two_button.visible = false
		vbox_ship_two.visible = true
	else: 
		GameOfLifeAudio.play_ui_disabled()

func do_rewind():
	# Once an event has triggered this run, the button stays visible but does nothing.
	if GameManager.rewind_blocked:
		GameOfLifeAudio.play_ui_disabled()	
	# Need at least [previous, current] in the history to step back a turn.
	if GameManager.done_rewinds < GameManager.rewind_number and GameManager.history.size() >= 2:
		GameManager.history.pop_back()
		GameManager.prev_states.pop_back()
		GameManager.restore_snapshot(GameManager.history.back())  # restore the previous turn
		GameManager.done_rewinds += 1
		GameOfLifeAudio.play_rewind()
	else: 
		GameOfLifeAudio.play_ui_disabled()	

func diable_subship_size_upgrade(ship_num):
	if ship_num == 0:
		buy_supship_one_size_upgrade_button.text = "Max Ship Size"
	else:
		buy_supship_two_size_upgrade_button.text = "Max Ship Size"
