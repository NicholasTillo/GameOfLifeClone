extends Control

class_name CellGiftPopUp


#A "pick one, free" card: three cell types on offer, the chosen one lands on the ship and
#the card closes. The offers and the blurb are handed in by whoever opens it, so one scene
#can serve any event that hands the player a free crewmate.
var _offers: Array = []

@export var button1:Button
@export var button2:Button
@export var button3:Button
@export var close_button:Button
@export var text_label:Label


#Call this straight after instantiate(), before adding it to the tree. `offers` is three
#Class ids, which double as the button labels.
func configure(blurb: String, offers: Array) -> void:
	_offers = offers
	text_label.text = blurb
	var buttons: Array = [button1, button2, button3]
	for i in range(buttons.size()):
		buttons[i].text = offers[i]
		buttons[i].pressed.connect(_grant.bind(offers[i]))
	close_button.pressed.connect(queue_free)


#One gift per visit: the card closes on the pick. Without that the buttons stay live and
#the player can keep taking until the board is full - the same hole the pet store had.
func _grant(id: String) -> void:
	var chosen_cell = GameManager.state.cells.pick_random()
	chosen_cell.contains = GameManager.id_to_class(id)
	chosen_cell.contains.cell = chosen_cell
	#The pick is part of the event, and events cannot be rewound past.
	GameManager.init_history()
	GameManager.renderer.redraw()
	queue_free()
