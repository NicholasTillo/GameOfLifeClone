extends Class
class_name Doctor


#A Doctor lives and dies by the ordinary crew rules - Alive.crew_round() is the single copy
#of them - and comes back as a Doctor rather than reverting to plain crew.
#
#The reviving is NOT here. Putting a corpse back on its feet is a write to a NEIGHBOUR cell,
#which the double-buffered pass may not do, so GameManager.revive_corpses() settles it after
#the pass. Same shape as the Plorian's walk.
func _init():
	visual = 1
	color = Color.RED
	id = "Doctor"


func _process_next_round():
	return Alive.crew_round(cell, Doctor)
