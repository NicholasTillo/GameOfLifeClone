extends Label
@export var resource_text:Label


func _ready():
	update_ui()

func update_ui():
	resource_text.text = "Resource: " + str(GameManager.resourceAmount)
	
