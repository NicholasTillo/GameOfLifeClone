extends Class
class_name Alive


func _init():
	visual = 1
	color = Color.WHITE
	id = "Alive"

func process_next_round():
	var dead_count = 0
	var alive_count = 0
	
	var chef_nearby: bool = false
	
	for i in cell.neighbours:
		if i.contains.id == "Chef":
			chef_nearby = true
		if i.contains.id == "Dead":
			dead_count += 1
		elif i.contains.id == "Alive":
			alive_count += 1
		elif i.contains.id == "Zombie":
			if i.contains.threatening(): 
				return Zombie.new()
			
	
	
	if alive_count < 2 or alive_count > 3:
		return Dead.new()
	else:
		return Alive.new()
		
