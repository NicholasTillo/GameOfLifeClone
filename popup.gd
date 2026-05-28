extends Control

class_name Popup1

# Called when the node enters the scene tree for the first time.
var cell_num: int
var grid_index: int = -1
@export var alive_button: Button
@export var dead_button: Button
@export var zombie_button: Button
@export var mechanic_button: Button
@export var chef_button: Button
@export var springtrap_button: Button
@export var wall_button:Button

func _ready() -> void:
	alive_button.pressed.connect(_button_pressed_alive)
	dead_button.pressed.connect(_button_pressed_dead)
	zombie_button.pressed.connect(_button_pressed_zombie)
	mechanic_button.pressed.connect(_button_pressed_mechanic)
	chef_button.pressed.connect(_button_pressed_chef)
	springtrap_button.pressed.connect(_button_pressed_springtrap)
	wall_button.pressed.connect(_button_pressed_wall)
	

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
		

func _button_pressed_dead():
	var cell = _get_cell()
	if cell.contains.id != "Dead":
		GameManager.state.change_money(10)
		change_parent(Dead.new())
		
		
func _button_pressed_zombie():
	GameManager.change_resource(-1)
	change_parent(Zombie.new())
	

func _button_pressed_mechanic():
	GameManager.change_resource(-1)
	change_parent(Mechanic.new())

func _button_pressed_springtrap():
	GameManager.state.change_money(-10)
	change_parent(Springtrap.new())
	
	
func _button_pressed_wall():
	GameManager.state.change_money(-10)
	change_parent(Wall.new())
	
	
	
	
func _button_pressed_chef():
	var cell = _get_cell()
	if cell.contains.id  != "Alive" and GameManager.state.how_much_money() >= 50:
		GameManager.state.change_money(50)
		change_parent(Chef.new())
	else:
		pass
