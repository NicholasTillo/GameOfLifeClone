extends Class
class_name Sandshark


#It eats money and produces resource. Class.process_next_round() diffs both currencies
#either side of this call, so the resource pop over the tank is automatic - and the money
#it swallows correctly floats nothing, because that check is > rather than !=.
const UPKEEP: int = 5
const PAYOUT: int = 2


func _init():
	visual = 1
	color = Color.REBECCA_PURPLE
	id = "Sandshark"


func _process_next_round():
	GameManager.state.change_money(-UPKEEP)
	GameManager.change_resource(PAYOUT)
	return Sandshark.new()
