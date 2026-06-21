extends Class

class_name Revolutionary

func _init():
	visual = 1
	color = Color.PALE_TURQUOISE
	id = "Revolutionary"



func _process_next_round():
	var dead_count = 0
	var alive_count = 0

	var chef_nearby: bool = false

	for i in cell.neighbours:
		if i.contains.id == "Chef":
			chef_nearby = true
		elif i.contains.id == "Dead":
			dead_count += 1
		elif i.contains.id == "Alive" || i.contains.id == "Revolutionary":
			alive_count += 1
		elif i.contains.id == "Zombie":
			if i.contains.threatening():
				return Zombie.new()
		elif i.contains.id == "Springtrap":
			if i.contains.threatening():
				return Corpse.new()

	if chef_nearby:
		return Revolutionary.new()

	if alive_count < 2 or alive_count > 3:
		return Dead.new()
	else:
		return Revolutionary.new()
