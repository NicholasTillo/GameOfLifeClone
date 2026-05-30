extends Class
class_name Plorian


func _init():
	visual = 1
	color = Color.MEDIUM_PURPLE
	id = "Plorian"

func _process_next_round():
	return Plorian.new()
		
