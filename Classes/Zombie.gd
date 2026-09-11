extends Class

class_name Zombie
#Rename To Parasite! 

func _init():
	visual = 1
	color = Color.GREEN
	id = "Zombie"
	
	

func _process_next_round():
	var dead_count = 0
	var alive_count = 0
	
	for i in cell.neighbours:
		if i.contains.id == "Dead":
			dead_count += 1
		elif i.contains.id in GameManager.CREW:
			alive_count += 1
			
			
	if alive_count > 3 or alive_count < 1:
		return Dead.new()
	else:
		return Zombie.new()
	
	
func threatening():
	var alive_count = 0
	
	for i in cell.neighbours:
		if i.contains.id in GameManager.CREW:
			alive_count += 1
	return alive_count < 3
