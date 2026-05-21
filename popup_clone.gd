extends Control

class_name Popu1


signal result_chosen(value)

# Called when the node enters the scene tree for the first time.
var cell_num: int
@export var button1:Button
@export var button2:Button
@export var button3:Button
@export var button4:Button


func _ready() -> void:
	button1.pressed.connect(button1_func)
	button2.pressed.connect(button2_func)
	button3.pressed.connect(button3_func)
	button4.pressed.connect(button4_func)

func button1_func():
	var return_class = (Alive.new())
	result_chosen.emit(return_class)
	button1.text = return_class.id
	queue_free()
	
	
func button2_func():
	var return_class = (Dead.new())
	result_chosen.emit(return_class)
	button2.text = return_class.id
	queue_free()
	
	
func button3_func():
	var return_class = (Zombie.new())
	result_chosen.emit(return_class)
	button3.text = return_class.id
	queue_free()
	
	
func button4_func():
	var return_class = (Mechanic.new())
	button4.text = return_class.id
	result_chosen.emit(return_class)
	queue_free()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()
		
