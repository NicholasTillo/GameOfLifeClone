extends Control

class_name Popup1

# Called when the node enters the scene tree for the first time.
var cell_num: int
var grid_index: int = -1
@export var alive_button: Button
@export var dead_button: Button
@export var mechanic_button: Button
@export var innovator_button: Button
@export var chef_button: Button
@export var wall_button:Button
@export var doctor_button:Button
@export var robot_button:Button
@export var nuclear_engineer_button:Button
@export var captain_button:Button


var stored_popup_value: bool

#Every price in this popup, in one place. The tooltips below are built from these same
#consts, so a hover can never advertise a price the button does not actually charge.
const COST_ALIVE := 10
const COST_WALL := 10
const COST_CHEF := 50
const COST_DOCTOR := 25
const COST_ROBOT := 30
const COST_NUCLEAR_ENGINEER := 50
const COST_CAPTAIN := 150
#Money, not resource: the Mechanic is how resource gets made, so pricing it in resource
#stranded a player on 0 resource with no way to earn any back.
const COST_MECHANIC := 75
const REFUND_DEAD := 10             #clearing a cell pays this back
const COST_INNOVATOR_RESOURCE := 1

#Every cell the player can put on the board, in build-menu order. The starter-slot picker
#offers exactly this list, so the two menus cannot drift apart - a cell added to one shows
#up in the other. Dead is deliberately absent: it is the clear-this-berth action, and an
#unfilled starter slot already holds one.
#Freely available first, then the four Shop unlocks, so the locked buttons sit together at
#the end of both menus instead of being scattered through them.
const PLACEABLE := ["Alive", "Mechanic", "Wall", "Doctor", "Robot",
		"Innovator", "Chef", "NuclearEngineer", "Captain"]


func _ready() -> void:
	alive_button.pressed.connect(_button_pressed_alive)
	dead_button.pressed.connect(_button_pressed_dead)
	mechanic_button.pressed.connect(_button_pressed_mechanic)
	if PlayerController.cell_unlocked("Innovator"):
		innovator_button.pressed.connect(_button_pressed_innovator)
	else:
		innovator_button.text = "locked"
	if PlayerController.cell_unlocked("Chef"):
		chef_button.pressed.connect(_button_pressed_chef)
	else:
		chef_button.text = "locked"
	if PlayerController.cell_unlocked("NuclearEngineer"):
		nuclear_engineer_button.pressed.connect(_button_pressed_nuclear_engineer)
	else:
		nuclear_engineer_button.text = "locked"
	if PlayerController.cell_unlocked("Captain"):
		captain_button.pressed.connect(_button_pressed_captain)
	else:
		captain_button.text = "locked"
	wall_button.pressed.connect(_button_pressed_wall)
	doctor_button.pressed.connect(_button_pressed_doctor)
	robot_button.pressed.connect(_button_pressed_robot)
	stored_popup_value = GameManager.autoplay_enabled
	_set_tooltips()


#Hover text for every cell button: what it costs and what it does. tooltip_text is the
#built-in Control hover tooltip, so there is no hover handling to write.
func _set_tooltips() -> void:
	alive_button.tooltip_text = "Alive - %d money\nA crew member. Pays you every round it survives." % COST_ALIVE
	dead_button.tooltip_text = "Clear - refunds %d money\nEmpties the cell. Anyone there is gone." % REFUND_DEAD
	mechanic_button.tooltip_text = "Mechanic - %d money\nEarns +%d resource a round. Dies with no crew beside it." % [COST_MECHANIC, Mechanic.PAYOUT]
	wall_button.tooltip_text = "Wall - %d money\nNever changes. Shapes patterns and blocks fire." % COST_WALL
	doctor_button.tooltip_text = "Doctor - %d money\nLives and earns like crew, and raises the bodies beside it." % COST_DOCTOR
	robot_button.tooltip_text = "Robot - %d money\nCounts as crew to its neighbours, and seizes up with no Mechanic aboard." % COST_ROBOT

	if innovator_button.pressed.is_connected(_button_pressed_innovator):
		innovator_button.tooltip_text = "Innovator - %d resource\nEarns +%d money a round. Dies with no crew beside it." % [COST_INNOVATOR_RESOURCE, Innovator.PAYOUT]
	else:
		innovator_button.tooltip_text = "Locked - unlock the Innovator in the Shop between runs."
	if captain_button.pressed.is_connected(_button_pressed_captain):
		captain_button.tooltip_text = "Captain - %d money\nWhile one is aboard every crew member earns +%d, and a doomed one in four is spared." % [COST_CAPTAIN, Captain.MONEY_BONUS]
	else:
		captain_button.tooltip_text = "Locked - unlock the Captain in the Shop between runs."
	if nuclear_engineer_button.pressed.is_connected(_button_pressed_nuclear_engineer):
		nuclear_engineer_button.tooltip_text = "Nuclear Engineer - %d money\nCrew, and earns %d resource a round for every Robot beside it." % [COST_NUCLEAR_ENGINEER, NuclearEngineer.RESOURCE_PER_ROBOT]
	else:
		nuclear_engineer_button.tooltip_text = "Locked - unlock the Nuclear Engineer in the Shop between runs."
	if chef_button.pressed.is_connected(_button_pressed_chef):
		chef_button.tooltip_text = "Chef - %d money\nKeeps every neighbour alive, but eats %d money a round." % [COST_CHEF, Chef.UPKEEP]
	else:
		chef_button.tooltip_text = "Locked - unlock the Chef in the Shop between runs."

