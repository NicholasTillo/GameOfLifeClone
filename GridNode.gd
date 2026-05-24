extends Node

#This is GameManager


var state: GameState
var renderer = preload("res://Scenes/PlayARea.tscn").instantiate()
var ui: UIController

var sub_ships: Array

var result: Class

var prev_states: Array

var round_count: int
var resourceAmount = 10

var culm_time: float
var autoplay_enabled: bool = false


#Upgrade Stuff. 
var starting_money_increase: int = 0
var starting_alive_chance: float = 0.5
var starting_slots: float = 0
var slots: Array = []

var in_gameplay: bool

#Upgrade Here
var chosen_upgrades:Dictionary = {"money_upgrades": [], "chance_upgrades":[], "starter_upgrades": []}

var best_score: int

#List Of Cutscenes They Have Seen. 
var current_cutscene_index:int = 0





func reset_stats():
	starting_money_increase = 0
	starting_alive_chance = 0.5
	starting_slots = 0
	
func _ready() -> void:
	state = GameState.new()
	add_child(renderer)
	round_count = 0

func _process(delta: float) -> void:
	if autoplay_enabled:
		if culm_time > 1.0: 
			do_next_round()
			culm_time = 0.0
		else:
			culm_time += delta
	
	
func reset() -> void:
	state = GameState.new()
	renderer.redraw()
	round_count = 0
	
	
func do_next_round():
	var copy_array = []
	
	for i in range(len(state.cells)):
		result = state.cells[i].contains.process_next_round()
		copy_array.append(result)
		
		
	for i in range(len(state.cells)):
		state.cells[i].contains = copy_array[i]
		state.cells[i].contains.cell = state.cells[i]
		
	if check_stable_state(state.cells):
		autoplay_enabled = false
		best_score = round_count
		if round_count >= current_cutscene_index * 20:
			get_tree().change_scene_to_file("res://Scenes/Cutscene"+str(current_cutscene_index)+".tscn")
			
		get_tree().change_scene_to_file("res://Scenes/DeadScene.tscn")
		in_gameplay = false
		
	for i in range(len(state.subgrids)):
		var copy_array_1 = []
	
		for j in range(len(state.subgrids[i])):
			result = state.subgrids[i][j].contains.process_next_round()
			print(result.id)
			copy_array_1.append(result)
			
		for j in range(len(state.subgrids[i])):
			state.subgrids[i][j].contains = copy_array_1[j]
			state.subgrids[i][j].contains.cell = state.subgrids[i][j]
			print(state.subgrids[i][j].contains.id)

	renderer.redraw()
	state.change_money(1)
	change_resource(2)
	round_count += 1
	
	for i in state.subgrids:
		pass
	
func check_stable_state(param):
	var hashed = hash_state(param)
	for i in prev_states:
		if i == hashed:
			return true
	prev_states.append(hashed)
	return false


func hash_state(grid: Array) -> String:
	var new_array = []
	for i in grid:
		new_array.append(i.contains.id)
	return str(new_array)
	
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
	
	#Upgrade Here
	for i in chosen_upgrades["money_upgrades"]: 
		new_1.append(i.id)
	for i in chosen_upgrades["chance_upgrades"]: 
		new_2.append(i.id)
	for i in chosen_upgrades["starter_upgrades"]: 
		new_3.append(i.id)
			
	var new_dict = {}
	json_string = JSON.stringify({"upgrades": {"money_upgrades": new_1, "chance_upgrades":new_2, "starter_upgrades":new_3}})
	save_file.store_line(json_string)
	
	
func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.
		
	chosen_upgrades = {"money_upgrades": [], "chance_upgrades":[], "starter_upgrades":[]}
	reset_stats()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	
	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
	else:
		var data = json.data
		print(data)
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
							
							
