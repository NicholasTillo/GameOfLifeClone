extends Class
class_name NuclearEngineer


#Lives and dies by the ordinary crew rules - Alive.crew_round() is the single copy of them -
#and on top of that draws resource from the reactor frames beside it. No robots, no output:
#the engineer alone is just another crewmate.
const RESOURCE_PER_ROBOT: int = 2


func _init():
	visual = 1
	color = Color(0.15, 1.0, 0.25, 1.0)
	id = "NuclearEngineer"


func _process_next_round():
	var result = Alive.crew_round(cell, NuclearEngineer)
	#Paid only by an engineer still standing at the end of the round. Checked on the result
	#rather than up front so a shift that ends in death, conversion or a corpse earns
	#nothing - the same way Alive only takes its wage on the surviving branch.
	if result.id != id:
		return result

	var robots: int = 0
	for i in cell.neighbours:
		if i.contains.id == "Robot":
			robots += 1
	if robots > 0:
		GameManager.change_resource(RESOURCE_PER_ROBOT * robots)
	return result
