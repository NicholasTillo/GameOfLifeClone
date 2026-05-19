extends Button

@export var s:Popup1
@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
func _button_pressed():
	
	if GameManager.state.cells[s.cell_num].contains.id != "Dead":
		GameManager.state.change_money(10)
		s.change_parent(Dead.new())
		
	pass
