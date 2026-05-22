extends Label

@export var resource_text:Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resource_text.text = "Best Round: " + str(GameManager.best_score)
