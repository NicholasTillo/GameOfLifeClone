extends Class
class_name Corpse


func _init():
	visual = 1
	color = Color.DARK_RED
	id = "Corpse"

func process_next_round():
	return Corpse.new()
		
