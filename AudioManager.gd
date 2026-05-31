extends Node
class_name AudioManager

## Central place to play sound effects and music.


const SFX_PLAYER_COUNT := 8

var music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_index := 0

var sfx_ui_click: AudioStream = null
var sfx_ui_disabled: AudioStream = load("res://Assets/UI_Disabled.mp3")
var sfx_button_hover: AudioStream = null #Looping bzz sound. 
var sfx_purchase: AudioStream = load("res://Assets/Purchase.mp3")
var sfx_error: AudioStream = null
var sfx_cell_born: AudioStream = null
var sfx_cell_died: AudioStream = null
var sfx_generation_step: AudioStream = null
var sfx_rewind: AudioStream = load("res://Assets/Rewind.mp3")
var sfx_event_popup: AudioStream = null
var sfx_pet_buy: AudioStream = null
var sfx_win: AudioStream = null
var sfx_lose: AudioStream = load("res://Assets/Loss.mp3")

var music_menu: AudioStream = null
var music_gameplay: AudioStream = null


func _ready() -> void:
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)

	# Pool of SFX players
	for i in SFX_PLAYER_COUNT:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer%d" % i
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)



## Play a one-shot sound effect on the next free player in the pool.
func play_sfx(stream: AudioStream, volume_db: float = -20.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var player := _get_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


## Play (or switch) looping background music.
func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func _get_sfx_player() -> AudioStreamPlayer:
	# Prefer a player that isn't currently busy.
	for p in _sfx_players:
		if not p.playing:
			return p
	# All busy: round-robin reuse the oldest.
	var p := _sfx_players[_next_sfx_index]
	_next_sfx_index = (_next_sfx_index + 1) % _sfx_players.size()
	return p



func play_ui_click() -> void:
	play_sfx(sfx_ui_click)

func play_ui_disabled() -> void:
	play_sfx(sfx_ui_disabled)

func play_button_hover() -> void:
	play_sfx(sfx_button_hover)

func play_purchase() -> void:
	play_sfx(sfx_purchase)

func play_error() -> void:
	play_sfx(sfx_error)

func play_cell_born() -> void:
	play_sfx(sfx_cell_born)

func play_cell_died() -> void:
	play_sfx(sfx_cell_died)

func play_generation_step() -> void:
	play_sfx(sfx_generation_step)

func play_rewind() -> void:
	play_sfx(sfx_rewind)

func play_event_popup() -> void:
	play_sfx(sfx_event_popup)

func play_pet_buy() -> void:
	play_sfx(sfx_pet_buy)

func play_win() -> void:
	play_sfx(sfx_win)

func play_lose() -> void:
	play_sfx(sfx_lose)

func play_menu_music() -> void:
	play_music(music_menu)

func play_gameplay_music() -> void:
	play_music(music_gameplay)
