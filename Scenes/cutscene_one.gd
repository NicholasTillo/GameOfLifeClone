extends Node2D

var culm_time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if culm_time > 5: 
		get_tree().change_scene_to_file("res://Scenes/DeadScene.tscn")
		culm_time = 0.0
	else:
		culm_time += delta
