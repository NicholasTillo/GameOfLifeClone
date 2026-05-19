@abstract

extends Node
class_name Class

var name1 = "text"
var id 
var color
var visual
var cell:Cell = null


@abstract func process_next_round()


func _init():
	assert(false, "don't instantiate me, dummy!")
