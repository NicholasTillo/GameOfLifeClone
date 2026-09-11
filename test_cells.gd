extends Node

# Smallest check for the cell logic that has silently broken before.
# Run: godot --headless --path . res://test_cells.tscn
#
# This runs as a SCENE, not with --script. The cell classes reach into the
# GameManager autoload, and --script mode does not register autoloads, so
# everything fails to compile there. A scene run has them.
#
# Covers the three failure modes that were real bugs:
#  - id_to_class() missing a class, which turns that cell into Dead on rewind.
#  - Springtrap.threatening() accumulating state between calls, so neighbours
#    asking in different order got different answers.
#  - the death-skull predicate firing on the wrong transitions.

func _ready() -> void:
	var failures := 0
	failures += _test_id_round_trip()
	failures += _test_springtrap_threatening_is_stateless()
	failures += _test_death_predicate()
	failures += _test_earned_money_flag()
	if failures == 0:
		print("test_cells: OK")
	else:
		print("test_cells: %d FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)


# Every Class the player can end up with on the board must survive a
# hash -> id_to_class() round trip, or rewinding silently deletes it.
func _test_id_round_trip() -> int:
	var instances: Array = [
		Alive.new(), Dead.new(), Chef.new(), Corpse.new(), Zombie.new(),
		Innovator.new(), Mechanic.new(), Revolutionary.new(), Wall.new(),
		Springtrap.new(), Life.new(), Sandshark.new(), Plorian.new(),
		Dog.new(), Fire.new(),
	]
	var failures := 0
	for original in instances:
		var restored = GameManager.id_to_class(original.id)
		if restored.id != original.id:
			print("FAIL id_to_class(\"%s\") gave \"%s\"" % [original.id, restored.id])
			failures += 1
	return failures


# Which transitions float a death skull. A person turning into a monster or a corpse is a
# death; becoming Life is ascension, swapping jobs is not a death, and a monster dying is
# nobody's funeral.
func _test_death_predicate() -> int:
	# [old id, new id, is a death]
	var cases: Array = [
		["Alive", "Dead", true],
		["Alive", "Corpse", true],
		["Alive", "Zombie", true],
		["Mechanic", "Fire", true],
		["Chef", "Dead", true],
		["Revolutionary", "Dead", true],
		["Dog", "Fire", true],
		["Alive", "Revolutionary", false],
		["Alive", "Chef", false],
		["Alive", "Life", false],
		["Zombie", "Dead", false],
		["Fire", "Dead", false],
		["Corpse", "Corpse", false],
		["Wall", "Dead", false],
	]
	var failures := 0
	for case in cases:
		var is_death: bool = case[0] in GameManager.MORTAL and case[1] in GameManager.FATAL
		if is_death != case[2]:
			print("FAIL %s -> %s should%s be a death" %
					[case[0], case[1], "" if case[2] else " not"])
			failures += 1
	return failures


# A marker floats only where the player actually got PAID, and only in the right currency.
# Alive and Innovator earn money; Mechanic earns resource; Chef spends money and must flag
# nothing; a starving cell earns nothing on its way out.
func _test_earned_money_flag() -> int:
	# [cell under test, alive neighbours, expect money, expect resource]
	var cases: Array = [
		[Alive.new(), 2, true, false],
		[Alive.new(), 3, true, false],
		[Alive.new(), 0, false, false],     # starves - dies instead of earning
		[Alive.new(), 8, false, false],     # overcrowded - same
		[Innovator.new(), 1, true, false],
		[Innovator.new(), 0, false, false], # no live neighbour, dies
		[Mechanic.new(), 1, false, true],   # resource, NOT money
		[Mechanic.new(), 0, false, false],  # dies
		[Chef.new(), 3, false, false],      # pays upkeep, must never show a marker
		[Wall.new(), 3, false, false],
		[Dead.new(), 2, false, false],
	]
	#Chef only reaches its spend branch if the player can afford the upkeep. Without this
	#it would starve instead, and the case would pass for the wrong reason.
	GameManager.state.moneyAmount = 500
	var failures := 0
	for case in cases:
		var subject: Class = case[0]
		subject.cell = _cell_with(subject, case[1])
		var produced = subject.process_next_round()
		if produced.earned_money != case[2] or produced.earned_resource != case[3]:
			print("FAIL %s with %d alive neighbours: money=%s/%s resource=%s/%s (got/expected)"
					% [subject.id, case[1], produced.earned_money, case[2],
					produced.earned_resource, case[3]])
			failures += 1
	return failures


# threatening() must answer from the board only, never from carried-over counters:
# the same Springtrap asked twice must say the same thing.
func _test_springtrap_threatening_is_stateless() -> int:
	var failures := 0
	for alive_neighbours in [0, 1, 2, 4]:
		var trap := Springtrap.new()
		trap.cell = _cell_with(trap, alive_neighbours)
		var expected: bool = alive_neighbours <= 1
		for call_number in range(4):
			if trap.threatening() != expected:
				print("FAIL threatening() with %d alive neighbours changed on call %d"
						% [alive_neighbours, call_number + 1])
				failures += 1
				break
	return failures


# A cell holding `contains`, surrounded by `alive_count` Alive cells and 8 - n Dead.
func _cell_with(contains: Class, alive_count: int) -> Cell:
	var cell := Cell.new()
	cell.contains = contains
	for i in range(8):
		var neighbour := Cell.new()
		neighbour.contains = Alive.new() if i < alive_count else Dead.new()
		cell.neighbours.append(neighbour)
	return cell
