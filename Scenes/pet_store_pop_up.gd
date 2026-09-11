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
	_spawn_pet(Sandshark.new())


func spawn_pet_2():
	_spawn_pet(Plorian.new())


func spawn_pet_3():
	_spawn_pet(Dog.new())


#One pet per visit: the popup closes on the pick. Without this the buttons stayed live
#and the player could spawn unlimited permanent blockers.
func _spawn_pet(pet: Class) -> void:
	var chosen_cell = GameManager.state.cells.pick_random()
	chosen_cell.contains = pet
	chosen_cell.contains.cell = chosen_cell
	GameManager.renderer.redraw()
	queue_free()
