extends Class
class_name Wall


func _init():
	visual = 1
	color = Color.GRAY
	id = "Wall"

func process_next_round():
	return Wall.new()
		
