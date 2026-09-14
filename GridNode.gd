extends Node

#This is GameManager


var state: GameState
var renderer = preload("res://Scenes/PlayARea.tscn").instantiate()
var ui: UIController

#Who can die, and what they have to become for it to count as dying. A death floats a
#skull off the cell (see GridRenderer.spawn_death_skull). Everything not in MORTAL is a
#monster, a wall or already gone. Turning into Life is ascension, not death, and neither
#is mortal -> mortal (Alive -> Revolutionary, Alive -> Chef), so neither shows a skull.
const MORTAL := ["Alive", "Chef", "Innovator", "Mechanic", "Revolutionary",
		"Sandshark", "Plorian", "Dog", "TotallyAlive", "Doctor", "NuclearEngineer",
		"Captain"]
const FATAL := ["Dead", "Corpse", "Zombie", "Fire"]

#Who counts as crew when a neighbour looks at you. Every rule in Classes/ used to spell
#this as `id == "Alive"`, which meant TotallyAlive - a cell whose whole point is to read as
#crew - would have had to be added to eight separate comparisons. One table instead.
#Robot is here and NOT in HUMAN: it props up the cells around it like a crewmate, but
#it is machinery, so a Dog will not live on its company.
const CREW := ["Alive", "TotallyAlive", "Doctor", "Robot", "NuclearEngineer", "Captain"]
#The trained jobs. Knowledge Collapse strips these back to plain crew, and a new
#profession must be listed here as well as in HUMAN below.
const PROFESSIONS := ["Chef", "Innovator", "Mechanic", "Doctor", "NuclearEngineer",
		"Captain"]
#Who counts as a person: crew, the trained jobs, and the Revolutionary - which is a cause
#rather than a job, which is why it is here but not in PROFESSIONS. Pets (Sandshark,
#Plorian, Dog) are company, not crew, and the Dog will not stay alive on their company
#alone.
const HUMAN := ["Alive", "TotallyAlive", "Doctor", "Chef", "Innovator", "Mechanic",
		"NuclearEngineer", "Captain", "Revolutionary"]

#Run pacing. These were bare numbers inside do_next_round(); the HUD reads them too, so a
#counter can never disagree with the rule it is counting down to.
const EVENT_INTERVAL := 25      #a random event fires on every round_count multiple of this
const CUTSCENE_INTERVAL := 20   #each cutscene needs this many more rounds than the last
const MAX_CUTSCENE := 5         #Scenes/Cutscene1..5 exist; there is no Cutscene6
const LIFE_EVENT_ID := 3        #RandomEvents/FindingMeaningOfLife.tres
const SOLAR_FLARE_ROUNDS := 4   #rounds the shields stay up, and the grid stays locked
const BIRTHDAY_ROUNDS := 5      #rounds the party runs, and overcrowding is suspended
const OVERHEAT_PRESSES := 10    #advance attempts swallowed by Overheating - half of them
const SALVAGE_MONEY := 100      #Fortunate Space Junk, in one payment
const SALVAGE_RESOURCE := 15
#The round that unlocks the final chapter.
const LIFE_EVENT_ROUND := MAX_CUTSCENE * CUTSCENE_INTERVAL


#Round the next cutscene unlocks at, or -1 once they have all been seen.
func next_cutscene_round() -> int:
	if current_cutscene_index >= MAX_CUTSCENE:
		return -1
	return (current_cutscene_index + 1) * CUTSCENE_INTERVAL


#True when advancing one more round will trigger a random event.
func event_next_round() -> bool:
	return (round_count + 1) % EVENT_INTERVAL == 0


#The Meaning Of Life belongs to the last chapter and nowhere else: it lands on the round
#that unlocks the final cutscene, and only on a run where that cutscene is the one still to
#come. A player still on chapter 2 who reaches round 100 gets an ordinary event instead.
func life_event_due() -> bool:
	return round_count == LIFE_EVENT_ROUND and current_cutscene_index == MAX_CUTSCENE - 1

var sub_ships: Array

var result: Class
var prev_states: Array

#Rewind history: full turn snapshots, used only for rewinding. Separate from prev_states,
#which stays dedicated to stable-state / loop detection.
#
#The buffer's length IS the rewind rule. It holds rewind_number + 1 snapshots (the current
#turn plus one per rewind upgrade) and the oldest falls off as the run moves forward. So
#stepping back and then forward again re-earns the rounds you undid, but never reaches
#further back than you could from the furthest round you got to.
#
#Anything the snapshot does not capture - an event's effects, a bigger grid, a new subship,
#taxes - calls init_history() once it lands, so the board can never be rewound past it.
var history: Array = []

