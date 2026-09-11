extends Class
class_name Dog


#Crew standing next to a dog earn double. The multiplier is applied by the earner, in
#Alive._process_next_round(), because that is where the payout is worked out.
const PAYOUT_MULTIPLIER: float = 2.0


func _init():
	visual = 1
	color = Color.WEB_PURPLE
	id = "Dog"


func _process_next_round():
	#A dog needs its people. Any one of them beside it is enough; pets and monsters are
	#company it cannot live on.
	for i in cell.neighbours:
		if i.contains.id in GameManager.HUMAN:
			return Dog.new()
	return Dead.new()
