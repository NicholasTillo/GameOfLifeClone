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
	failures += _test_pets()
	failures += _test_totally_alive()
	failures += _test_plorian_walk()
	failures += _test_solar_flare()
	failures += _test_birthday_party()
	failures += _test_job_fair()
	failures += _test_space_junk()
	failures += _test_knowledge_collapse()
	failures += _test_warp_scramble()
	failures += _test_trading_outpost()
	failures += _test_enemy_spaceship()
	failures += _test_chapter_gate()
	failures += _test_overheating()
	failures += _test_doctor()
	failures += _test_robot()
	failures += _test_nuclear_engineer()
	failures += _test_captain()
	failures += _test_starter_slots()
	failures += _test_slot_picker_lifetime()
	failures += _test_upgrade_ids_unique()
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
		Dog.new(), Fire.new(), TotallyAlive.new(), Doctor.new(), Robot.new(),
		NuclearEngineer.new(), Captain.new(),
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


# The three pets. Dog needs a person beside it and doubles what the crew beside it earn;
# Sandshark trades money for resource every round no matter what is around it.
func _test_pets() -> int:
	var failures := 0
	GameManager.state.moneyAmount = 500

	# Dog lives on people, not on pets or monsters.
	for case in [["Alive", true], ["Chef", true], ["Mechanic", true], ["TotallyAlive", true],
			["Dead", false], ["Zombie", false], ["Dog", false], ["Sandshark", false]]:
		var dog := Dog.new()
		dog.cell = _cell_beside(dog, GameManager.id_to_class(case[0]))
		var survived: bool = dog.process_next_round().id == "Dog"
		if survived != case[1]:
			print("FAIL Dog beside %s should%s survive" % [case[0], "" if case[1] else " not"])
			failures += 1

	# A dog doubles the round's takings for a neighbouring Alive.
	GameManager.money_per_alive = 0.0
	var plain := Alive.new()
	plain.cell = _cell_with(plain, 2)
	var before: float = GameManager.state.moneyAmount
	plain.process_next_round()
	var solo_payout: float = GameManager.state.moneyAmount - before

	var walked := Alive.new()
	walked.cell = _cell_with(walked, 2)
	walked.cell.neighbours[7].contains = Dog.new()
	before = GameManager.state.moneyAmount
	walked.process_next_round()
	var dog_payout: float = GameManager.state.moneyAmount - before
	if not is_equal_approx(dog_payout, solo_payout * Dog.PAYOUT_MULTIPLIER):
		print("FAIL Dog payout %s, expected %s" % [dog_payout, solo_payout * Dog.PAYOUT_MULTIPLIER])
		failures += 1

	# Sandshark: money out, resource in, every round.
	var shark := Sandshark.new()
	shark.cell = _cell_with(shark, 0)
	var money_before: float = GameManager.state.moneyAmount
	var resource_before: int = GameManager.resourceAmount
	var produced = shark.process_next_round()
	if produced.id != "Sandshark":
		print("FAIL Sandshark did not persist"); failures += 1
	if GameManager.state.moneyAmount != money_before - Sandshark.UPKEEP:
		print("FAIL Sandshark upkeep"); failures += 1
	if GameManager.resourceAmount != resource_before + Sandshark.PAYOUT:
		print("FAIL Sandshark payout"); failures += 1
	if not produced.earned_resource or produced.earned_money:
		print("FAIL Sandshark markers: money=%s resource=%s"
				% [produced.earned_money, produced.earned_resource]); failures += 1
	return failures


# TotallyAlive reads as crew to everything around it, and nothing in a round can take it.
func _test_totally_alive() -> int:
	var failures := 0
	if not "TotallyAlive" in GameManager.CREW:
		print("FAIL TotallyAlive is not crew"); failures += 1

	# It survives every board a normal Alive would die on.
	for alive_neighbours in [0, 1, 8]:
		var anchor := TotallyAlive.new()
		anchor.cell = _cell_with(anchor, alive_neighbours)
		if anchor.process_next_round().id != "TotallyAlive":
			print("FAIL TotallyAlive died with %d neighbours" % alive_neighbours)
			failures += 1

	# A Zombie and a Springtrap must both leave it alone.
	for hostile in ["Zombie", "Springtrap"]:
		var anchor := TotallyAlive.new()
		anchor.cell = _cell_beside(anchor, GameManager.id_to_class(hostile))
		anchor.cell.neighbours[0].contains.cell = anchor.cell.neighbours[0]
		if anchor.process_next_round().id != "TotallyAlive":
			print("FAIL TotallyAlive taken by %s" % hostile); failures += 1

	# A neighbour counting crew must count it. An Alive with two TotallyAlive beside it
	# has the company it needs and lives.
	var crew := Alive.new()
	crew.cell = _cell_with(crew, 0)
	crew.cell.neighbours[0].contains = TotallyAlive.new()
	crew.cell.neighbours[1].contains = TotallyAlive.new()
	if crew.process_next_round().id != "Alive":
		print("FAIL TotallyAlive does not count as a live neighbour"); failures += 1
	return failures


# The Plorian creeps toward the nearest corpse and becomes a TotallyAlive on arrival.
func _test_plorian_walk() -> int:
	var failures := 0

	# Away from a corpse: stays a Plorian and counts up to its next step.
	var walker := Plorian.new()
	walker.cell = _cell_with(walker, 0)
	var next = walker.process_next_round()
	if next.id != "Plorian" or next.steps != 1:
		print("FAIL Plorian step counter: %s steps=%s" % [next.id, next.steps]); failures += 1

	# It steps on the interval and not in between.
	for steps in range(1, Plorian.MOVE_INTERVAL * 2 + 1):
		var p := Plorian.new()
		p.steps = steps
		if p.ready_to_step() != (steps % Plorian.MOVE_INTERVAL == 0):
			print("FAIL Plorian ready_to_step at %d" % steps); failures += 1

	# On a real board it closes the distance to the corpse instead of sitting still.
	GameManager.state = GameState.new()
	var board = GameManager.state
	var size: int = board.full_grid_size
	for c in board.cells:
		c.contains = Dead.new()
		c.contains.cell = c
	var start: int = 0
	var corpse_index: int = size * size - 1
	board.cells[start].contains = Plorian.new()
	board.cells[start].contains.cell = board.cells[start]
	board.cells[start].contains.steps = Plorian.MOVE_INTERVAL
	board.cells[corpse_index].contains = Corpse.new()
	board.cells[corpse_index].contains.cell = board.cells[corpse_index]

	var before: int = GameManager._grid_distance(start, corpse_index, size)
	GameManager.move_plorians()
	var moved_to: int = -1
	for c in board.cells:
		if c.contains is Plorian:
			moved_to = c.id
	if moved_to == -1:
		print("FAIL Plorian vanished during the walk"); failures += 1
	elif GameManager._grid_distance(moved_to, corpse_index, size) >= before:
		print("FAIL Plorian did not close the distance"); failures += 1
	elif board.cells[start].contains.id != "Dead":
		print("FAIL Plorian left something behind in its old berth"); failures += 1

	# Arriving: the corpse is eaten and the Plorian becomes the anchor, whatever its step
	# counter says - touching one is not something it has to wait a turn for.
	for steps in [0, 1, Plorian.MOVE_INTERVAL]:
		GameManager.state = GameState.new()
		board = GameManager.state
		for c in board.cells:
			c.contains = Dead.new()
			c.contains.cell = c
		var pilgrim: Cell = board.cells[0]
		pilgrim.contains = Plorian.new()
		pilgrim.contains.cell = pilgrim
		pilgrim.contains.steps = steps
		#Index 1 is the berth immediately to its right, so the two are neighbours.
		var grave: Cell = board.cells[1]
		grave.contains = Corpse.new()
		grave.contains.cell = grave

		GameManager.move_plorians()
		if pilgrim.contains.id != "TotallyAlive":
			print("FAIL Plorian on %d steps beside a corpse became %s"
					% [steps, pilgrim.contains.id]); failures += 1
		if grave.contains.id != "Dead":
			print("FAIL corpse survived the Plorian, left a %s" % grave.contains.id)
			failures += 1
		for c in board.cells:
			if c.contains.id == "Corpse":
				print("FAIL a corpse was left on the board"); failures += 1
				break
	return failures


