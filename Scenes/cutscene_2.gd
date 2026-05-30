extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Text_Maker.list_of_text(["Captain \n Hello, im about to die, bring on my legacy, tell me when we meet in heaven.", 
							"Captain 2. \n Okay I will keep youre legacy going dad. ", 
							"Captain \n *died*. "])
	Text_Maker.display_text("2084CE - Outside of the Skoopa Galaxy")
