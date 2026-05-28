extends Label

@export var text_acc:Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_acc.text = "Next Goal: Round " + str((GameManager.current_cutscene_index + 1) * 20) # Replace with function body.
