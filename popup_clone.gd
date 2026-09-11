extends Control

class_name Popu1


signal result_chosen(value)

# Called when the node enters the scene tree for the first time.
var cell_num: int

#The offers are built in code rather than laid out in the scene, because the list is not
#fixed: it is whatever the build menu can place (Popup1.PLACEABLE), and every Shop unlock
#adds another. A new cell needs one line in that list and nothing here.
const COLUMNS := 3
const BUTTON_SIZE := Vector2(112.0, 34.0)
const SEPARATION := 7
const MARGIN := 10

@export var background: ColorRect
@export var buttons: GridContainer


func _ready() -> void:
	buttons.columns = COLUMNS
	buttons.add_theme_constant_override("h_separation", SEPARATION)
	buttons.add_theme_constant_override("v_separation", SEPARATION)

	for id in Popup1.PLACEABLE:
		buttons.add_child(_offer_button(id))

	#Sized to whatever was just built, so the card always fits its offers however many
	#there turn out to be.
	var rows: int = ceili(float(Popup1.PLACEABLE.size()) / float(COLUMNS))
	var inner := Vector2(
			COLUMNS * BUTTON_SIZE.x + (COLUMNS - 1) * SEPARATION,
			rows * BUTTON_SIZE.y + (rows - 1) * SEPARATION)
	background.size = inner + Vector2(MARGIN, MARGIN) * 2.0
	buttons.position = Vector2(MARGIN, MARGIN)
	buttons.size = inner


func _offer_button(id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	#Ids are CamelCase so they survive the save file; capitalize() is what a player reads.
	var label: String = id.capitalize()
	#cell_unlocked() answers true for anything that never needed an unlock, so the always
	#available cells and the Shop ones go through the same question.
	if PlayerController.cell_unlocked(id):
		button.text = label
		button.pressed.connect(_choose.bind(id))
		button.tooltip_text = "Start a slot with a %s." % label
	else:
		button.text = "Locked"
		button.disabled = true
		button.tooltip_text = "Locked - unlock the %s in the Shop between runs." % label
	return button


func _choose(id: String) -> void:
	result_chosen.emit(GameManager.id_to_class(id))
	queue_free()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()
