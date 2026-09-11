extends Class

class_name Chef

const UPKEEP: int = 25

func _init():
	visual = 1
	color = Color.YELLOW
	id = "Chef"
	
	


func _process_next_round():
	if  GameManager.state.moneyAmount >= UPKEEP:
		GameManager.state.change_money(-UPKEEP)
		return Chef.new()
	else:
		return Dead.new()
