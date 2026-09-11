extends Class
class_name Alive


func _init():
	visual = 1
	color = Color.WHITE
	id = "Alive"


func _process_next_round():
	return Alive.crew_round(cell, Alive)


#The ordinary crew survival rule, in one place: who is beside you, whether you make it to
#next round, and what you get paid for it. `kind` is the class to come back as when you
#survive, so a Doctor stays a Doctor instead of reverting to plain crew - everything else
#about the round is identical for every cell that "lives like a crew member".
static func crew_round(cell: Cell, kind) -> Class:
	var dead_count = 0
	var alive_count = 0

	var chef_nearby: bool = false
	var revolutionary_nearby: bool = false
	var dog_nearby: bool = false


	for i in cell.neighbours:
		if i.contains.id == "Dog":
			dog_nearby = true
		elif i.contains.id == "Chef":
			chef_nearby = true
		elif i.contains.id == "Revolutionary":
			revolutionary_nearby = true
		elif i.contains.id == "Dead":
			dead_count += 1
		elif i.contains.id in GameManager.CREW || i.contains.id =="Revolutionary":
			alive_count += 1
		elif i.contains.id == "Zombie":
			if i.contains.threatening():
				return Zombie.new()
		elif i.contains.id == "Springtrap":
			if i.contains.threatening():
				return Corpse.new()


	if revolutionary_nearby:
		return Revolutionary.new()

	if chef_nearby:
		return kind.new()

	#A Captain anywhere aboard lifts every wage and softens every crowding death. Unlike the
	#Dog it is not a neighbour effect - it runs the ship, not the room.
	var captain_aboard: bool = GameManager.has_captain()

	var crowd_min: int = GameManager.state.min_number_of_surrounding_alives
	var crowd_max: int = GameManager.state.max_number_of_surrounding_alives
	if alive_count < crowd_min or alive_count > crowd_max:
		#Spared, not paid: they scraped through a round they did not work. Only crowding
		#and isolation are survivable this way - a Zombie or a Springtrap has already
		#returned above, and the Captain has no say in either.
		if captain_aboard and randf() >= Captain.DEATH_CHANCE:
			return kind.new()
		return Dead.new()
	else:
		#A dog beside you doubles the round's takings, the Captain's rise included.
		var payout: float = 1.0 + GameManager.money_per_alive
		if captain_aboard:
			payout += Captain.MONEY_BONUS
		if dog_nearby:
			payout *= Dog.PAYOUT_MULTIPLIER
		GameManager.state.change_money(payout)
		#play Money Gain Animation. 
		return kind.new()
