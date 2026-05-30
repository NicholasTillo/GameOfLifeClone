extends Class
class_name Life


func _init():
	visual = 1
	color = Color(0.8, 0.8, 1.0, 1.0)
	id = "Life"

func _process_next_round():
	# Neighbours are turned into Life by the wrapper in Class.process_next_round();
	# a Life cell simply stays alive.
	return Life.new()
