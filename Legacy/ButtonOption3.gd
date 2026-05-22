extends Button

@export var s:Popup1
@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	GameManager.change_resource(-1)
	s.change_parent(Zombie.new())

	pass
