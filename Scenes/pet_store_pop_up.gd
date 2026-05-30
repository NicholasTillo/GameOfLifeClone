extends Control

@export var button1:Button
@export var button2:Button
@export var button3:Button
@export var close_button:Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_button.pressed.connect(func():queue_free()) # Replace with function body.
	button1.pressed.connect(spawn_pet_1) 
	button2.pressed.connect(spawn_pet_2) 
	button3.pressed.connect(spawn_pet_3) 
	

func spawn_pet_1():
	var chosen_cell = GameManager.state.cells.pick_random()
	chosen_cell.contains = Sandshark.new()
	chosen_cell.contains.cell = chosen_cell
func spawn_pet_2():
	var chosen_cell = GameManager.state.cells.pick_random()
	chosen_cell.contains = Plorian.new()
	chosen_cell.contains.cell = chosen_cell
func spawn_pet_3():
	var chosen_cell = GameManager.state.cells.pick_random()
	chosen_cell.contains = Dog.new()
	chosen_cell.contains.cell = chosen_cell
