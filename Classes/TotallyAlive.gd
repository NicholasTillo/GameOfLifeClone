extends Class
class_name TotallyAlive


#What a Plorian becomes when its pilgrimage reaches a corpse. Every neighbour rule counts
#it as crew (see GameManager.CREW), but nothing in the round can take it - not isolation,
#not overcrowding, not a Zombie, not a Springtrap. It is an anchor, not a worker: it earns
#nothing, so a stable pattern built around one is paid for by the crew beside it.
func _init():
	visual = 1
	#Off-white. Close enough to Alive's white to read as crew at a glance, far enough to
	#tell the two apart on a crowded board.
	color = Color(0.93, 0.91, 0.80, 1.0)
	id = "TotallyAlive"


func _process_next_round():
	return TotallyAlive.new()
