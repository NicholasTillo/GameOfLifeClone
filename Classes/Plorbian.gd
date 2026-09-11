extends Class
class_name Plorian


#It shuffles one berth every MOVE_INTERVAL rounds. The walking itself is GameManager's job
#(move_plorians, after the double-buffered pass), because a cell may not write to a
#neighbour the pass is still reading. All this counter does is say when a step is due.
const MOVE_INTERVAL: int = 3

var steps: int = 0


func _init():
	visual = 1
	color = Color.MEDIUM_PURPLE
	id = "Plorian"


func _process_next_round():
	#Arriving is not decided here. Reaching a corpse consumes it, and a cell may not write
	#to a neighbour during the double-buffered pass, so GameManager.move_plorians() settles
	#both halves of that trade after the pass instead.
	var son = Plorian.new()
	son.steps = steps + 1
	return son


#True on the rounds a step is due.
func ready_to_step() -> bool:
	return steps > 0 and steps % MOVE_INTERVAL == 0