func _get_cell() -> Cell:
	var state = GameManager.state
	if grid_index == -1:
		return state.cells[cell_num]
	else:
		return state.subgrids[grid_index][cell_num]


func change_parent(to:Class):
	#Through replace_cell so clearing a living crew member back to Dead floats a skull
	#like any other death - the player did kill them. grid_index already matches its
	#convention (-1 main grid, 0/1 subship).
	GameManager.replace_cell(_get_cell(), to, grid_index)
	GameManager.renderer.redraw()
	GameManager.ui.update_ui()
	GameManager.renderer.popup_enabled = false

	queue_free()


func _button_pressed_alive():
	var cell = _get_cell()
	if cell.contains.id  != "Alive" and GameManager.state.how_much_money() >= COST_ALIVE:
		GameManager.state.change_money(-COST_ALIVE)
		change_parent(Alive.new())
	else:
		GameOfLifeAudio.play_ui_disabled()

		
func _button_pressed_dead():
	var cell = _get_cell()
	if cell.contains.id != "Dead":
		GameManager.state.change_money(REFUND_DEAD)
		change_parent(Dead.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
		
func _button_pressed_mechanic():
	var cell = _get_cell()
	if cell.contains.id  != "Mechanic" and GameManager.state.how_much_money() >= COST_MECHANIC:
		GameManager.state.change_money(-COST_MECHANIC)
		change_parent(Mechanic.new())
	else:
		GameOfLifeAudio.play_ui_disabled()

func _button_pressed_innovator():
	var cell = _get_cell()
	if cell.contains.id  != "Innovator" and GameManager.how_much_resource() >= COST_INNOVATOR_RESOURCE:
		GameManager.change_resource(-COST_INNOVATOR_RESOURCE)
		change_parent(Innovator.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
func _button_pressed_wall():
	var cell = _get_cell()
	if cell.contains.id  != "Wall" and GameManager.state.how_much_money() >= COST_WALL:
		GameManager.state.change_money(-COST_WALL)
		change_parent(Wall.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
func _button_pressed_chef():
	var cell = _get_cell()
	if cell.contains.id  != "Chef" and GameManager.state.how_much_money() >= COST_CHEF:
		GameManager.state.change_money(-COST_CHEF)
		change_parent(Chef.new())
	else:
		GameOfLifeAudio.play_ui_disabled()


func _button_pressed_doctor():
	var cell = _get_cell()
	if cell.contains.id  != "Doctor" and GameManager.state.how_much_money() >= COST_DOCTOR:
		GameManager.state.change_money(-COST_DOCTOR)
		change_parent(Doctor.new())
	else:
		GameOfLifeAudio.play_ui_disabled()


func _button_pressed_robot():
	var cell = _get_cell()
	if cell.contains.id  != "Robot" and GameManager.state.how_much_money() >= COST_ROBOT:
		GameManager.state.change_money(-COST_ROBOT)
		change_parent(Robot.new())
	else:
		GameOfLifeAudio.play_ui_disabled()


func _button_pressed_nuclear_engineer():
	var cell = _get_cell()
	if cell.contains.id  != "NuclearEngineer" and GameManager.state.how_much_money() >= COST_NUCLEAR_ENGINEER:
		GameManager.state.change_money(-COST_NUCLEAR_ENGINEER)
		change_parent(NuclearEngineer.new())
	else:
		GameOfLifeAudio.play_ui_disabled()


func _button_pressed_captain():
	var cell = _get_cell()
	if cell.contains.id  != "Captain" and GameManager.state.how_much_money() >= COST_CAPTAIN:
		GameManager.state.change_money(-COST_CAPTAIN)
		change_parent(Captain.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
