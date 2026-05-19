extends Button



@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	GameManager.reset()
	get_tree().change_scene_to_file("res://Scenes/shop_scene.tscn")
	