# Solar Flare locks the board for SOLAR_FLARE_ROUNDS rounds and then gives it back, and
# the lockout must not outlive the run it happened in.
func _test_solar_flare() -> int:
	var failures := 0

	var flare: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 9:
			flare = e
	if flare == null:
		print("FAIL no event with id 9"); failures += 1
		return failures
	if flare.name != "Solar Flare" or not flare.enabled:
		print("FAIL Solar Flare resource: name=%s enabled=%s" % [flare.name, flare.enabled])
		failures += 1
	if not flare in GameManager.drawable_events([flare]):
		print("FAIL Solar Flare cannot be drawn"); failures += 1

	# Locked the moment it fires, and for exactly the advertised number of rounds.
	GameManager.state = GameState.new()
	GameManager.solar_flare_rounds = GameManager.SOLAR_FLARE_ROUNDS
	if not GameManager.grid_locked():
		print("FAIL grid not locked when the flare lands"); failures += 1
	for round_number in range(GameManager.SOLAR_FLARE_ROUNDS):
		if not GameManager.grid_locked():
			print("FAIL grid unlocked early, on round %d of %d"
					% [round_number, GameManager.SOLAR_FLARE_ROUNDS]); failures += 1
			break
		_advance_round()
	if GameManager.grid_locked():
		print("FAIL grid still locked after %d rounds" % GameManager.SOLAR_FLARE_ROUNDS)
		failures += 1

	# While locked, no cell is clickable - not even one whose type normally is.
	GameManager.state = GameState.new()
	for c in GameManager.state.cells:
		c.contains = Alive.new()
		c.contains.cell = c
	GameManager.solar_flare_rounds = 0
	if not GameManager.renderer.changeable_cell(0):
		print("FAIL an Alive cell is not clickable with the grid clear"); failures += 1
	GameManager.solar_flare_rounds = GameManager.SOLAR_FLARE_ROUNDS
	if GameManager.renderer.changeable_cell(0):
		print("FAIL a cell is still clickable behind the shields"); failures += 1

	# A run that ends mid-event must not hand the leftovers to the next one.
	GameManager.num_remaining_astroids = 7
	GameManager.num_remaining_ecodeadzone = 7
	GameManager.fire_spreads_remaining = 7
	GameManager.reset()
	if GameManager.grid_locked() or GameManager.num_remaining_astroids != 0 			or GameManager.num_remaining_ecodeadzone != 0 			or GameManager.fire_spreads_remaining != 0:
		print("FAIL event effects survived reset()"); failures += 1
	return failures


# The Captain's Birthday Party suspends the overcrowding half of the rule for
# BIRTHDAY_ROUNDS rounds, and the starvation half must keep working throughout.
func _test_birthday_party() -> int:
	var failures := 0

	var party: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 10:
			party = e
	if party == null:
		print("FAIL no event with id 10"); failures += 1
		return failures
	if party.name != "Captain's Birthday Party" or not party.enabled:
		print("FAIL party resource: name=%s enabled=%s" % [party.name, party.enabled])
		failures += 1

	GameManager.state = GameState.new()

	# Normally a cell with more than DEFAULT_MAX_ALIVES neighbours is crowded out.
	var crowded := Alive.new()
	crowded.cell = _cell_with(crowded, 8)
	if crowded.process_next_round().id != "Dead":
		print("FAIL a crowded cell survived with the party off"); failures += 1

	# With the party on it lives, and it still gets paid.
	GameManager.state.max_number_of_surrounding_alives = GameState.NO_CROWDING
	for neighbours in [4, 6, 8]:
		var reveller := Alive.new()
		reveller.cell = _cell_with(reveller, neighbours)
		if reveller.process_next_round().id != "Alive":
			print("FAIL crowd of %d died during the party" % neighbours); failures += 1

	# Starving is still fatal - the party does not make cells immortal.
	var alone := Alive.new()
	alone.cell = _cell_with(alone, 0)
	if alone.process_next_round().id != "Dead":
		print("FAIL an isolated cell survived during the party"); failures += 1

	# It lasts exactly BIRTHDAY_ROUNDS and then puts the bound back.
	GameManager.birthday_rounds = GameManager.BIRTHDAY_ROUNDS
	for round_number in range(GameManager.BIRTHDAY_ROUNDS):
		if GameManager.state.max_number_of_surrounding_alives != GameState.NO_CROWDING:
			print("FAIL party ended early, on round %d" % round_number); failures += 1
			break
		_advance_round()
	if GameManager.state.max_number_of_surrounding_alives != GameState.DEFAULT_MAX_ALIVES:
		print("FAIL crowding limit not restored: %s"
				% GameManager.state.max_number_of_surrounding_alives); failures += 1

	# Two overlapping Ecological Dead Zones must not leave the floor permanently raised.
	# The arm sets an absolute value, so firing it twice and expiring once still restores
	# the default - nudging with += / -= left it one too high for the rest of the run.
	GameManager.state = GameState.new()
	for _i in range(2):
		GameManager.start_dead_zone()
	while GameManager.num_remaining_ecodeadzone > 0:
		_advance_round()
	if GameManager.state.min_number_of_surrounding_alives != GameState.DEFAULT_MIN_ALIVES:
		print("FAIL stacked dead zones left the floor at %s"
				% GameManager.state.min_number_of_surrounding_alives); failures += 1

	GameManager.birthday_rounds = 0
	return failures


