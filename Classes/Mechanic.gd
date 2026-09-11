extends Class

class_name Mechanic

const PAYOUT: int = 1

func _init():
	visual = 1
	color = Color.ORANGE
	id = "Mechanic"
	
	

func _process_next_round():
	var dead_count = 0
	var alive_count = 0
	
	for i in cell.neighbours:
		if i.contains.id in GameManager.CREW:
			alive_count += 1
			
			
	if  alive_count < 1:
		return Dead.new()
	else:
		GameManager.change_resource(PAYOUT)
		return Mechanic.new()
