extends Class

class_name Mechanic

func _init():
	visual = 1
	color = Color.ORANGE
	id = "Mechanic"
	
	

func _process_next_round():
	var dead_count = 0
	var alive_count = 0
	
	for i in cell.neighbours:
		if i.contains.id == "Alive":
			alive_count += 1
			
			
	if  alive_count < 1:
		return Dead.new()
	else:
		GameManager.change_resource(1)
		return Mechanic.new()