# The Job Fair specialises three crew. The helper it shares with Religious Reform
# shares - must cope with a board that has fewer crew than the event asks for.
func _test_job_fair() -> int:
	var failures := 0

	var fair: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 11:
			fair = e
	if fair == null:
		print("FAIL no event with id 11"); failures += 1
		return failures
	if fair.name != "Job Fair" or not fair.enabled:
		print("FAIL Job Fair resource: name=%s enabled=%s" % [fair.name, fair.enabled])
		failures += 1

	# A full crew: exactly one of each profession, and nobody else is touched.
	var wanted := ["Innovator", "Mechanic", "Chef"]
	GameManager.state = GameState.new()
	_fill_board_with_alive(10)
	var converted: int = GameManager.job_fair()
	if converted != 3:
		print("FAIL Job Fair converted %d of 3" % converted); failures += 1
	var counts := {}
	for c in GameManager.state.cells:
		counts[c.contains.id] = counts.get(c.contains.id, 0) + 1
	for id in wanted:
		if counts.get(id, 0) != 1:
			print("FAIL Job Fair produced %d %s" % [counts.get(id, 0), id]); failures += 1
	if counts.get("Alive", 0) != 7:
		print("FAIL Job Fair left %d Alive, expected 7" % counts.get("Alive", 0))
		failures += 1

	# A thin board converts what it can and returns instead of hunting forever. The old
	# pick-until-three loop never terminated here and froze the game.
	for crew in [0, 1, 2]:
		GameManager.state = GameState.new()
		_fill_board_with_alive(crew)
		converted = GameManager.job_fair()
		if converted != crew:
			print("FAIL %d crew aboard converted %d" % [crew, converted]); failures += 1

	# Religious Reform runs through the same helper and still makes three.
	GameManager.state = GameState.new()
	_fill_board_with_alive(10)
	GameManager.religious_reform()
	var revolutionaries: int = 0
	for c in GameManager.state.cells:
		if c.contains.id == "Revolutionary":
			revolutionaries += 1
	if revolutionaries != 3:
		print("FAIL Religious Reform made %d revolutionaries" % revolutionaries); failures += 1
	return failures


# Fortunate Space Junk pays out once, in both currencies, and touches nothing else.
func _test_space_junk() -> int:
	var failures := 0

	var junk: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 12:
			junk = e
	if junk == null:
		print("FAIL no event with id 12"); failures += 1
		return failures
	if junk.name != "Fortunate Space Junk" or not junk.enabled:
		print("FAIL space junk resource: name=%s enabled=%s" % [junk.name, junk.enabled])
		failures += 1

	GameManager.state = GameState.new()
	_fill_board_with_alive(4)
	var money_before: float = GameManager.state.moneyAmount
	var resource_before: int = GameManager.resourceAmount
	var board_before: String = GameManager.hash_state(GameManager.state.cells,
			GameManager.state.subgrids)

	GameManager.salvage_space_junk()

	if GameManager.state.moneyAmount != money_before + GameManager.SALVAGE_MONEY:
		print("FAIL salvage paid %s money, expected %s"
				% [GameManager.state.moneyAmount - money_before, GameManager.SALVAGE_MONEY])
		failures += 1
	if GameManager.resourceAmount != resource_before + GameManager.SALVAGE_RESOURCE:
		print("FAIL salvage paid %s resource, expected %s"
				% [GameManager.resourceAmount - resource_before, GameManager.SALVAGE_RESOURCE])
		failures += 1
	if GameManager.hash_state(GameManager.state.cells, GameManager.state.subgrids) != board_before:
		print("FAIL salvage disturbed the board"); failures += 1
	return failures


# Knowledge Collapse strips every trained job back to plain crew, on the subships as well
# as the main grid, and leaves everyone else alone.
func _test_knowledge_collapse() -> int:
	var failures := 0

	var collapse: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 13:
			collapse = e
	if collapse == null:
		print("FAIL no event with id 13"); failures += 1
		return failures
	if collapse.name != "Knowledge Collapse" or not collapse.enabled:
		print("FAIL collapse resource: name=%s enabled=%s" % [collapse.name, collapse.enabled])
		failures += 1

	GameManager.state = GameState.new()
	GameManager.state.add_ship(3)
	var board := GameManager.state

	# One of each profession on the main grid, plus a Chef posted to the subship, plus a
	# spread of cells that must all survive untouched.
	var bystanders := ["Revolutionary", "Wall", "Zombie", "Dog", "TotallyAlive", "Dead"]
	var layout := ["Chef", "Innovator", "Mechanic"] + bystanders
	for i in range(board.cells.size()):
		var id: String = layout[i] if i < layout.size() else "Alive"
		board.cells[i].contains = GameManager.id_to_class(id)
		board.cells[i].contains.cell = board.cells[i]
	for c in board.subgrids[0]:
		c.contains = Dead.new()
		c.contains.cell = c
	board.subgrids[0][0].contains = Innovator.new()
	board.subgrids[0][0].contains.cell = board.subgrids[0][0]

	var alive_before: int = 0
	for c in board.cells:
		if c.contains.id == "Alive":
			alive_before += 1

	var reverted: int = GameManager.knowledge_collapse()
	if reverted != 4:
		print("FAIL collapse reverted %d, expected 4 (3 aboard, 1 on the subship)" % reverted)
		failures += 1

	for c in board.cells:
		if c.contains.id in GameManager.PROFESSIONS:
			print("FAIL a %s kept its job" % c.contains.id); failures += 1
	if board.subgrids[0][0].contains.id != "Alive":
		print("FAIL the subship %s kept its job" % board.subgrids[0][0].contains.id)
		failures += 1

	# The three demoted crew joined the Alive count, and nobody else moved.
	var alive_after: int = 0
	for c in board.cells:
		if c.contains.id == "Alive":
			alive_after += 1
	if alive_after != alive_before + 3:
		print("FAIL Alive went %d -> %d, expected +3" % [alive_before, alive_after])
		failures += 1
	for i in range(bystanders.size()):
		var at: String = board.cells[3 + i].contains.id
		if at != bystanders[i]:
			print("FAIL collapse turned a %s into a %s" % [bystanders[i], at]); failures += 1

	# Nothing to undo is not an error.
	if GameManager.knowledge_collapse() != 0:
		print("FAIL a second collapse found more jobs"); failures += 1
	return failures


