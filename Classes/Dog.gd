extends Class
class_name Dog


func _init():
	visual = 1
	color = Color.WEB_PURPLE
	id = "Dog"

func _process_next_round():
	return Dog.new()
		