var round_count: int
var resourceAmount = 10

var culm_time: float
var autoplay_enabled: bool = false


#Upgrade Stuff. 
var starting_money_increase: int = 0
var starting_alive_chance: float = 0.5
var starting_slots: float = 0
var slots: Array = []
var max_number_size_upgrades :int = 5
var rewind_number: int = 0

var in_gameplay: bool
var money_per_alive: float = 0

#Upgrade Here
var chosen_upgrades:Dictionary = {"money_upgrades": [], "chance_upgrades":[], "starter_upgrades": [], "max_ship_size_upgrade": [], "starter_ship_size_upgrade": [], "unlock_cells": [], "unlock_rewind": []}
var best_score: int

#List Of Cutscenes They Have Seen. 
var current_cutscene_index:int = 0

#Event Variables
var event_popup_precon_scene = preload("res://Scenes/event_pop_up.tscn")
var pet_store_popup_scene = preload("res://Scenes/pet_store_pop_up.tscn")
var cell_gift_popup_scene = preload("res://Scenes/cell_gift_pop_up.tscn")
var spaceship_upgrade_bay_popup_scene = preload("res://Scenes/spaceship_upgrade_bay_pop_up.tscn")
var num_remaining_astroids = 0
var num_remaining_ecodeadzone = 0
#Rounds of Solar Flare left to ride out. While this is above zero the shields are up: the
#board keeps running and stays visible, but the player cannot touch it.
var solar_flare_rounds: int = 0
#Rounds of the Captain's Birthday Party left to run, during which no crowd is too big.
var birthday_rounds: int = 0
#Advance attempts left under Overheating. Every other one is swallowed while the boosters
#cool, so OVERHEAT_PRESSES presses buy the player half that many generations.
var overheat_presses: int = 0
#Shared budget of extra fires the Spaceship Attack outbreak may still create by spreading.
var fire_spreads_remaining: int = 0



func reset_stats():
	starting_money_increase = 0
	starting_alive_chance = 0.5
	starting_slots = 0
	slots.clear()
	rewind_number = 0
	
	
func _ready() -> void:
	state = GameState.new()
	add_child(renderer)
	round_count = 0
	init_history()

#Everything an event leaves ticking. GameManager is an autoload, so without this a run
#that ended mid-event carried the remainder into the next one: leftover astroids fell on a
#fresh board, a half-finished dead zone decremented min_number_of_surrounding_alives on a
#GameState that never had it raised, and a solar flare locked a grid nobody had shielded.
func clear_event_effects() -> void:
	num_remaining_astroids = 0
	num_remaining_ecodeadzone = 0
	fire_spreads_remaining = 0
	solar_flare_rounds = 0
	birthday_rounds = 0
	overheat_presses = 0


func _process(delta: float) -> void:
	if autoplay_enabled:
		if culm_time > 0.25: 
			do_next_round()
			culm_time = 0.0
		else:
			culm_time += delta
	
	

func reset() -> void:
	state = GameState.new()
	renderer.redraw()
	round_count = 0
	clear_event_effects()
	#Loop detection is per-run. Left uncleared it grows for the whole session and a new
	#run can be ended by a board the previous run already visited.
	prev_states.clear()
	init_history()
	



		
		
#Every place a cell's contents change routes through here, so a death is noticed in one
#spot instead of six. grid_index -1 is the main grid, 0/1 a subship.
func replace_cell(cell: Cell, new_contains: Class, grid_index: int = -1) -> void:
	if cell.contains != null and cell.contains.id in MORTAL and new_contains.id in FATAL:
		renderer.spawn_death_skull(cell.id, grid_index)
	else:
		#Flags set by Class.process_next_round() when working this cell out paid the
		#player. Not exclusive - a future cell type could earn both currencies.
		if new_contains.earned_money:
			renderer.spawn_money_pop(cell.id, grid_index)
		if new_contains.earned_resource:
			renderer.spawn_resource_pop(cell.id, grid_index)
	cell.contains = new_contains
	new_contains.cell = cell


