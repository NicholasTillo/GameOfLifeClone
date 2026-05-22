extends Class

class_name Chef

func _init():
	visual = 1
	color = Color.YELLOW
	id = "Chef"
	
	

func process_next_round():
	if  GameManager.state.moneyAmount >= 1:
		GameManager.state.change_money(-1)
		return Chef.new()
	else:
		return Dead.new()
