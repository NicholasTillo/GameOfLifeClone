extends HBoxContainer


var current_chosen_button: int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(GameManager.starting_slots): # Replace with function body.
		var obects = Button.new()
		obects.text = "i: " +str(i)
		obects.pressed.connect(_on_button_pressed.bind(i))
		add_child(obects)
		
func _on_button_pressed(value):
	var popup_scene = preload("res://popup_copy.tscn")
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	#This is the bodgiest bodge ever, dont judge me it just works, stupid though
	popup.position = position + get_parent().position + get_parent().get_parent().position + get_parent().get_parent().get_parent().position
	popup.result_chosen.connect(_on_result_chosen)
	current_chosen_button = value


func _on_result_chosen(value:Class):
	GameManager.slots[current_chosen_button] = value
	
	
