extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text


@export var audioPlayer: AudioStreamPlayer
var cutscene1_audio = load("res://Scenes/cutscene_1.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Text_Maker.list_of_text(["Captain \n Hello mr engineer how is the construction coming along.", 
							"Cube 2 \n just working on the *important pods* now, it will be done within the year. ", 
							"Captain \n Hello Everybody my name is markiplier. "])
	
	Text_Maker.display_text("2026CE - Earth")

	fade_in(audioPlayer, 0.0, 4.0)


func fade_in(player: AudioStreamPlayer, target_db: float = 0.0, duration: float = 1.0) -> void:
		player.volume_db = -80.0   # effectively silent
		if not player.playing:
				player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", target_db, duration)
