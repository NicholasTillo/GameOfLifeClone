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
@export var springtrap_button: Button
@export var wall_button:Button
@export var life_button:Button
@export var revolutionary_button:Button


var stored_popup_value: bool

#Every price in this popup, in one place. The tooltips below are built from these same
#consts, so a hover can never advertise a price the button does not actually charge.
const COST_ALIVE := 10
const COST_SPRINGTRAP := 10
const COST_WALL := 10
const COST_LIFE := 10
const COST_REVOLUTIONARY := 10
const COST_CHEF := 50
const REFUND_DEAD := 10             #clearing a cell pays this back
const COST_MECHANIC_RESOURCE := 1
const COST_INNOVATOR_RESOURCE := 1


func _ready() -> void:
	alive_button.pressed.connect(_button_pressed_alive)
	dead_button.pressed.connect(_button_pressed_dead)
	mechanic_button.pressed.connect(_button_pressed_mechanic)
	if PlayerController.unlock_innovator_upgrade in GameManager.chosen_upgrades["unlock_cells"]:
		innovator_button.pressed.connect(_button_pressed_innovator)
	else:
		innovator_button.text = "locked"
	if PlayerController.unlock_chef_upgrade in GameManager.chosen_upgrades["unlock_cells"]:
		chef_button.pressed.connect(_button_pressed_chef)
	else:
		chef_button.text = "locked"
	springtrap_button.pressed.connect(_button_pressed_springtrap)
	wall_button.pressed.connect(_button_pressed_wall)
	life_button.pressed.connect(_button_pressed_life)
	revolutionary_button.pressed.connect(_button_pressed_revolutionary)
	stored_popup_value = GameManager.autoplay_enabled
	_set_tooltips()


#Hover text for every cell button: what it costs and what it does. tooltip_text is the
#built-in Control hover tooltip, so there is no hover handling to write.
func _set_tooltips() -> void:
	alive_button.tooltip_text = "Alive - %d money\nA crew member. Pays you every round it survives." % COST_ALIVE
	dead_button.tooltip_text = "Clear - refunds %d money\nEmpties the cell. Anyone there is gone." % REFUND_DEAD
	mechanic_button.tooltip_text = "Mechanic - %d resource\nEarns +1 resource a round. Dies with no crew beside it." % COST_MECHANIC_RESOURCE
	wall_button.tooltip_text = "Wall - %d money\nNever changes. Shapes patterns and blocks fire." % COST_WALL
	springtrap_button.tooltip_text = "Springtrap - %d money\nKills crew around it for 7 rounds, then dies." % COST_SPRINGTRAP
	life_button.tooltip_text = "Life - %d money\nSpreads to every neighbour, forever." % COST_LIFE
	revolutionary_button.tooltip_text = "Revolutionary - %d money\nPays nothing, and converts the crew beside it." % COST_REVOLUTIONARY

	if innovator_button.pressed.is_connected(_button_pressed_innovator):
		innovator_button.tooltip_text = "Innovator - %d resource\nEarns +1 money a round. Dies with no crew beside it." % COST_INNOVATOR_RESOURCE
	else:
		innovator_button.tooltip_text = "Locked - unlock the Innovator in the Shop between runs."
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
	if cell.contains.id  != "Mechanic" and GameManager.how_much_resource() >= COST_MECHANIC_RESOURCE:
		GameManager.change_resource(-COST_MECHANIC_RESOURCE)
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
func _button_pressed_springtrap():
	var cell = _get_cell()
	if cell.contains.id  != "Springtrap" and GameManager.state.how_much_money() >= COST_SPRINGTRAP:
		GameManager.state.change_money(-COST_SPRINGTRAP)
		change_parent(Springtrap.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
	
func _button_pressed_wall():
	var cell = _get_cell()
	if cell.contains.id  != "Wall" and GameManager.state.how_much_money() >= COST_WALL:
		GameManager.state.change_money(-COST_WALL)
		change_parent(Wall.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
func _button_pressed_life():
	var cell = _get_cell()
	if cell.contains.id  != "Life" and GameManager.state.how_much_money() >= COST_LIFE:
		GameManager.state.change_money(-COST_LIFE)
		change_parent(Life.new())
	else:
		GameOfLifeAudio.play_ui_disabled()

func _button_pressed_revolutionary():
	var cell = _get_cell()
	if cell.contains.id  != "Revolutionary" and GameManager.state.how_much_money() >= COST_REVOLUTIONARY:
		GameManager.state.change_money(-COST_REVOLUTIONARY)
		change_parent(Revolutionary.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
	
func _button_pressed_chef():
	var cell = _get_cell()
	if cell.contains.id  != "Chef" and GameManager.state.how_much_money() >= COST_CHEF:
		GameManager.state.change_money(-COST_CHEF)
		change_parent(Chef.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