func do_next_round():
	#Overheating swallows every other attempt to advance. Checked here rather than in the
	#button handler because autoplay drives this same function, and a player who could
	#switch autoplay on to coast through the cooldown would not be slowed by it at all.
	if overheat_presses > 0:
		overheat_presses -= 1
		if overheat_presses % 2 == 1:
			#The same "that did nothing" cue the rest of the UI uses. Skipped under
			#autoplay, which would otherwise fire it several times a second.
			if not autoplay_enabled:
				GameOfLifeAudio.play_ui_disabled()
			return

	var copy_array = []
	
	for i in range(len(state.cells)):
		result = state.cells[i].contains.process_next_round()
		copy_array.append(result)
		
	
	for i in range(len(state.cells)):
		replace_cell(state.cells[i], copy_array[i])

	if num_remaining_astroids > 0:
		#Do astroid Belt Stuff.
		var chosen_cell = state.cells.pick_random()
		#Play Animation Of Astroid
		num_remaining_astroids -= 1
		#This used to also do `contains.id = chosen_cell.id`, overwriting the class id
		#("Dead") with the cell's array index. That corrupted every id comparison and
		#the state hash for that cell, so it is gone.
		replace_cell(chosen_cell, Dead.new())


	if num_remaining_ecodeadzone > 0:
		num_remaining_ecodeadzone -= 1
		if num_remaining_ecodeadzone == 0:
			state.min_number_of_surrounding_alives = GameState.DEFAULT_MIN_ALIVES

	if birthday_rounds > 0:
		birthday_rounds -= 1
		if birthday_rounds == 0:
			state.max_number_of_surrounding_alives = GameState.DEFAULT_MAX_ALIVES

	if solar_flare_rounds > 0:
		solar_flare_rounds -= 1
		renderer.queue_redraw()

	spread_fire()
	move_plorians()
	revive_corpses()

	if check_stable_state(state.cells, state.subgrids):
		autoplay_enabled = false
		best_score = max(best_score, round_count)
		in_gameplay = false
		renderer.clear()
		var milestone := next_cutscene_round()
		#milestone is -1 once all five cutscenes are seen. Without that guard this walked
		#current_cutscene_index up to 6 and tried to load a Cutscene6.tscn that does not
		#exist, leaving the player on a dead screen.
		if milestone >= 0 and round_count >= milestone:
			current_cutscene_index += 1
			get_tree().change_scene_to_file("res://Scenes/Cutscene"+str(current_cutscene_index)+".tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/DeadScene.tscn")
		#change_scene_to_file is deferred, so without this the run keeps advancing:
		#round_count ticks over and can fire a random event whose popup is parented to
		#the tree root, leaving it floating over the death screen or cutscene.
		return


	for i in range(len(state.subgrids)):
		var copy_array_1 = []
	
		for j in range(len(state.subgrids[i])):
			result = state.subgrids[i][j].contains.process_next_round()
			copy_array_1.append(result)
			
		for j in range(len(state.subgrids[i])):
			replace_cell(state.subgrids[i][j], copy_array_1[j], i)

	renderer.redraw()
	round_count += 1

	#Record this turn (board + money + resource + round_count) so it can be rewound to.
	push_history(take_snapshot())

	#Refresh the HUD every round. It used to update only as a side effect of a cell
	#earning money, so the generation counter would stall on a round where nobody got paid.
	if ui != null:
		ui.update_ui()

	#elif, not a second if: LIFE_EVENT_ROUND is itself a multiple of EVENT_INTERVAL, so both
	#branches would fire on the same round and stack two event popups on top of each other.
	if life_event_due():
		trigger_meaning_of_life()
	elif round_count % EVENT_INTERVAL == 0:
		do_random_event()
	

#True while an event has taken the board away from the player. The renderer asks this
#before it will open a cell popup, and draws the shield overlay from it.
#Ecological Dead Zone: crew need one more neighbour than usual to make it through a round.
#The floor is SET, not nudged up - a second dead zone starting before the first expires
#used to raise it twice and lower it once, leaving the run permanently harder.
#Turns random Alive cells into the given professions, one cell per entry, and hands back
#how many it managed. Shuffling the crew and walking that list is what makes this safe on a
#thin board: Religious Reform used to pick at random until three had landed, which never
#terminated once fewer than three Alive cells were left, and the game simply froze. Now a
#board with one spare crewmate converts one and returns.
#Religious Reform: three of the crew take up the cause.
func religious_reform() -> int:
	return convert_alive_cells([Revolutionary.new(), Revolutionary.new(),
			Revolutionary.new()])


#Job Fair: three of the crew pick up a trade, one of each.
func job_fair() -> int:
	return convert_alive_cells([Innovator.new(), Mechanic.new(), Chef.new()])


#Enemy Spaceship Appears: the ship fights it off and three of the crew do not come back.
#These are real deaths - Alive is MORTAL and Corpse is FATAL - so each floats a skull.
func enemy_spaceship_attack() -> int:
	return convert_alive_cells([Corpse.new(), Corpse.new(), Corpse.new()])


