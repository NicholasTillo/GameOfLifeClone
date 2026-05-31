extends Control

@export var end_label:Label



func _ready():
	end_label.text = "Game Over. You survived: " + str(GameManager.round_count) + " rounds"
	GameOfLifeAudio.play_lose()
