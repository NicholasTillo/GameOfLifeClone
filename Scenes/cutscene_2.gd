extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.

@export var audioPlayer: AudioStreamPlayer


func _ready() -> void:
	Text_Maker.list_of_text(["Captain \n Hello, I'm about to die, bring on my legacy, tell me when we meet in heaven.", 
							"Captain 2. \n Okay I will keep your legacy going dad. ", 
							"Captain \n *died*. "])
	Text_Maker.display_text("2084CE - Outside of the Skoopa Galaxy")

	fade_in(audioPlayer, -20.0, 4.0)


func fade_in(player: AudioStreamPlayer, target_db: float = 0.0, duration: float = 1.0) -> void:
		player.volume_db = -80.0   # effectively silent
		if not player.playing:
				player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", target_db, duration)
