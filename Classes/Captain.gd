extends Class
class_name Captain


#The Captain changes the whole ship, not the berths beside it: while one is aboard every
#crew member earns MONEY_BONUS more a round, and any of them about to be lost to crowding or
#isolation gets talked back from the brink one time in four. Both are applied in
#Alive.crew_round(), the one copy of the crew rule, so they reach the Captain itself and
#every other cell that lives by it.
const MONEY_BONUS: float = 1.0
#The odds a doomed crew member still goes. The remainder is the reprieve.
const DEATH_CHANCE: float = 0.75


func _init():
	visual = 1
	color = Color(0.20, 0.40, 1.0, 1.0)
	id = "Captain"


func _process_next_round():
	return Alive.crew_round(cell, Captain)
