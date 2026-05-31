extends Class
class_name Sandshark


func _init():
	visual = 1
	color = Color.REBECCA_PURPLE
	id = "Sandshark"

func _process_next_round():
	return Sandshark.new()
		
