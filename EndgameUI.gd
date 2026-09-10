extends Control

@export var end_label:Label



func _ready():
	end_label.text = " \n Game Over. You survived: " + str(GameManager.round_count) + " rounds \n"
	GameOfLifeAudio.play_lose()