# Faulty Warp Drive shuffles every occupant across every ship. Nobody is created or lost,
# every back-reference follows its occupant, and crew can cross between ships.
func _test_warp_scramble() -> int:
	var failures := 0

	var warp: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 14:
			warp = e
	if warp == null:
		print("FAIL no event with id 14"); failures += 1
		return failures
	if warp.name != "Faulty Warp Drive" or not warp.enabled:
		print("FAIL warp resource: name=%s enabled=%s" % [warp.name, warp.enabled])
		failures += 1

	GameManager.state = GameState.new()
	GameManager.state.add_ship(3)
	GameManager.state.add_ship(3)
	var board := GameManager.state

	# A mixed crew, including cells that carry state, so the move can be shown to keep it.
	var layout := ["Alive", "Chef", "Innovator", "Mechanic", "Wall", "Zombie", "Corpse",
			"Dog", "Sandshark", "TotallyAlive", "Revolutionary", "Dead"]
	var index := 0
	for cell in GameManager.all_cells():
		cell.contains = GameManager.id_to_class(layout[index % layout.size()])
		cell.contains.cell = cell
		index += 1
	var travelling_fire := Fire.new()
	travelling_fire.age = 4
	board.cells[0].contains = travelling_fire
	travelling_fire.cell = board.cells[0]

	var before := _population(GameManager.all_cells())
	var berths: int = GameManager.all_cells().size()
	if berths != board.cells.size() + 9 + 9:
		print("FAIL all_cells() saw %d berths" % berths); failures += 1

	var crossed := false
	for attempt in range(5):
		# Who is on a subship right now, by identity, so a crossing can be spotted after.
		var on_subships := {}
		for subgrid in board.subgrids:
			for c in subgrid:
				on_subships[c.contains.get_instance_id()] = true

		GameManager.scramble_ships()

		# Nobody created, nobody lost.
		var after := _population(GameManager.all_cells())
		if after != before:
			print("FAIL scramble changed the population: %s -> %s" % [before, after])
			failures += 1
			break

		# Every occupant points back at the berth actually holding it.
		for c in GameManager.all_cells():
			if c.contains == null or c.contains.cell != c:
				print("FAIL a berth and its occupant disagree after the scramble")
				failures += 1
				break

		# Someone who was on a subship is now on the main grid, or vice versa.
		for c in board.cells:
			if on_subships.has(c.contains.get_instance_id()):
				crossed = true
				break
		if crossed:
			break

	if not crossed:
		print("FAIL nobody ever crossed between ships"); failures += 1
	if travelling_fire.age != 4:
		print("FAIL the Fire lost its age in the jump"); failures += 1
	if travelling_fire.cell == null or travelling_fire.cell.contains != travelling_fire:
		print("FAIL the Fire is not where it thinks it is"); failures += 1
	return failures


# The Trading Outpost offers one free Chef, Innovator or Mechanic. The card labels itself
# from the offers, grants exactly the one picked, and closes so it cannot be milked.
func _test_trading_outpost() -> int:
	var failures := 0

	var outpost: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 15:
			outpost = e
	if outpost == null:
		print("FAIL no event with id 15"); failures += 1
		return failures
	if outpost.name != "Trading Outpost" or not outpost.enabled:
		print("FAIL outpost resource: name=%s enabled=%s" % [outpost.name, outpost.enabled])
		failures += 1

	var offers := ["Chef", "Innovator", "Mechanic"]
	for pick in range(offers.size()):
		GameManager.state = GameState.new()
		for c in GameManager.state.cells:
			c.contains = Dead.new()
			c.contains.cell = c

		var card: CellGiftPopUp = (load("res://Scenes/cell_gift_pop_up.tscn") as PackedScene).instantiate()
		card.configure("Take your pick.", offers)

		# The buttons name what they hand over.
		var buttons: Array = [card.button1, card.button2, card.button3]
		for i in range(offers.size()):
			if buttons[i].text != offers[i]:
				print("FAIL offer %d labelled %s, expected %s"
						% [i, buttons[i].text, offers[i]]); failures += 1
		if card.text_label.text != "Take your pick.":
			print("FAIL card blurb not set"); failures += 1

		buttons[pick].pressed.emit()

		var counts := _population(GameManager.state.cells)
		if counts.get(offers[pick], 0) != 1:
			print("FAIL picking %s put %d of them aboard"
					% [offers[pick], counts.get(offers[pick], 0)]); failures += 1
		for other in offers:
			if other != offers[pick] and counts.has(other):
				print("FAIL picking %s also produced a %s" % [offers[pick], other])
				failures += 1

		# One gift per visit: the card is on its way out after a pick.
		if not card.is_queued_for_deletion():
			print("FAIL the card stayed open after a pick"); failures += 1
		card.free()

	return failures


# The Enemy Spaceship kills three crew outright, and those three are real deaths.
func _test_enemy_spaceship() -> int:
	var failures := 0

	var enemy: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 16:
			enemy = e
	if enemy == null:
		print("FAIL no event with id 16"); failures += 1
		return failures
	if enemy.name != "Enemy Spaceship Appears" or not enemy.enabled:
		print("FAIL enemy resource: name=%s enabled=%s" % [enemy.name, enemy.enabled])
		failures += 1
	if enemy.required_cutscene != 3:
		print("FAIL enemy ship gated at %d, expected 3" % enemy.required_cutscene)
		failures += 1

	# Alive -> Corpse must read as a death, or the crew die without a skull.
	if not ("Alive" in GameManager.MORTAL and "Corpse" in GameManager.FATAL):
		print("FAIL Alive -> Corpse is not counted as a death"); failures += 1

	GameManager.state = GameState.new()
	_fill_board_with_alive(10)
	var converted: int = GameManager.enemy_spaceship_attack()
	if converted != 3:
		print("FAIL enemy ship killed %d of 3" % converted); failures += 1
	var counts := _population(GameManager.state.cells)
	if counts.get("Corpse", 0) != 3:
		print("FAIL enemy ship left %d corpses" % counts.get("Corpse", 0)); failures += 1
	if counts.get("Alive", 0) != 7:
		print("FAIL enemy ship left %d Alive, expected 7" % counts.get("Alive", 0))
		failures += 1

	# A near-empty ship loses who it has and no more.
	GameManager.state = GameState.new()
	_fill_board_with_alive(2)
	if GameManager.enemy_spaceship_attack() != 2:
		print("FAIL enemy ship overkilled a two-crew board"); failures += 1
	return failures


# Chapter-gated events stay out of the pool until the player has seen enough cutscenes,
# and are in it for good afterwards.
func _test_chapter_gate() -> int:
	var failures := 0
	var gated := {"Space Pirate Attack": 3, "Revolutionary Reform": 3,
			"Enemy Spaceship Appears": 3}
	var all := GameManager.load_resources_from_folder("res://RandomEvents")
	var was := GameManager.current_cutscene_index

	for e in all:
		var want: int = gated.get(e.name, 0)
		if e.required_cutscene != want:
			print("FAIL %s gated at %d, expected %d" % [e.name, e.required_cutscene, want])
			failures += 1

	for index in range(0, GameManager.MAX_CUTSCENE + 1):
		GameManager.current_cutscene_index = index
		var drawable := []
		for e in GameManager.drawable_events(all):
			drawable.append(e.name)
		if "The Meaning Of Life" in drawable:
			print("FAIL the ending is drawable at cutscene %d" % index); failures += 1
		if drawable.is_empty():
			print("FAIL nothing drawable at cutscene %d" % index); failures += 1
		for name in gated:
			var allowed: bool = index >= gated[name]
			if (name in drawable) != allowed:
				print("FAIL %s %s at cutscene %d"
						% [name, "missing" if allowed else "drawable", index])
				failures += 1

	GameManager.current_cutscene_index = was
	return failures