func convert_alive_cells(new_classes: Array) -> int:
	var candidates: Array = []
	for cell in state.cells:
		if cell.contains is Alive:
			candidates.append(cell)
	candidates.shuffle()

	var converted: int = 0
	for new_class in new_classes:
		if converted >= candidates.size():
			break
		#Through replace_cell so the transition gets the usual bookkeeping, which includes
		#deciding whether it was a death: a Job Fair promotion floats nothing, while the
		#corpses an Enemy Spaceship leaves behind each get their skull.
		replace_cell(candidates[converted], new_class)
		converted += 1
	return converted


#Fortunate Space Junk: a one-off windfall in both currencies. Paid through the normal
#change_ calls so the HUD refreshes itself; there is no cell involved, so nothing floats.
#Knowledge Collapse: every trained job on the ship forgets it and goes back to being plain
#crew. Sweeps the subships too - the player can post professions there, and a collapse that
#spared them would be a hiding place rather than a setback. Hands back how many it undid.
#Every berth on every ship, main grid first. One flat list, so anything that works across
#the whole vessel does not have to repeat the subship walk.
func all_cells() -> Array:
	var every: Array = []
	every.append_array(state.cells)
	for subgrid in state.subgrids:
		every.append_array(subgrid)
	return every


#Faulty Warp Drive: everyone and everything aboard comes out of the jump in someone else's
#berth. The occupants are pooled across the main grid AND the subships before shuffling, so
#a crewmate can land on a different ship entirely - which is the point of the event.
#
#Occupants are moved rather than rebuilt, so whatever state they carry (a Fire's age, a
#Springtrap's night count, a Plorian's step counter) rides along with them. The assignment
#is done by hand instead of through replace_cell(): being flung across the ship is not
#dying, and replace_cell would read an Alive berth receiving a Dead as a death and float a
#skull for a crewmate who merely moved.
func scramble_ships() -> void:
	var berths: Array = all_cells()
	var occupants: Array = []
	for cell in berths:
		occupants.append(cell.contains)
	occupants.shuffle()

	for i in range(berths.size()):
		berths[i].contains = occupants[i]
		occupants[i].cell = berths[i]


func knowledge_collapse() -> int:
	var reverted: int = 0
	for cell in state.cells:
		if cell.contains.id in PROFESSIONS:
			#Not a death - a professional turning back into crew is a demotion, and Alive
			#is not in FATAL, so replace_cell floats nothing for it.
			replace_cell(cell, Alive.new())
			reverted += 1
	for i in range(len(state.subgrids)):
		for cell in state.subgrids[i]:
			if cell.contains.id in PROFESSIONS:
				replace_cell(cell, Alive.new(), i)
				reverted += 1
	return reverted


func salvage_space_junk() -> void:
	state.change_money(SALVAGE_MONEY)
	change_resource(SALVAGE_RESOURCE)


func start_dead_zone() -> void:
	state.min_number_of_surrounding_alives = GameState.DEFAULT_MIN_ALIVES + 1
	num_remaining_ecodeadzone += (randi() % 15) + 5


func grid_locked() -> bool:
	return solar_flare_rounds > 0


