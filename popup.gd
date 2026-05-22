extends Control

class_name Popup1

# Called when the node enters the scene tree for the first time.
var cell_num: int
@export var alive_button: Button
@export var dead_button: Button
@export var zombie_button: Button
@export var mechanic_button: Button
@export var chef_button: Button

func _ready() -> void:
	alive_button.pressed.connect(_button_pressed_alive)
	dead_button.pressed.connect(_button_pressed_dead)
	zombie_button.pressed.connect(_button_pressed_zombie)
	mechanic_button.pressed.connect(_button_pressed_mechanic)
	chef_button.pressed.connect(_button_pressed_chef)


func change_parent(to:Class):
	var state = GameManager.state
	state.cells[cell_num].contains = to
	state.cells[cell_num].contains.cell = state.cells[cell_num]
	GameManager.renderer.redraw()
	GameManager.ui.update_ui()


func _button_pressed_alive():
	if GameManager.state.cells[cell_num].contains.id  != "Alive" and GameManager.state.how_much_money() >= 10:
		GameManager.state.change_money(-10)
		change_parent(Alive.new())

func _button_pressed_dead():
	if GameManager.state.cells[cell_num].contains.id != "Dead":
		GameManager.state.change_money(10)
		change_parent(Dead.new())
		
		
func _button_pressed_zombie():
	GameManager.change_resource(-1)
	change_parent(Zombie.new())
	

func _button_pressed_mechanic():
	GameManager.change_resource(-1)
	change_parent(Mechanic.new())



func _button_pressed_chef():
	if GameManager.state.cells[cell_num].contains.id  != "Alive" and GameManager.state.how_much_money() >= 50:
		GameManager.state.change_money(50)
		change_parent(Chef.new())
	else:
		pass
