@abstract

extends RefCounted
class_name Class

var name1 = "text"
var id 
var color
var visual
var cell:Cell = null


func process_next_round():
	# No matter what this cell is, a Life neighbour turns it into Life.
	if cell != null:
		for i in cell.neighbours:
			if i.contains.id == "Life":
				return Life.new()
	return _process_next_round()


@abstract func _process_next_round()


func _init():
	assert(false, "don't instantiate me, dummy!")
