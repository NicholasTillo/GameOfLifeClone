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
	
func _get_cell() -> Cell:
	var state = GameManager.state
	if grid_index == -1:
		return state.cells[cell_num]
	else:
		return state.subgrids[grid_index][cell_num]


func change_parent(to:Class):
	var cell = _get_cell()
	cell.contains = to
	cell.contains.cell = cell
	GameManager.renderer.redraw()
	GameManager.ui.update_ui()
	GameManager.renderer.popup_enabled = false

	queue_free()


func _button_pressed_alive():
	var cell = _get_cell()
	if cell.contains.id  != "Alive" and GameManager.state.how_much_money() >= 10:
		GameManager.state.change_money(-10)
		change_parent(Alive.new())
	else:
		GameOfLifeAudio.play_ui_disabled()

		
func _button_pressed_dead():
	var cell = _get_cell()
	if cell.contains.id != "Dead":
		GameManager.state.change_money(10)
		change_parent(Dead.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
		
func _button_pressed_mechanic():
	var cell = _get_cell()
	if cell.contains.id  != "Mechanic" and GameManager.how_much_resource() >= 1:
		GameManager.change_resource(-1)
		change_parent(Mechanic.new())
	else:
		GameOfLifeAudio.play_ui_disabled()

func _button_pressed_innovator():
	var cell = _get_cell()
	if cell.contains.id  != "Innovator" and GameManager.how_much_resource() >= 1:
		GameManager.change_resource(-1)
		change_parent(Innovator.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
func _button_pressed_springtrap():
	var cell = _get_cell()
	if cell.contains.id  != "Springtrap" and GameManager.state.how_much_money() >= 10:
		GameManager.state.change_money(-10)
		change_parent(Springtrap.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
	
func _button_pressed_wall():
	var cell = _get_cell()
	if cell.contains.id  != "Wall" and GameManager.state.how_much_money() >= 10:
		GameManager.state.change_money(-10)
		change_parent(Wall.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
func _button_pressed_life():
	var cell = _get_cell()
	if cell.contains.id  != "Life" and GameManager.state.how_much_money() >= 10:
		GameManager.state.change_money(-10)
		change_parent(Life.new())
	else:
		GameOfLifeAudio.play_ui_disabled()

func _button_pressed_revolutionary():
	var cell = _get_cell()
	if cell.contains.id  != "Revolutionary" and GameManager.state.how_much_money() >= 10:
		GameManager.state.change_money(-10)
		change_parent(Revolutionary.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
	
func _button_pressed_chef():
	var cell = _get_cell()
	if cell.contains.id  != "Chef" and GameManager.state.how_much_money() >= 50:
		GameManager.state.change_money(-50)
		change_parent(Chef.new())
	else:
		GameOfLifeAudio.play_ui_disabled()
