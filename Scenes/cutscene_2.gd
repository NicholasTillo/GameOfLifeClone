extends Node2D

var culm_time = 0

@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.

@export var audioPlayer: AudioStreamPlayer


func _ready() -> void:
	Text_Maker.list_of_text(["Captain Glart \n My son, I'm about to die, carry on my legacy, find the signal.", 
							"Lieutenant Kele. \n I will keep your legacy going dad. I will search for her.", 
							"Captain Glart \n I have enjoyed my time as captian of this ship, meeting all these people. I regret nothing, live on as I have"])
	Text_Maker.display_text("2084CE - Outside of the Skoopa Galaxy - Medical Bay")

	fade_in(audioPlayer, -20.0, 4.0)


func fade_in(player: AudioStreamPlayer, target_db: float = 0.0, duration: float = 1.0) -> void:
		player.volume_db = -80.0   # effectively silent
		if not player.playing:
				player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", target_db, duration)