# The Doctor lives by the ordinary crew rules and raises the corpses beside it.
func _test_doctor() -> int:
	var failures := 0

	if not "Doctor" in GameManager.CREW:
		print("FAIL Doctor does not count as crew"); failures += 1
	if not "Doctor" in GameManager.MORTAL:
		print("FAIL Doctor cannot die"); failures += 1
	if Doctor.new().color != Color.RED:
		print("FAIL Doctor is not red"); failures += 1
	if Popup1.COST_DOCTOR != 25:
		print("FAIL Doctor costs %d, expected 25" % Popup1.COST_DOCTOR); failures += 1

	GameManager.state = GameState.new()
	GameManager.state.max_number_of_surrounding_alives = GameState.DEFAULT_MAX_ALIVES

	# It lives and dies exactly where a plain Alive would, and stays a Doctor doing it.
	for neighbours in [0, 1, 2, 3, 8]:
		var plain := Alive.new()
		plain.cell = _cell_with(plain, neighbours)
		var medic := Doctor.new()
		medic.cell = _cell_with(medic, neighbours)
		var plain_result: String = plain.process_next_round().id
		var medic_result: String = medic.process_next_round().id
		var expected: String = "Doctor" if plain_result == "Alive" else plain_result
		if medic_result != expected:
			print("FAIL Doctor with %d neighbours became %s, Alive became %s"
					% [neighbours, medic_result, plain_result]); failures += 1

	# It earns what a crew member earns.
	GameManager.money_per_alive = 0.0
	var earner := Doctor.new()
	earner.cell = _cell_with(earner, 2)
	var before: float = GameManager.state.moneyAmount
	var produced = earner.process_next_round()
	if GameManager.state.moneyAmount <= before or not produced.earned_money:
		print("FAIL Doctor did not get paid"); failures += 1

	# On a real board it raises every corpse beside it, on the subships too.
	GameManager.state = GameState.new()
	GameManager.state.add_ship(3)
	var board := GameManager.state
	for c in GameManager.all_cells():
		c.contains = Dead.new()
		c.contains.cell = c
	board.cells[0].contains = Doctor.new()
	board.cells[0].contains.cell = board.cells[0]
	for i in [1, board.full_grid_size, board.full_grid_size + 1]:
		board.cells[i].contains = Corpse.new()
		board.cells[i].contains.cell = board.cells[i]
	# A corpse well clear of the doctor must be left where it lies.
	var far: int = board.cells.size() - 1
	board.cells[far].contains = Corpse.new()
	board.cells[far].contains.cell = board.cells[far]
	# And one beside a doctor on a subship.
	board.subgrids[0][0].contains = Doctor.new()
	board.subgrids[0][0].contains.cell = board.subgrids[0][0]
	board.subgrids[0][1].contains = Corpse.new()
	board.subgrids[0][1].contains.cell = board.subgrids[0][1]

	var revived: int = GameManager.revive_corpses()
	if revived != 4:
		print("FAIL doctors revived %d, expected 4" % revived); failures += 1
	for i in [1, board.full_grid_size, board.full_grid_size + 1]:
		if board.cells[i].contains.id != "Alive":
			print("FAIL corpse beside the doctor is still a %s" % board.cells[i].contains.id)
			failures += 1
	if board.cells[far].contains.id != "Corpse":
		print("FAIL a corpse across the ship was raised anyway"); failures += 1
	if board.subgrids[0][1].contains.id != "Alive":
		print("FAIL the subship corpse was not raised"); failures += 1
	if GameManager.revive_corpses() != 0:
		print("FAIL a second sweep found corpses that were already up"); failures += 1
	return failures


# The Robot props the crew up around it and runs only while a Mechanic is aboard.
func _test_robot() -> int:
	var failures := 0

	if not "Robot" in GameManager.CREW:
		print("FAIL Robot does not count toward the alive count"); failures += 1
	if "Robot" in GameManager.HUMAN:
		print("FAIL Robot counts as a person"); failures += 1
	if Popup1.COST_ROBOT != 30:
		print("FAIL Robot costs %d, expected 30" % Popup1.COST_ROBOT); failures += 1
	if Robot.new().color == Wall.new().color:
		print("FAIL Robot is the same grey as a Wall"); failures += 1

	GameManager.state = GameState.new()
	GameManager.state.max_number_of_surrounding_alives = GameState.DEFAULT_MAX_ALIVES

	# It keeps the cells beside it alive: an Alive with two Robots has the company it needs.
	var propped := Alive.new()
	propped.cell = _cell_with(propped, 0)
	propped.cell.neighbours[0].contains = Robot.new()
	propped.cell.neighbours[1].contains = Robot.new()
	if propped.process_next_round().id != "Alive":
		print("FAIL Robots did not keep their neighbour alive"); failures += 1

	# A Dog will not live on machinery, because a Robot is not a person.
	var dog := Dog.new()
	dog.cell = _cell_beside(dog, Robot.new())
	if dog.process_next_round().id != "Dead":
		print("FAIL a Dog survived on robot company"); failures += 1

	# No Mechanic aboard: it seizes up, however crowded or empty the room is.
	GameManager.state = GameState.new()
	var board := GameManager.state
	for c in board.cells:
		c.contains = Dead.new()
		c.contains.cell = c
	board.cells[0].contains = Robot.new()
	board.cells[0].contains.cell = board.cells[0]
	if GameManager.has_mechanic():
		print("FAIL found a Mechanic on an empty board"); failures += 1
	if board.cells[0].contains.process_next_round().id != "Dead":
		print("FAIL Robot ran with no Mechanic aboard"); failures += 1

	# One Mechanic anywhere keeps it going - including one on a subship.
	board.cells[5].contains = Mechanic.new()
	board.cells[5].contains.cell = board.cells[5]
	if not GameManager.has_mechanic():
		print("FAIL did not find the Mechanic"); failures += 1
	if board.cells[0].contains.process_next_round().id != "Robot":
		print("FAIL Robot seized up with a Mechanic aboard"); failures += 1

	board.cells[5].contains = Dead.new()
	board.cells[5].contains.cell = board.cells[5]
	board.add_ship(3)
	board.subgrids[0][0].contains = Mechanic.new()
	board.subgrids[0][0].contains.cell = board.subgrids[0][0]
	if not GameManager.has_mechanic():
		print("FAIL a Mechanic on a subship does not count"); failures += 1
	if board.cells[0].contains.process_next_round().id != "Robot":
		print("FAIL a subship Mechanic did not keep the Robot running"); failures += 1

	# Crowding never touches it - eight neighbours and it carries on.
	var crowded := Robot.new()
	crowded.cell = _cell_with(crowded, 8)
	if crowded.process_next_round().id != "Robot":
		print("FAIL Robot was crowded out"); failures += 1
	return failures


