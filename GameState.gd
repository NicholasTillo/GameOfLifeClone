class_name GameState

extends Resource

var nullCell = Cell.new()

@export var gridSize: int = 10
var cells: Array = []

#Player Resoruces

var moneyAmount = 5 + GameManager.starting_money_increase

var subgrids: Array = []
var subgrid_sizes: Array = []
var sub_ship_index = 0
func _init() -> void:
	initialize_grid()
	
func initialize_grid():
	cells = []
	cells.resize(gridSize * gridSize)
	
	
	for i in range(gridSize*gridSize):
		cells[i] = Cell.new()
		if randf() < GameManager.starting_alive_chance:
			cells[i].contains = Alive.new()
		else:
			cells[i].contains = Dead.new()
		cells[i].id = i
		cells[i].contains.cell = cells[i]
		
	#Deal with specific slots: 
	var chosen_ids = []
	for i in range(GameManager.starting_slots):
		var id = randi_range(0, (gridSize*gridSize)  - 1)
		while id in chosen_ids:
			id = randi_range(0,  (gridSize*gridSize) - 1)
		cells[id].contains = GameManager.slots[i]
		cells[id].contains.cell = cells[id]
		chosen_ids.append(id)
	
	#Set up the neighbours. 
	for i in range(gridSize*gridSize):
		var x = i % gridSize
		var y = i / gridSize
			
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx = x + dx
				var ny = y + dy
				if nx < 0 or nx >= gridSize:
					continue
				if ny < 0 or ny >= gridSize:
					continue
				cells[i].neighbours.append(cells[ny * gridSize + nx])
			


func resize_grid(amount: int, input_grid: Array, grid_size: int) -> Array:
	var new_cells = []
	
	new_cells.resize((grid_size + amount) * (grid_size + amount))

	for i in range((grid_size + amount) * (grid_size + amount)):
		new_cells[i] = Cell.new()

		var x = i % (grid_size + amount)
		var y = i / (grid_size + amount)
		if x >= grid_size or y >= grid_size:
			new_cells[i].contains = Dead.new()
		else:
			new_cells[i].contains = input_grid[y * grid_size + x].contains
		new_cells[i].id = i
		new_cells[i].contains.cell = new_cells[i]

	# Set up the neighbours.
	for i in range((grid_size + amount) * (grid_size + amount)):
		var x = i % (grid_size + amount)
		var y = i / (grid_size + amount)

		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx = x + dx
				var ny = y + dy
				if nx < 0 or nx >= (grid_size + amount):
					continue
				if ny < 0 or ny >= (grid_size + amount):
					continue
				new_cells[i].neighbours.append(new_cells[ny * (grid_size + amount) + nx])
	GameManager.renderer.redraw()
	return new_cells

	
	
	
	
	
	

func get_cell(x:int, y:int):
	if not( x >= 0 and x < gridSize and y >= 0 and y < gridSize):
		return null; 
	return cells[y * gridSize + x]
	
func get_subship_cell(x:int, y:int, ship:int):
	if not( x >= 0 and x < subgrid_sizes[ship] and y >= 0 and y < subgrid_sizes[ship]):
		return null; 
	return subgrids[ship][y * subgrid_sizes[ship] + x]

func change_money(x: int):
	moneyAmount += x
	GameManager.ui.update_ui()
	
func how_much_money():
	return moneyAmount
	
	
func add_ship(sub_ship_size):
	#Set up each subgrid in the same way we set up the original.
	subgrids.append([])
	subgrid_sizes.append(sub_ship_size)
	subgrids[sub_ship_index].resize(sub_ship_size * sub_ship_size)
	
	
	for i in range(sub_ship_size*sub_ship_size):
		subgrids[sub_ship_index][i] = Cell.new()
		if randf() < GameManager.starting_alive_chance:
			subgrids[sub_ship_index][i].contains = Alive.new()
		else:
			subgrids[sub_ship_index][i].contains = Dead.new()
		subgrids[sub_ship_index][i].id = i
		subgrids[sub_ship_index][i].contains.cell = subgrids[sub_ship_index][i]

	#Set up the neighbours. 
	for i in range(sub_ship_size*sub_ship_size):
		var x = i % sub_ship_size
		var y = i / sub_ship_size
			
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx = x + dx
				var ny = y + dy
				if nx < 0 or nx >= sub_ship_size:
					continue
				if ny < 0 or ny >= sub_ship_size:
					continue
				subgrids[sub_ship_index][i].neighbours.append(subgrids[sub_ship_index][ny * sub_ship_size + nx])
	sub_ship_index += 1
