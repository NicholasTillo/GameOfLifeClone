extends HBoxContainer


const PICKER_SCENE := preload("res://popup_copy.tscn")

var current_chosen_button: int = 0
#The open picker, if any. Tracked so clicking a second slot cannot leave two cards on
#screen: both would be wired to _on_result_chosen, and a pick from the stale one would land
#in whichever slot was clicked most recently rather than its own.
var _picker: Popu1 = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(GameManager.starting_slots):
		var obects = Button.new()
		obects.text = _slot_label(i)
		obects.pressed.connect(_on_button_pressed.bind(i))
		add_child(obects)


func _on_button_pressed(value):
	current_chosen_button = value
	_close_picker()

	_picker = PICKER_SCENE.instantiate()
	#Parented to the current SCENE, not get_tree().root. A card on the root Window is not
	#owned by the menu, so change_scene_to_file() never frees it and pressing Play carried
	#the picker into the run, still floating over the board.
	get_tree().current_scene.add_child(_picker)
	#global_position puts it under the slot button without hand-summing the offsets of
	#every ancestor between here and the scene root.
	_picker.global_position = get_child(value).global_position + Vector2(0.0, size.y)
	_picker.result_chosen.connect(_on_result_chosen)


func _close_picker() -> void:
	if is_instance_valid(_picker):
		_picker.queue_free()
	_picker = null


func _on_result_chosen(value:Class):
	GameManager.slots[current_chosen_button] = value
	get_child(current_chosen_button).text = _slot_label(current_chosen_button)
	#The picker frees itself on a pick; drop the reference so _close_picker() is not left
	#holding a freed node.
	_picker = null


#A slot the player has not filled in still holds the Dead placeholder purchase_start_count
#appended, so read the label straight off the stored cell rather than tracking it twice.
func _slot_label(i:int) -> String:
	var contains = GameManager.slots[i]
	return "Empty" if contains == null or contains.id == "Dead" else contains.id.capitalize()
