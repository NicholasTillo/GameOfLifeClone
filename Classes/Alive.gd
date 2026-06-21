extends Class
class_name Alive


func _init():
	visual = 1
	color = Color.WHITE
	id = "Alive"

func _process_next_round():
	var dead_count = 0
	var alive_count = 0
	
	var chef_nearby: bool = false
	var revolutionary_nearby: bool = false
	
	
	for i in cell.neighbours:
		if i.contains.id == "Chef":
			chef_nearby = true
		elif i.contains.id == "Revolutionary":
			revolutionary_nearby = true
		elif i.contains.id == "Dead":
			dead_count += 1
		elif i.contains.id == "Alive" || i.contains.id =="Revolutionary":
			alive_count += 1
		elif i.contains.id == "Zombie":
			if i.contains.threatening(): 
				return Zombie.new()
		elif i.contains.id == "Springtrap":
			if i.contains.threatening():
				return Corpse.new()
	
	
	if revolutionary_nearby:
		return Revolutionary.new()
		
	if chef_nearby:
		return Alive.new()

	if alive_count < GameManager.state.min_number_of_surrounding_alives or alive_count > 3:
		return Dead.new()
	else:
		GameManager.state.change_money(1.0 + GameManager.money_per_alive)
		#play Money Gain Animation. 
		return Alive.new()
		
