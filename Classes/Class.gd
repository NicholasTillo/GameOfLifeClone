@abstract

extends RefCounted
class_name Class

var name1 = "text"
var id
var color
var visual
var cell:Cell = null

# Set on the cell this round produced when working it out paid the player, so
# GridNode.replace_cell() can float a marker over the cell: a green $ for money, an orange
# triangle for resource. Measured as a delta here rather than flagged by each earner, so any
# future paying cell type is covered for free - and Chef, which *spends* money, correctly
# gets nothing, because these compare with > rather than !=.
var earned_money: bool = false
var earned_resource: bool = false


func process_next_round():
	# No matter what this cell is, a Life neighbour turns it into Life.
	if cell != null:
		for i in cell.neighbours:
			if i.contains.id == "Life":
				return Life.new()

	var state = GameManager.state
	var money_before: float = state.moneyAmount if state != null else 0.0
	var resource_before: int = GameManager.resourceAmount
	var result = _process_next_round()
	if result != null:
		if state != null and state.moneyAmount > money_before:
			result.earned_money = true
		if GameManager.resourceAmount > resource_before:
			result.earned_resource = true
	return result


@abstract func _process_next_round()


func _init():
	assert(false, "don't instantiate me, dummy!")
