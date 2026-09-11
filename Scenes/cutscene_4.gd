extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.


@export var audioPlayer: AudioStreamPlayer

func _ready() -> void:
	Text_Maker.list_of_text(["Captain Cup \n Captain Marque gave up on the mission that I will resume, buried it for thousands of years, For those who come after us, We are going across the edge of the universe.", 
							"Captain Cup \n There is no way to know what lies beyond, but we shall find out in memory of those who came before us. "])
	Text_Maker.display_text("~5230CE - The Edge Of The Universe")

	fade_in(audioPlayer, -20.0, 4.0)


func fade_in(player: AudioStreamPlayer, target_db: float = 0.0, duration: float = 1.0) -> void:
		player.volume_db = -80.0   # effectively silent
		if not player.playing:
				player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", target_db, duration)