# The Nuclear Engineer is crew that draws resource from the Robots beside it, and is a Shop
# unlock rather than something the player starts with.
func _test_nuclear_engineer() -> int:
	var failures := 0

	if not "NuclearEngineer" in GameManager.CREW:
		print("FAIL engineer does not count as crew"); failures += 1
	if not "NuclearEngineer" in GameManager.PROFESSIONS:
		print("FAIL engineer is not a trained job"); failures += 1
	if Popup1.COST_NUCLEAR_ENGINEER != 50:
		print("FAIL engineer costs %d, expected 50" % Popup1.COST_NUCLEAR_ENGINEER); failures += 1

	# It is the third unlock, and carries an id no other upgrade uses.
	var unlock: Upgrade = PlayerController.unlock_nuclear_engineer_upgrade
	if unlock == null:
		print("FAIL no unlock upgrade for the engineer"); failures += 1
		return failures
	if not unlock in PlayerController.all_upgrades:
		print("FAIL the unlock is not in all_upgrades, so it will not survive a save")
		failures += 1

	GameManager.state = GameState.new()
	GameManager.state.max_number_of_surrounding_alives = GameState.DEFAULT_MAX_ALIVES
	GameManager.money_per_alive = 0.0

	# With no Robots it is just another crewmate: it earns money, not resource.
	var alone := NuclearEngineer.new()
	alone.cell = _cell_with(alone, 2)
	var resource_before: int = GameManager.resourceAmount
	var produced = alone.process_next_round()
	if produced.id != "NuclearEngineer":
		print("FAIL engineer with 2 neighbours became %s" % produced.id); failures += 1
	if GameManager.resourceAmount != resource_before:
		print("FAIL engineer made resource with no Robots beside it"); failures += 1
	if not produced.earned_money:
		print("FAIL engineer did not draw a wage"); failures += 1

	# Output scales with the machines around it. Robots count as crew, so they also keep it
	# alive - which is why the neighbour count starts from an empty room here.
	#Robots count as crew, so the room fills up: fewer than the crowding floor and the
	#engineer starves, more than the ceiling and it is crowded out. Two or three is the
	#whole usable range, which caps output at DEFAULT_MAX_ALIVES * RESOURCE_PER_ROBOT.
	for robots in [2, 3]:
		var engineer := NuclearEngineer.new()
		engineer.cell = _cell_with(engineer, 0)
		for i in range(robots):
			engineer.cell.neighbours[i].contains = Robot.new()
		resource_before = GameManager.resourceAmount
		produced = engineer.process_next_round()
		var gained: int = GameManager.resourceAmount - resource_before
		var expected: int = robots * NuclearEngineer.RESOURCE_PER_ROBOT
		if produced.id != "NuclearEngineer":
			print("FAIL engineer beside %d Robots became %s" % [robots, produced.id])
			failures += 1
			continue
		if gained != expected:
			print("FAIL %d Robots gave %d resource, expected %d" % [robots, gained, expected])
			failures += 1
		if not produced.earned_resource:
			print("FAIL no resource marker for %d Robots" % robots); failures += 1

	# A shift that ends in death pays nothing. One Robot alone is below the crowding floor,
	# so this engineer starves out with a machine right beside it.
	GameManager.state.min_number_of_surrounding_alives = GameState.DEFAULT_MIN_ALIVES
	var doomed := NuclearEngineer.new()
	doomed.cell = _cell_with(doomed, 0)
	doomed.cell.neighbours[0].contains = Robot.new()
	resource_before = GameManager.resourceAmount
	produced = doomed.process_next_round()
	if produced.id != "Dead":
		print("FAIL a lone engineer beside one Robot survived as %s" % produced.id)
		failures += 1
	elif GameManager.resourceAmount != resource_before:
		print("FAIL a dying engineer still got paid"); failures += 1

	# Too many machines is as fatal as too few - Robots crowd a room like anyone else.
	var buried := NuclearEngineer.new()
	buried.cell = _cell_with(buried, 0)
	for i in range(8):
		buried.cell.neighbours[i].contains = Robot.new()
	if buried.process_next_round().id != "Dead":
		print("FAIL an engineer walled in by 8 Robots survived"); failures += 1
	return failures


# load_game() finds an upgrade by matching its id against all_upgrades and does NOT stop at
# the first hit, so two upgrades sharing an id both get purchased from one saved entry. Any
# new upgrade must therefore bring a free id with it.
func _test_upgrade_ids_unique() -> int:
	var failures := 0
	var seen := {}
	for u in PlayerController.all_upgrades:
		if seen.has(u.id):
			print("FAIL upgrade id \"%s\" is used by more than one upgrade" % u.id)
			failures += 1
		seen[u.id] = true
	return failures


