extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Text_Maker.list_of_text(["Captain \n Its beautiful.", 
							"Cube 2 \n just working on the *important pods* now, it will be done within the year. ", 
							"Captain \n Hello Everybody my name is markiplier. "])
	Text_Maker.display_text("????CE - ?????")