func load_resources_from_folder(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	#Not DirAccess.get_files_at(): in an exported build that lists "AstroidBelt.tres.remap",
	#which load() cannot open, so the web build found zero events and none ever fired.
	#ResourceLoader.list_directory() gives the loadable names in the editor and exports alike.
	var file_names = ResourceLoader.list_directory(path)
	
	for file_name in file_names:
		# Construct the full path
		var full_path = path + "/" + file_name
		
		# Load the resource and add it to the array
		var res = load(full_path)
		if res:
			resources.append(res)
			
	return resources

#Shows an event's popup. Both trigger paths use this so the player sees the same card
#however the event was reached.
func show_event_popup(event: random_event):
	var event_popup = event_popup_precon_scene.instantiate()
	get_tree().root.add_child(event_popup)
	event_popup.change_name(event.name)
	event_popup.change_text(event.text)
	return event_popup


#Drops a single Life into the board. Life converts every neighbour each round (see
#Class.process_next_round), so one seed is enough to take the whole crew.
func seed_life() -> void:
	var chosen_cell = state.cells.pick_random()
	chosen_cell.contains = Life.new()
	chosen_cell.contains.cell = chosen_cell


#The Meaning Of Life arriving on its own, outside the random pool and the 25-round cycle:
#its popup plus the seed. Fired from do_next_round() when life_event_due() says so.
func trigger_meaning_of_life() -> void:
	for e in load_resources_from_folder("res://RandomEvents"):
		if e.id == LIFE_EVENT_ID:
			show_event_popup(e)
			break
	seed_life()
	#No rewinding back past the arrival - see history.
	init_history()
	renderer.redraw()


#Everything the player is currently allowed to draw. Filtering up front replaces a
#pick-until-enabled loop that spun forever if nothing in the folder was drawable, and it
#is the single place the chapter gate is applied - see random_event.required_cutscene.
func drawable_events(all_events: Array) -> Array:
	var pool := []
	for e in all_events:
		if e.enabled and current_cutscene_index >= e.required_cutscene:
			pool.append(e)
	return pool


func do_random_event():
	var list_of_events:Array = load_resources_from_folder("res://RandomEvents")

	#The Meaning Of Life is kept OUT of this pool - FindingMeaningOfLife.tres is
	#`enabled = false` and drawable_events() skips disabled events, so it can never be drawn
	#at random and spoil the ending. It has its own guaranteed trigger at
	#LIFE_EVENT_ROUND in do_next_round().
	var pool := drawable_events(list_of_events)
	#Nothing drawable means nothing happened, so rewinding is left alone.
	if pool.is_empty():
		return
	var chosen_event: random_event = pool.pick_random()

	var event_popup = show_event_popup(chosen_event)

	#Actually Do The Thing

	match chosen_event.id:
		0: #Springtrap
			var chosen_cell = state.cells.pick_random()
			chosen_cell.contains = Springtrap.new()
			chosen_cell.contains.cell = chosen_cell
		1: #Alien Invasion
			var num_of_zombies = 5
			for i in range(num_of_zombies):
				var chosen_cell = state.cells.pick_random()
				replace_cell(chosen_cell, Zombie.new())
		2: #Exotic Pet Store
			var pet_store_popup = pet_store_popup_scene.instantiate()
			event_popup.okay_button.pressed.connect(func(): 
															get_tree().root.add_child(pet_store_popup)
															event_popup.close())
		3: #Meaning Of Life
			seed_life()
		4:#Astroid Belt
			num_remaining_astroids =  (randi() % 15 )+ 5 #Random 5-20

		5:#Eco Dead Zone
			start_dead_zone()
			
		6:#Religious Reform
			religious_reform()
		7: #Spaceship Upgrade Bay
			var upgrade_bay_popup = spaceship_upgrade_bay_popup_scene.instantiate()
			event_popup.okay_button.pressed.connect(func():
															get_tree().root.add_child(upgrade_bay_popup)
															event_popup.close())
		8:#Spaceship attack,
			var num_of_fires = 3
			fire_spreads_remaining = 5
			#Walls are firebreaks, so the strike can't set one alight either.
			var flammable = []
			for c in state.cells:
				if not (c.contains is Wall):
					flammable.append(c)
			for i in range(num_of_fires):
				if flammable.is_empty():
					break
				var chosen_cell = flammable.pick_random()
				replace_cell(chosen_cell, Fire.new())
		9: #Solar Flare
			solar_flare_rounds = SOLAR_FLARE_ROUNDS
			#The shields come up under whatever the player was in the middle of doing.
			#Without this a popup opened just before the flare stays live and buys them
			#one placement the lockout is supposed to deny.
			renderer.dismiss_popup()
		10: #Captain's Birthday Party
			birthday_rounds = BIRTHDAY_ROUNDS
			state.max_number_of_surrounding_alives = GameState.NO_CROWDING
		11: #Job Fair
			job_fair()
		12: #Fortunate Space Junk
			salvage_space_junk()
		13: #Knowledge Collapse
			knowledge_collapse()
		14: #Faulty Warp Drive
			scramble_ships()
		15: #Trading Outpost
			var outpost_popup = cell_gift_popup_scene.instantiate()
			outpost_popup.configure(
					"The foremen of the outpost line up at your airlock.
Take your pick, the contract is already paid.",
					["Chef", "Innovator", "Mechanic"])
			event_popup.okay_button.pressed.connect(func():
															get_tree().root.add_child(outpost_popup)
															event_popup.close())
		16: #Enemy Spaceship Appears
			enemy_spaceship_attack()
		17: #Overheating
			overheat_presses = OVERHEAT_PRESSES

	#The snapshot for this round was taken before the event hit. Restart the history from
	#the board as the event left it, so a rewind cannot undo the event or roll a new one.
	#Events that hand out a pick (pet store, outpost, upgrade bay) restart it again on the pick.
	init_history()

	#do_random_event() runs at the very END of do_next_round(), after that round has already
	#redrawn. Without this every board-changing event - rocks, fires, the scramble - sat
	#invisible until the player advanced another round.
	renderer.redraw()

# Every fire that has just burned for SPREAD_AGE rounds ignites one random non-burning
# neighbour, until the outbreak's shared spread budget runs out. Runs after the round's
# double-buffered pass so a new fire can't clobber a cell that pass is still reading.
func spread_fire() -> void:
	if fire_spreads_remaining <= 0:
		return

	for cell in state.cells:
		if fire_spreads_remaining <= 0:
			return
		if not (cell.contains is Fire) or cell.contains.age != Fire.SPREAD_AGE:
			continue

		var targets = []
		for neighbour in cell.neighbours:
			#Walls are firebreaks: fire never spreads into one.
			if not (neighbour.contains is Fire) and not (neighbour.contains is Wall):
				targets.append(neighbour)

		if targets.is_empty():
			continue

		var target = targets.pick_random()
		replace_cell(target, Fire.new())
		fire_spreads_remaining -= 1


#Chebyshev distance between two main-grid cell indices. Neighbours include diagonals, so a
#diagonal step covers exactly as much ground as a straight one.
func _grid_distance(a: int, b: int, size: int) -> int:
	@warning_ignore("integer_division")
	var ay: int = a / size
	@warning_ignore("integer_division")
	var by: int = b / size
	return max(abs(a % size - b % size), abs(ay - by))


#The Plorian's pilgrimage: it creeps one berth at a time toward the nearest corpse, and on
#reaching one it consumes the corpse and becomes a TotallyAlive.
#Runs after the round's double-buffered pass, like spread_fire(), because a cell may not
#write to a neighbour that pass is still reading - and taking the corpse away is exactly
#such a write, which is why arriving is settled here and not in Plorian itself. Main grid
#only: pets are only ever dropped into state.cells, never into a subship.
func move_plorians() -> void:
	var size: int = state.full_grid_size

	#Arrivals first, so a Plorian already touching a corpse takes it rather than stepping
	#somewhere else, and so the corpses gathered below are the ones still on the board.
	for cell in state.cells:
		if not (cell.contains is Plorian):
			continue
		for neighbour in cell.neighbours:
			if neighbour.contains.id != "Corpse":
				continue
			#Corpse is not in MORTAL and Plorian -> TotallyAlive is not a FATAL end, so
			#neither of these reads as a death and no skull is floated for either.
			replace_cell(neighbour, Dead.new())
			replace_cell(cell, TotallyAlive.new())
			break

	var corpses: Array = []
	for cell in state.cells:
		if cell.contains.id == "Corpse":
			corpses.append(cell.id)
	if corpses.is_empty():
		return

	#Collected before any of them move, so a Plorian that steps into a berth further down
	#state.cells is not picked up again and walked twice in the one round.
	var movers: Array = []
	for cell in state.cells:
		if cell.contains is Plorian and cell.contains.ready_to_step():
			movers.append(cell)

	for cell in movers:
		var target: int = corpses[0]
		for c in corpses:
			if _grid_distance(cell.id, c, size) < _grid_distance(cell.id, target, size):
				target = c

		#It only ever steps into an empty berth, so the walk can never trample the crew,
		#push through a wall, or wander into a fire.
		var best: Cell = null
		var best_distance: int = _grid_distance(cell.id, target, size)
		for neighbour in cell.neighbours:
			if neighbour.contains.id != "Dead":
				continue
			var d: int = _grid_distance(neighbour.id, target, size)
			if d < best_distance:
				best = neighbour
				best_distance = d
		if best == null:
			continue

		#A step is not a death. replace_cell() would read this Plorian -> Dead as one and
		#float a skull off the berth it just walked out of, so the swap is done by hand.
		var walker: Class = cell.contains
		cell.contains = Dead.new()
		cell.contains.cell = cell
		best.contains = walker
		walker.cell = best


#Doctors put the dead back on their feet: every corpse beside one gets up as crew. Runs
#after the round's double-buffered pass, like spread_fire() and move_plorians(), because
#reviving is a write to a NEIGHBOUR cell and the pass may not do that.
#
#Deliberately after move_plorians(), so a Plorian that reached a corpse this round consumes
#it first. The pilgrimage is the rarer thing and a doctor has no shortage of other work.
#True while at least one Mechanic is aboard, anywhere on any ship. Robots ask this every
#round to know whether they are still being maintained.
func has_mechanic() -> bool:
	return crew_aboard("Mechanic")


#True while at least one Captain is aboard, anywhere on any ship. Read once per crew member
#per round by Alive.crew_round().
func has_captain() -> bool:
	return crew_aboard("Captain")


#ponytail: rescans every berth per call, and crew_round() calls it for every crew member in
#the round. Fine at this board size; if it ever shows up in the profiler, work both answers
#out once at the top of do_next_round() and cache them for the pass.
func crew_aboard(id: String) -> bool:
	for cell in all_cells():
		if cell.contains.id == id:
			return true
	return false


func revive_corpses() -> int:
	var revived: int = 0
	for cell in state.cells:
		revived += _revive_around(cell, -1)
	for i in range(len(state.subgrids)):
		for cell in state.subgrids[i]:
			revived += _revive_around(cell, i)
	return revived


func _revive_around(cell: Cell, grid_index: int) -> int:
	if cell.contains.id != "Doctor":
		return 0
	var revived: int = 0
	for neighbour in cell.neighbours:
		if neighbour.contains.id == "Corpse":
			#Corpse is not in MORTAL, so getting back up is never read as a death.
			replace_cell(neighbour, Alive.new(), grid_index)
			revived += 1
	return revived


func check_stable_state(param, subgrids) -> bool:
	var hashed = hash_state(param, subgrids)
	
	for i in prev_states:
		if i == hashed:
			return true
	prev_states.append(hashed)
	return false


func hash_state(grid: Array, subgrids:Array) -> String:
	var new_array = []
	for i in grid:
		new_array.append(i.contains.id)
	for i in subgrids:
		for j in i:
			new_array.append(j.contains.id)
		
	return str(new_array)


#Capture everything that defines the current turn so it can be restored on rewind.
func take_snapshot() -> Dictionary:
	return {
		"board": hash_state(state.cells, state.subgrids),
		"money": state.moneyAmount,
		"resource": resourceAmount,
		"round_count": round_count,
	}


#Restore a previously captured turn: board contents plus the tracked counters.
func restore_snapshot(snap: Dictionary) -> void:
	unhash_state(snap["board"])
	state.moneyAmount = snap["money"]
	resourceAmount = snap["resource"]
	round_count = snap["round_count"]
	if ui != null:
		ui.update_ui()
	renderer.redraw()


#Push a snapshot onto the history, dropping the oldest past the rewind allowance.
func push_history(snap: Dictionary) -> void:
	history.append(snap)
	while history.size() > rewind_number + 1:
		history.pop_front()


#Start a fresh history from the current turn. Called for a new game, and whenever something
#the snapshot does not capture changes the run, so nothing can be rewound past that point.
func init_history() -> void:
	history.clear()
	push_history(take_snapshot())


#Steps the board back one round. False when the history has nothing further back.
func rewind() -> bool:
	if history.size() < 2:
		return false
	history.pop_back()
	#The undone round's loop-detection entry goes too, or replaying it would end the run.
	prev_states.pop_back()
	restore_snapshot(history.back())
	return true


# Reverse of hash_state: takes a hashed state string and applies the ids back
# onto the current grid/subgrids, rebuilding functioning cell contents. Reuses
# the existing Cell objects so their neighbour links stay intact.
func unhash_state(hashed: String) -> void:
	# hash_state() returns str(Array), e.g. ["Alive", "Dead", ...].
	var trimmed = hashed.strip_edges().trim_prefix("[").trim_suffix("]")
	if trimmed.is_empty():
		return

	var ids = trimmed.split(", ")
	var index = 0

	# Main grid comes first in the hash, in cell order.
	for cell in state.cells:
		if index >= ids.size():
			return
		cell.contains = id_to_class(_clean_id(ids[index]))
		cell.contains.cell = cell
		index += 1

	# Then each subgrid, in the same order they were hashed.
	for subgrid in state.subgrids:
		for cell in subgrid:
			if index >= ids.size():
				return
			cell.contains = id_to_class(_clean_id(ids[index]))
			cell.contains.cell = cell
			index += 1

	renderer.redraw()


# Strips the surrounding quotes/whitespace from a single tokenised id.
func _clean_id(raw: String) -> String:
	return raw.strip_edges().trim_prefix("\"").trim_suffix("\"")


# Maps a Class id back to a fresh instance of that Class.
func id_to_class(id: String) -> Class:
	match id:
		"Alive": return Alive.new()
		"Dead": return Dead.new()
		"Chef": return Chef.new()
		"Corpse": return Corpse.new()
		"Zombie": return Zombie.new()
		"Innovator": return Innovator.new()
		"Mechanic": return Mechanic.new()
		"Revolutionary": return Revolutionary.new()
		"Wall": return Wall.new()
		"Springtrap": return Springtrap.new()
		"Life": return Life.new()
		"Sandshark": return Sandshark.new()
		"Plorian": return Plorian.new()
		"Dog": return Dog.new()
		"TotallyAlive": return TotallyAlive.new()
		"Doctor": return Doctor.new()
		"Robot": return Robot.new()
		"NuclearEngineer": return NuclearEngineer.new()
		"Captain": return Captain.new()
		"Fire": return Fire.new()
		_: return Dead.new()


func change_resource(x: int):
	resourceAmount+= x
	if in_gameplay: 
		ui.update_ui()
	
func how_much_resource():
	return resourceAmount
	
	
func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file == null:
		return false
	var json_string = JSON.stringify({"resource": resourceAmount,"best_score": best_score, "current_cutscene_index": current_cutscene_index})
	save_file.store_line(json_string)
	

	
	var new_1 = []
	var new_2 = []
	var new_3 = []
	var new_4 = []
	var new_5 = []
	var new_6 = []
	var new_7 = []
	#Upgrade Here
	for i in chosen_upgrades["money_upgrades"]:
		new_1.append(i.id)
	for i in chosen_upgrades["chance_upgrades"]:
		new_2.append(i.id)
	for i in chosen_upgrades["starter_upgrades"]:
		new_3.append(i.id)
	for i in chosen_upgrades["max_ship_size_upgrade"]:
		new_4.append(i.id)
	for i in chosen_upgrades["starter_ship_size_upgrade"]:
		new_5.append(i.id)
	for i in chosen_upgrades["unlock_cells"]:
		new_6.append(i.id)
	for i in chosen_upgrades["unlock_rewind"]:
		new_7.append(i.id)

	var new_dict = {}
	json_string = JSON.stringify({"upgrades": {"money_upgrades": new_1, "chance_upgrades":new_2, "starter_upgrades":new_3, "max_ship_size_upgrade":new_4, "starter_ship_size_upgrade":new_5, "unlock_cells":new_6, "unlock_rewind":new_7}})
	save_file.store_line(json_string)
	return true


func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return false # Error! We don't have a save to load.
		
	chosen_upgrades = {"money_upgrades": [], "chance_upgrades":[], "starter_upgrades":[], "max_ship_size_upgrade":[], "starter_ship_size_upgrade":[], "unlock_cells":[], "unlock_rewind":[]}
	reset_stats()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file == null:
		push_error("Failed to open save file: %s" % FileAccess.get_open_error())
		return false

	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return false
	else:
		var data = json.data
		resourceAmount = int(data["resource"])
		best_score = int(data["best_score"])
		current_cutscene_index = int(data["current_cutscene_index"])
		

	
	#Load Upgrades
	json_string = save_file.get_line()
	json = JSON.new()
	parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return false
	else:
		var data = json.data
		var copy_chosen_upgrades = data["upgrades"]
		#Loop through data here, and set the correct upgrades.
		for i in copy_chosen_upgrades.keys():
			if i == "money_upgrades":
				for j in copy_chosen_upgrades["money_upgrades"]:
					for k in PlayerController.all_upgrades:
						
						if k.id == j:
							PlayerController.purchase_start_money_upgrade(k)
							chosen_upgrades["money_upgrades"].append(k)
			elif i == "chance_upgrades":
				for j in copy_chosen_upgrades["chance_upgrades"]:
					for k in PlayerController.all_upgrades:
						if k.id == j:
							PlayerController.purchase_start_alive_count(k)
							chosen_upgrades["chance_upgrades"].append(k)
			elif i == "starter_upgrades":
				for j in copy_chosen_upgrades["starter_upgrades"]:
					for k in PlayerController.all_upgrades:
						if k.id == j:
							PlayerController.purchase_start_count(k)
							chosen_upgrades["starter_upgrades"].append(k)
			elif i == "max_ship_size_upgrade":
				for j in copy_chosen_upgrades["max_ship_size_upgrade"]:
					for k in PlayerController.all_upgrades:
						if k.id == j:
							PlayerController.purchase_max_ship_size_upgrade(k)
							chosen_upgrades["max_ship_size_upgrade"].append(k)
			elif i == "starter_ship_size_upgrade":
				for j in copy_chosen_upgrades["starter_ship_size_upgrade"]:
					for k in PlayerController.all_upgrades:
						if k.id == j:
							PlayerController.purchase_starter_ship_size_upgrade(k)
							chosen_upgrades["starter_ship_size_upgrade"].append(k)
			elif i == "unlock_cells":
				for j in copy_chosen_upgrades["unlock_cells"]:
					for k in PlayerController.all_upgrades:
						if k.id == j:
							PlayerController.purchase_unlock_cell(k)
							chosen_upgrades["unlock_cells"].append(k)
			elif i == "unlock_rewind":
				for j in copy_chosen_upgrades["unlock_rewind"]:
					for k in PlayerController.all_upgrades:
						if k.id == j:
							PlayerController.purchase_rewind(k)
							chosen_upgrades["unlock_rewind"].append(k)
	return true
