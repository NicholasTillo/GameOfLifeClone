extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.

@export var audioPlayer: AudioStreamPlayer
var cutscene5_audio = load("res://Scenes/cutscene_5.gd") 


func _ready() -> void:
	Text_Maker.list_of_text(["Captain ???? \n Its beautiful.", 
							"Captain \n Hello Everybody my name is markiplier. "])
	Text_Maker.display_text("????CE - ?????")
	audioPlayer.stream = cutscene5_audio
	audioPlayer.play()
	
	fade_in(audioPlayer, -20.0, 4.0)


func fade_in(player: AudioStreamPlayer, target_db: float = 0.0, duration: float = 1.0) -> void:
		player.volume_db = -80.0   # effectively silent
		if not player.playing:
				player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", target_db, duration)
