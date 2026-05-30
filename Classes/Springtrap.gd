extends Class
class_name Springtrap

var alive_count:int = 0
var night_count:int = 0

func _init():
	visual = 1
	color = Color.DARK_GREEN
	id = "Springtrap"

func _process_next_round():
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

	if night_count < 6: #So a total of 7 nights
		var son = Springtrap.new()
		son.night_count = night_count + 1
		return son
	else: 
		return Dead.new()
		

func threatening():
	for i in cell.neighbours:
		if i.contains.id == "Alive":
			alive_count += 1
			
	if alive_count > 1:
		return false
	else:
		return true