# The Captain is a whole-ship effect: better pay for everyone, and a reprieve for some of
# those crowding or isolation would otherwise take.
func _test_captain() -> int:
	var failures := 0

	if not "Captain" in GameManager.CREW:
		print("FAIL Captain does not count as crew"); failures += 1
	if Popup1.COST_CAPTAIN != 150:
		print("FAIL Captain costs %d, expected 150" % Popup1.COST_CAPTAIN); failures += 1
	if not PlayerController.unlock_captain_upgrade in PlayerController.all_upgrades:
		print("FAIL the Captain unlock is not in all_upgrades"); failures += 1

	GameManager.state = GameState.new()
	GameManager.state.min_number_of_surrounding_alives = GameState.DEFAULT_MIN_ALIVES
	GameManager.state.max_number_of_surrounding_alives = GameState.DEFAULT_MAX_ALIVES
	GameManager.money_per_alive = 0.0
	var board := GameManager.state
	for c in board.cells:
		c.contains = Dead.new()
		c.contains.cell = c
	if GameManager.has_captain():
		print("FAIL found a Captain on an empty board"); failures += 1

	# Wages, with and without one aboard.
	var wage := func() -> float:
		var hand := Alive.new()
		hand.cell = _cell_with(hand, 2)
		var before: float = board.moneyAmount
		hand.process_next_round()
		return board.moneyAmount - before
	var plain_wage: float = wage.call()
	board.cells[0].contains = Captain.new()
	board.cells[0].contains.cell = board.cells[0]
	if not GameManager.has_captain():
		print("FAIL did not find the Captain"); failures += 1
	var captained_wage: float = wage.call()
	if not is_equal_approx(captained_wage, plain_wage + Captain.MONEY_BONUS):
		print("FAIL wage went %s -> %s, expected +%s"
				% [plain_wage, captained_wage, Captain.MONEY_BONUS]); failures += 1

	# A Captain aboard also reaches the subships, and the Captain draws the rise itself.
	var skipper := Captain.new()
	skipper.cell = _cell_with(skipper, 2)
	var before: float = board.moneyAmount
	if skipper.process_next_round().id != "Captain":
		print("FAIL Captain did not survive an ordinary round"); failures += 1
	if not is_equal_approx(board.moneyAmount - before, captained_wage):
		print("FAIL the Captain did not draw its own rise"); failures += 1

	# The reprieve. Without a Captain an isolated crew member ALWAYS dies; with one, it
	# survives about a quarter of the time. Checked over enough rolls that the bound is
	# many standard errors wide, so this cannot flake.
	var doomed_survivals := func(trials: int) -> int:
		var lived := 0
		for i in range(trials):
			var hand := Alive.new()
			hand.cell = _cell_with(hand, 0)
			if hand.process_next_round().id != "Dead":
				lived += 1
		return lived

	board.cells[0].contains = Dead.new()
	board.cells[0].contains.cell = board.cells[0]
	if doomed_survivals.call(200) != 0:
		print("FAIL an isolated cell survived with no Captain aboard"); failures += 1

	board.cells[0].contains = Captain.new()
	board.cells[0].contains.cell = board.cells[0]
	var trials := 2000
	var lived: int = doomed_survivals.call(trials)
	var rate: float = float(lived) / float(trials)
	#Pinned to the spec - a 75% chance to die - and NOT to Captain.DEATH_CHANCE, which is
	#the thing under test. Deriving the expectation from the constant made this tautological:
	#retuning the odds moved the goalposts with them and the check passed regardless.
	if not is_equal_approx(Captain.DEATH_CHANCE, 0.75):
		print("FAIL DEATH_CHANCE is %s, expected 0.75" % Captain.DEATH_CHANCE); failures += 1
	#0.10 either side of 0.25 is roughly ten standard errors at this sample size, so a
	#correct implementation cannot fail here by chance.
	if abs(rate - 0.25) > 0.10:
		print("FAIL reprieve rate %.3f, expected about 0.25" % rate); failures += 1

	# Overcrowding is spared the same way, but a Zombie is not - the Captain has no say
	# over what has already taken someone.
	var swarmed := Alive.new()
	swarmed.cell = _cell_with(swarmed, 8)
	var crowd_lived := 0
	for i in range(400):
		var hand := Alive.new()
		hand.cell = _cell_with(hand, 8)
		if hand.process_next_round().id != "Dead":
			crowd_lived += 1
	if crowd_lived == 0:
		print("FAIL nobody was ever spared an overcrowding death"); failures += 1

	for i in range(50):
		var victim := Alive.new()
		victim.cell = _cell_beside(victim, Zombie.new())
		victim.cell.neighbours[0].contains.cell = victim.cell.neighbours[0]
		if victim.process_next_round().id != "Zombie":
			print("FAIL the Captain talked someone out of a Zombie"); failures += 1
			break
	return failures


# The starter-slot picker offers Mechanic plus every Shop unlock, locking the ones the
# player has not bought, and it builds that list from PlayerController rather than a scene.
func _test_starter_slots() -> int:
	var failures := 0
	var was: Array = GameManager.chosen_upgrades["unlock_cells"]

	var unlockable: Dictionary = PlayerController.unlockable_cells()
	#Pinned to the literal sets, NOT derived from the lists under test - deriving them means
	#removing a cell silently removes it from the expectation too, and the check passes
	#while the picker quietly loses an option.
	if not _same_set(unlockable.keys(), ["Chef", "Innovator", "NuclearEngineer", "Captain"]):
		print("FAIL unlockable cells are %s" % [unlockable.keys()]); failures += 1
	if not _same_set(Popup1.PLACEABLE, ["Alive", "Mechanic", "Doctor", "Robot", "Innovator",
			"Chef", "NuclearEngineer", "Captain", "Wall", "Springtrap", "Life",
			"Revolutionary"]):
		print("FAIL placeable cells are %s" % [Popup1.PLACEABLE]); failures += 1
	if "Dead" in Popup1.PLACEABLE:
		print("FAIL Dead is offered as a starter cell"); failures += 1
	for id in Popup1.PLACEABLE:
		if GameManager.id_to_class(id).id != id:
			print("FAIL placeable cell \"%s\" is not in id_to_class" % id); failures += 1
	for id in unlockable:
		if GameManager.id_to_class(id).id != id:
			print("FAIL unlockable cell \"%s\" is not in id_to_class" % id); failures += 1
		if unlockable[id] == null:
			print("FAIL no unlock upgrade behind \"%s\"" % id); failures += 1

	# Nothing bought: Mechanic is offered, every unlockable is locked.
	GameManager.chosen_upgrades["unlock_cells"] = []
	if not PlayerController.cell_unlocked("Mechanic"):
		print("FAIL Mechanic needs an unlock"); failures += 1
	for id in unlockable:
		if PlayerController.cell_unlocked(id):
			print("FAIL %s is available with nothing bought" % id); failures += 1

	var card: Popu1 = (load("res://popup_copy.tscn") as PackedScene).instantiate()
	add_child(card)
	var offered: Array = []
	var locked: int = 0
	for b in card.buttons.get_children():
		if b.disabled:
			locked += 1
		else:
			offered.append(b.text)
	#Everything that never needed an unlock is on offer from the first run; the four Shop
	#cells are locked until bought.
	if not _same_set(offered, ["Alive", "Mechanic", "Doctor", "Robot", "Wall", "Springtrap",
			"Life", "Revolutionary"]):
		print("FAIL with nothing bought the picker offered %s" % [offered]); failures += 1
	if locked != unlockable.size():
		print("FAIL %d locked buttons, expected %d" % [locked, unlockable.size()]); failures += 1
	if card.buttons.get_child_count() != Popup1.PLACEABLE.size():
		print("FAIL picker built %d buttons, expected %d"
				% [card.buttons.get_child_count(), Popup1.PLACEABLE.size()]); failures += 1
	card.free()

	# Everything bought: every unlockable is offered, and picking one hands back that class.
	GameManager.chosen_upgrades["unlock_cells"] = unlockable.values()
	card = (load("res://popup_copy.tscn") as PackedScene).instantiate()
	add_child(card)
	for b in card.buttons.get_children():
		if b.disabled:
			print("FAIL %s still locked with everything bought" % b.text); failures += 1
	card.free()

	# Each offer emits its own class - including the multi-word one, whose button reads
	# "Nuclear Engineer" but must still resolve to the "NuclearEngineer" id.
	for id in Popup1.PLACEABLE:
		var pick: Popu1 = (load("res://popup_copy.tscn") as PackedScene).instantiate()
		add_child(pick)
		var got: Array = []
		pick.result_chosen.connect(func(v): got.append(v.id))
		var pressed := false
		for b in pick.buttons.get_children():
			if b.text == id.capitalize():
				b.pressed.emit()
				pressed = true
				break
		if not pressed:
			print("FAIL no button labelled %s" % id.capitalize()); failures += 1
		elif got != [id]:
			print("FAIL picking %s gave %s" % [id, got]); failures += 1
		pick.free()

	GameManager.chosen_upgrades["unlock_cells"] = was
	return failures


