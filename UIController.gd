extends Control
class_name UIController

const SUBSHIP_ONE_COST: int = 5
const SUBSHIP_TWO_COST: int = 10
#Size upgrades get dearer the further out the ship is, indexed by subship number - the
#same 0/1 the buttons bind below. The MAIN ship's size upgrade is not here: it is priced
#by Upgrades/GridSizeUpgrade1.tres, which both PlayerController.purchase_grid_upgrade()
#and the button's own tooltip read (Shop/shop_button.gd).
const SUBSHIP_SIZE_COST: Array[int] = [150, 300]
const TAXES_UPGRADE_COST: int = 50
#What one Raise Taxes buys, per PlayerController.purchase_main_ship_taxes_upgrade.
const TAXES_PER_UPGRADE: float = 0.1

#Generation counter goes red the round before an event lands, as a warning.
const GENERATION_COLOR := Color(1, 1, 1)
const GENERATION_WARNING_COLOR := Color(1, 0.25, 0.25)

@export var texty:Label
@export var resource_text:Label
@export var generation_label:Label
@export var milestone_label:Label

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
	#Priced from the constants below, not the scene, so the label can't drift from the
	#actual cost the way it had (500 shown / 5 charged, 1000 shown / 10 charged).
	buy_supship_one_button.text = "Purchase\nSubship 1:\n%d" % SUBSHIP_ONE_COST
	buy_supship_one_button.pressed.connect(buy_supship_one)
	#Both subships go through one handler - they only ever differed by the bound number.
	buy_supship_one_size_upgrade_button.pressed.connect(buy_subship_size_upgrade.bind(0))
	buy_supship_two_size_upgrade_button.pressed.connect(buy_subship_size_upgrade.bind(1))
	
	#All three Raise Taxes buttons were exported but only the main ship's was ever
	#connected, so the two subship ones did nothing at all when clicked. They raise the
	#same global money_per_alive, so they share the one handler.
	buy_ship_taxes_upgrade_button.pressed.connect(buy_ship_taxes_upgrade)
	buy_supship_one_taxes_upgrade_button.pressed.connect(buy_ship_taxes_upgrade)
	buy_supship_two_taxes_upgrade_button.pressed.connect(buy_ship_taxes_upgrade)

	if GameManager.rewind_number > 0:
		do_rewind_button.disabled = false
		do_rewind_button.visible = true
		do_rewind_button.pressed.connect(do_rewind)

	_set_tooltips()
	PlayerController.UI_controller = self


#Hover costs for the in-run ship shop, built from the consts above so a tooltip can never
#advertise a price the button does not charge. tooltip_text is the built-in Control hover.
func _set_tooltips() -> void:
	buy_supship_one_button.tooltip_text = \
			"Subship 1 - %d money\nA second, separate 5x5 grid that runs its own generations." % SUBSHIP_ONE_COST
	buy_supship_two_button.tooltip_text = \
			"Subship 2 - %d money\nA third grid. Requires Subship 1 first." % SUBSHIP_TWO_COST

	var size_tip := "Size Upgrade - %d money\nAdds one row and column to this ship. Limited by Max Ship Size."
	buy_supship_one_size_upgrade_button.tooltip_text = size_tip % SUBSHIP_SIZE_COST[0]
	buy_supship_two_size_upgrade_button.tooltip_text = size_tip % SUBSHIP_SIZE_COST[1]

	var taxes_tip := "Raise Taxes - %d money\nEvery surviving crew member pays +%.1f money a round, for the rest of the run." \
			% [TAXES_UPGRADE_COST, TAXES_PER_UPGRADE]
	buy_ship_taxes_upgrade_button.tooltip_text = taxes_tip
	buy_supship_one_taxes_upgrade_button.tooltip_text = taxes_tip
	buy_supship_two_taxes_upgrade_button.tooltip_text = taxes_tip

	do_rewind_button.tooltip_text = \
			"Rewind - free\nSteps the board back one round. %d left this run, and none once an event has fired." \
			% GameManager.rewind_number

func update_ui():
	texty.text = money_text(GameManager.state.moneyAmount)
	resource_text.text = "Resource: " + str(GameManager.resourceAmount)
	_update_generation()


#Money is kept as a float - Raise Taxes pays out in tenths - but the player is shown a whole
#number. Floored rather than rounded, because every purchase compares against the true
#amount: on 9.7 you cannot afford a 10 cell, and a label reading "10" would make the refusal
#look like a bug.
static func money_text(amount: float) -> String:
	return "Money: %d" % floori(amount)


#The generation counter and the line under it. Both read GameManager's pacing constants, so
#they cannot drift from the rules they describe.
func _update_generation() -> void:
	if generation_label == null:
		return
	generation_label.text = "Generation %d" % GameManager.round_count
	#Red the round before an event lands - the next step will trigger one.
	generation_label.add_theme_color_override("font_color",
			GENERATION_WARNING_COLOR if GameManager.event_next_round() else GENERATION_COLOR)

	if milestone_label == null:
		return
	var milestone := GameManager.next_cutscene_round()
	if milestone < 0:
		milestone_label.text = "The story is told. Survive as long as you can."
	elif GameManager.round_count >= milestone:
		milestone_label.text = "Next chapter reached - it plays when the run ends"
	else:
		var togo := milestone - GameManager.round_count
		milestone_label.text = "%d generation%s to the next chapter" % [togo, "" if togo == 1 else "s"]


func buy_supship_one():
	var succeed = PlayerController.purchase_ship_upgrade(SUBSHIP_ONE_COST)
	if succeed:
		buy_supship_one_button.visible = false
		vbox_ship_one.visible = true
		buy_supship_two_button.text = "Purchase\nSubship 2:\n%d" % SUBSHIP_TWO_COST
		buy_supship_two_button.pressed.connect(buy_supship_two)
	else: 
		GameOfLifeAudio.play_ui_disabled()


func buy_subship_size_upgrade(subship_num: int):
	if not PlayerController.purchase_ship_size_upgrade(SUBSHIP_SIZE_COST[subship_num], subship_num):
		GameOfLifeAudio.play_ui_disabled()


func buy_ship_taxes_upgrade():
	var succeed = PlayerController.purchase_main_ship_taxes_upgrade(TAXES_UPGRADE_COST)
	if succeed:
		#Play Sound
		pass 
	else: 
		GameOfLifeAudio.play_ui_disabled()
		
		
func buy_supship_two():
	var succeed = PlayerController.purchase_ship_upgrade(SUBSHIP_TWO_COST)
	if succeed:
		buy_supship_two_button.visible = false
		vbox_ship_two.visible = true
	else: 
		GameOfLifeAudio.play_ui_disabled()

func do_rewind():
	# Once an event has triggered this run, the button stays visible but does nothing.
	if GameManager.rewind_blocked:
		GameOfLifeAudio.play_ui_disabled()
		return
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
