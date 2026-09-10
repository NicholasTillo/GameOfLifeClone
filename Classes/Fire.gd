extends Class
class_name Fire

# Spreading is handled by GameManager.spread_fire() after the round's double-buffered
# pass, not here, so a spread can't overwrite a cell that pass is still reading.
const SPREAD_AGE: int = 5
const BURN_OUT_AGE: int = 10

var age: int = 0

func _init():
	visual = 1
	color = Color(1.0, 0.35, 0.0, 1.0)
	id = "Fire"

func _process_next_round():
	if age >= BURN_OUT_AGE:
		return Dead.new()
	var son = Fire.new()
	son.age = age + 1
	return son
