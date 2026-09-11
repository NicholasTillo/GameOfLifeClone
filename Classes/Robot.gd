extends Class
class_name Robot


#A support frame rather than a person. It counts as crew to everything around it (see
#GameManager.CREW), so the cells beside it stay fed, but it has no life of its own: crowding
#and isolation do not touch it, and the only thing that stops it is the ship running out of
#Mechanics to keep it running.
func _init():
	visual = 1
	#Metallic grey, cool enough to read as machinery beside Wall's flat grey.
	color = Color(0.58, 0.62, 0.68, 1.0)
	id = "Robot"


func _process_next_round():
	#Any Mechanic anywhere aboard will do - one engineer can keep the whole fleet running.
	if GameManager.has_mechanic():
		return Robot.new()
	return Dead.new()
