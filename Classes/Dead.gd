extends Class
class_name Dead

func _init():
	visual = 1
	color = Color.BLACK
	id = "Dead"
	

func process_next_round():
	var dead_count = 0
	var alive_count = 0
	
	
	for i in cell.neighbours:
		if i.contains.id == "Dead":
			dead_count += 1
		elif i.contains.id == "Alive":
			alive_count += 1
	if alive_count == 3:
		return Alive.new()
	else:
		return Dead.new()
