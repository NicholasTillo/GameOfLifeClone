extends Node

#This is GameManager


var state: GameState
var renderer = preload("res://Scenes/PlayARea.tscn").instantiate()
var ui: UIController

var sub_ships: Array

var result: Class
var prev_states: Array

#Rewind history: a capped circular buffer of full turn snapshots, used only for
#rewinding. Separate from prev_states, which stays dedicated to stable-state /
#loop detection. Oldest snapshot is dropped once we exceed MAX_HISTORY.
const MAX_HISTORY: int = 8
var history: Array = []

#Once a random event fires, rewinding is disabled for the rest of the run so the
#player can't undo/escape the event. Reset when a new game starts.
var rewind_blocked: bool = false

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

#Upgrade Here
var chosen_upgrades:Dictionary = {"money_upgrades": [], "chance_upgrades":[], "starter_upgrades": [], "max_ship_size_upgrade": [], "starter_ship_size_upgrade": [], "unlock_cells": [], "unlock_rewind": []}
var best_score: int

#List Of Cutscenes They Have Seen. 
var current_cutscene_index:int = 0

#Event Variables
var event_popup_precon_scene = preload("res://Scenes/event_pop_up.tscn")
var pet_store_popup_scene = preload("res://Scenes/pet_store_pop_up.tscn")

var done_rewinds: int = 0



func reset_stats():
	starting_money_increase = 0
	starting_alive_chance = 0.5
	starting_slots = 0
	rewind_number = 0
	
	
func _ready() -> void:
	state = GameState.new()
	add_child(renderer)
	round_count = 0
	init_history()

func _process(delta: float) -> void:
	if autoplay_enabled:
		if culm_time > 0.25: 
			do_next_round()
			culm_time = 0.0
		else:
			culm_time += delta
	
	
#DEV: [ adds 100 resource, ] adds 100 money
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BRACKETLEFT:
			change_resource(100)
		elif event.keycode == KEY_BRACKETRIGHT:
			state.change_money(100)


func reset() -> void:
	state = GameState.new()
	renderer.redraw()
	round_count = 0
	init_history()
	
	
func do_next_round():
	var copy_array = []
	
	for i in range(len(state.cells)):
		result = state.cells[i].contains.process_next_round()
		copy_array.append(result)
		
		
	for i in range(len(state.cells)):
		state.cells[i].contains = copy_array[i]
		state.cells[i].contains.cell = state.cells[i]
		
	if check_stable_state(state.cells, state.subgrids):
		autoplay_enabled = false
		best_score = round_count
		in_gameplay = false
		if round_count >= (current_cutscene_index + 1) * 20:
			renderer.clear()
			current_cutscene_index += 1
			print("res://Scenes/Cutscene"+str(current_cutscene_index)+".tscn")
			get_tree().change_scene_to_file("res://Scenes/Cutscene"+str(current_cutscene_index)+".tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/DeadScene.tscn")
		
		
	for i in range(len(state.subgrids)):
		var copy_array_1 = []
	
		for j in range(len(state.subgrids[i])):
			result = state.subgrids[i][j].contains.process_next_round()
			copy_array_1.append(result)
			
		for j in range(len(state.subgrids[i])):
			state.subgrids[i][j].contains = copy_array_1[j]
			state.subgrids[i][j].contains.cell = state.subgrids[i][j]

	renderer.redraw()
	round_count += 1
	done_rewinds = 0

	#Record this turn (board + money + resource + round_count) so it can be rewound to.
	push_history(take_snapshot())

	if round_count % 25 == 0:
		do_random_event()
	

func load_resources_from_folder(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var file_names = DirAccess.get_files_at(path)
	
	for file_name in file_names:
		# Construct the full path
		var full_path = path + "/" + file_name
		
		# Load the resource and add it to the array
		var res = load(full_path)
		if res:
			resources.append(res)
			
	return resources

func do_random_event():
	#An event permanently changes the board this run; block rewinding past it.
	rewind_blocked = true
	
	var list_of_events:Array = load_resources_from_folder("res://RandomEvents")
	var chosen_event: random_event = list_of_events.pick_random()
	
	
	#Account for Meaning Of Life
	if round_count >= 100 && GameManager.current_cutscene_index == 4:
		for e in list_of_events:
			if e.id == 3:
				chosen_event = e
				break
	else:
		while chosen_event.enabled == false:
			chosen_event = list_of_events.pick_random()
	
	
	var event_popup = event_popup_precon_scene.instantiate()
	get_tree().root.add_child(event_popup)
	event_popup.change_name(chosen_event.name)
	event_popup.change_text(chosen_event.text)
	
	#Actually Do The Thing
	
	match chosen_event.id:
		0: #Springtrap
			var chosen_cell = state.cells.pick_random()
			chosen_cell.contains = Springtrap.new()
			chosen_cell.contains.cell = chosen_cell
		1: #Zombie Invasion
			var num_of_zombies = 5
			for i in range(num_of_zombies):
				var chosen_cell = state.cells.pick_random()
				chosen_cell.contains = Zombie.new()
				chosen_cell.contains.cell = chosen_cell
		2: #Exotic Pet Store
			var pet_store_popup = pet_store_popup_scene.instantiate()
			event_popup.okay_button.pressed.connect(func(): 
															get_tree().root.add_child(pet_store_popup)
															event_popup.close())
		3: #Meaning Of Life
			var chosen_cell = state.cells.pick_random()
			chosen_cell.contains = Life.new()
			chosen_cell.contains.cell = chosen_cell
	
func check_stable_state(param, subgrids):
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


#Push a snapshot onto the history, dropping the oldest once we exceed MAX_HISTORY.
func push_history(snap: Dictionary) -> void:
	history.append(snap)
	if history.size() > MAX_HISTORY:
		history.pop_front()


#Start a fresh history for a new game, seeded with the current (starting) turn.
func init_history() -> void:
	history.clear()
	done_rewinds = 0
	rewind_blocked = false
	push_history(take_snapshot())


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
		"Nurse": return Nurse.new()
		"Wall": return Wall.new()
		"Springtrap": return Springtrap.new()
		"Life": return Life.new()
		"Sandshark": return Sandshark.new()
		"Plorian": return Plorian.new()
		"Dog": return Dog.new()
		_: return Dead.new()


func change_resource(x: int):
	resourceAmount+= x
	if in_gameplay: 
		ui.update_ui()
	
func how_much_resource():
	return resourceAmount
	
	
func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
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
	
	
func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.
		
	chosen_upgrades = {"money_upgrades": [], "chance_upgrades":[], "starter_upgrades":[], "max_ship_size_upgrade":[], "starter_ship_size_upgrade":[], "unlock_cells":[], "unlock_rewind":[]}
	reset_stats()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	
	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
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
				
							
							