# The slot picker must belong to the SCENE, not the root Window. A node parented to the
# root outlives change_scene_to_file(), which is how pressing Play used to carry the picker
# into the run. Only one may be open at a time, or a pick from a stale card lands in
# whichever slot was clicked most recently.
func _test_slot_picker_lifetime() -> int:
	var failures := 0
	var was_slots: Array = GameManager.slots
	var was_count = GameManager.starting_slots

	GameManager.starting_slots = 2
	GameManager.slots = [Dead.new(), Dead.new()]

	var container := HBoxContainer.new()
	container.set_script(load("res://slot_container.gd"))
	add_child(container)

	if container.get_child_count() != 2:
		print("FAIL picker built %d slots, expected 2" % container.get_child_count())
		failures += 1
		container.free()
		GameManager.slots = was_slots
		GameManager.starting_slots = was_count
		return failures

	container.get_child(0).pressed.emit()
	var picker = container._picker
	if not is_instance_valid(picker):
		print("FAIL clicking a slot opened no picker"); failures += 1
	else:
		if picker.get_parent() == get_tree().root:
			print("FAIL the picker is parented to the root Window, so Play will not free it")
			failures += 1
		if picker.get_parent() != get_tree().current_scene:
			print("FAIL the picker is not owned by the current scene"); failures += 1

	# A second slot click replaces the card rather than stacking another on top.
	container.get_child(1).pressed.emit()
	var second = container._picker
	if is_instance_valid(picker) and not picker.is_queued_for_deletion():
		print("FAIL the first picker was left open"); failures += 1
	if not is_instance_valid(second):
		print("FAIL the second click opened no picker"); failures += 1

	# Picking writes to the slot that was clicked last, and relabels that button.
	if is_instance_valid(second):
		second.result_chosen.emit(Mechanic.new())
		if GameManager.slots[1].id != "Mechanic":
			print("FAIL the pick landed in slot %s" % GameManager.slots); failures += 1
		if container.get_child(1).text != "Mechanic":
			print("FAIL slot button reads %s" % container.get_child(1).text); failures += 1
		if container.get_child(0).text != "Empty":
			print("FAIL the untouched slot reads %s" % container.get_child(0).text)
			failures += 1

	container.free()
	GameManager.slots = was_slots
	GameManager.starting_slots = was_count
	return failures


# Two arrays holding the same ids, order aside.
func _same_set(got, want: Array) -> bool:
	var a: Array = Array(got).duplicate()
	var b: Array = want.duplicate()
	a.sort()
	b.sort()
	return a == b


# Overheating swallows every other attempt to advance, so OVERHEAT_PRESSES attempts buy
# half that many generations - and normal service resumes once it has burned through.
func _test_overheating() -> int:
	var failures := 0

	var overheat: random_event = null
	for e in GameManager.load_resources_from_folder("res://RandomEvents"):
		if e.id == 17:
			overheat = e
	if overheat == null:
		print("FAIL no event with id 17"); failures += 1
		return failures
	if overheat.name != "Overheating" or not overheat.enabled:
		print("FAIL overheating resource: name=%s enabled=%s" % [overheat.name, overheat.enabled])
		failures += 1
	if GameManager.OVERHEAT_PRESSES % 2 != 0:
		print("FAIL OVERHEAT_PRESSES is odd, so the pairs do not divide"); failures += 1

	GameManager.state = GameState.new()
	GameManager.clear_event_effects()
	#From zero, so the handful of rounds below cannot reach EVENT_INTERVAL and fire a real
	#event mid-test.
	GameManager.round_count = 0
	GameManager.overheat_presses = GameManager.OVERHEAT_PRESSES

	# Press through the whole cooldown, counting how many attempts actually advanced.
	var advanced: int = 0
	for press in range(GameManager.OVERHEAT_PRESSES):
		var before: int = GameManager.round_count
		_advance_attempt()
		if GameManager.round_count > before:
			advanced += 1
	var expected: int = GameManager.OVERHEAT_PRESSES / 2
	if advanced != expected:
		print("FAIL %d presses advanced %d generations, expected %d"
				% [GameManager.OVERHEAT_PRESSES, advanced, expected]); failures += 1
	if GameManager.overheat_presses != 0:
		print("FAIL cooldown left %d presses on the clock" % GameManager.overheat_presses)
		failures += 1

	# Cooled down: every press counts again.
	var before_count: int = GameManager.round_count
	for press in range(3):
		_advance_attempt()
	if GameManager.round_count != before_count + 3:
		print("FAIL after cooling, 3 presses gave %d generations"
				% [GameManager.round_count - before_count]); failures += 1

	# It must not outlive the run.
	GameManager.overheat_presses = GameManager.OVERHEAT_PRESSES
	GameManager.reset()
	if GameManager.overheat_presses != 0:
		print("FAIL overheating survived reset()"); failures += 1
	return failures


# One press of the next-round button: the real do_next_round(), whether or not it advances.
# Unlike _advance_round() this leaves round_count alone, because how far it moves is the
# thing under test. The caller keeps the total well short of EVENT_INTERVAL instead.
func _advance_attempt() -> void:
	GameManager.prev_states.clear()
	GameManager.do_next_round()


# Advances one real round without letting the run end. A hand-built test board is usually
# stable on the spot, and do_next_round() reacts to a stable board by changing scene - which
# errors out when called from inside _ready() and would abandon the rest of the suite.
# Emptying the loop-detection history each time is what keeps the run alive.
func _advance_round() -> void:
	GameManager.prev_states.clear()
	#These tests are about the per-round countdowns, not the event scheduler. round_count
	#is global and accumulates across the suite, so left alone it eventually lands on a
	#multiple of EVENT_INTERVAL and fires a real event, which tries to parent its popup to
	#a tree still busy running _ready().
	GameManager.round_count = 0
	GameManager.do_next_round()


# How many of each cell id are present, as {id: count}.
func _population(cells: Array) -> Dictionary:
	var counts := {}
	for c in cells:
		counts[c.contains.id] = counts.get(c.contains.id, 0) + 1
	return counts


# Empties the main grid, then puts `crew` Alive cells on it.
func _fill_board_with_alive(crew: int) -> void:
	var index := 0
	for c in GameManager.state.cells:
		c.contains = Alive.new() if index < crew else Dead.new()
		c.contains.cell = c
		index += 1


# A cell holding `contains`, with one `neighbour` beside it and 7 empty berths.
func _cell_beside(contains: Class, neighbour_contains: Class) -> Cell:
	var cell := Cell.new()
	cell.contains = contains
	for i in range(8):
		var neighbour := Cell.new()
		neighbour.contains = neighbour_contains if i == 0 else Dead.new()
		cell.neighbours.append(neighbour)
	return cell


# A cell holding `contains`, surrounded by `alive_count` Alive cells and 8 - n Dead.
func _cell_with(contains: Class, alive_count: int) -> Cell:
	var cell := Cell.new()
	cell.contains = contains
	for i in range(8):
		var neighbour := Cell.new()
		neighbour.contains = Alive.new() if i < alive_count else Dead.new()
		cell.neighbours.append(neighbour)
	return cell
