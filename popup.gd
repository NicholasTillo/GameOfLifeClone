extends Control

class_name Popup1

# Called when the node enters the scene tree for the first time.
var cell_num: int

func change_parent(to:Class):
	var state = GameManager.state
	state.cells[cell_num].contains = to
	state.cells[cell_num].contains.cell = state.cells[cell_num]
	GameManager.renderer.redraw()
	GameManager.ui.update_ui()
