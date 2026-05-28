extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Text_Maker.list_of_text(["Who the hell is cube 1", "Idk who is cube 2"])
	Text_Maker.display_text("Cutscene 1 Stuff")
	Text_Maker.on_finish_list()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if culm_time > 5: 
		get_tree().change_scene_to_file("res://Scenes/DeadScene.tscn")
		culm_time = 0.0
	else:
		culm_time += delta
