class_name GameState

extends Resource

var nullCell = Cell.new()

@export var gridSize: int = 10
var cells: Array = []

#Player Resoruces

var moneyAmount = 5 + GameManager.starting_money_increase


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
		print(cells)
		print(GameManager.slots)
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
			


func resize_grid(amount:int):
	#Columns
	var new_cells = []
	new_cells.resize((gridSize + amount) *(gridSize+ amount))
	var offset = 0
	
	for i in range((gridSize + amount) * (gridSize+ amount)):
		new_cells[i] = Cell.new()
		
		var x = i % (gridSize + amount)
		var y = i / (gridSize + amount)
		if x >= gridSize or y >= gridSize:
			new_cells[i].contains = Dead.new()

		else:
			new_cells[i].contains = cells[y * gridSize + x].contains
		new_cells[i].id = i
		new_cells[i].contains.cell = new_cells[i]
		
	#Set up the neighbours. 
	for i in range((gridSize + amount) *(gridSize+ amount)):
		var x = i % (gridSize + amount)
		var y = i / (gridSize+ amount)
			
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx = x + dx
				var ny = y + dy
				if nx < 0 or nx >= (gridSize+ amount):
					continue
				if ny < 0 or ny >= (gridSize+ amount):
					continue
				new_cells[i].neighbours.append(new_cells[ny * (gridSize + amount) + nx])

	
	gridSize += amount
	cells = new_cells
	GameManager.renderer.redraw()
	
	

func get_cell(x:int, y:int):
	if not( x >= 0 and x < gridSize and y >= 0 and y < gridSize):
		return null; 
	return cells[y * gridSize + x]


func change_money(x: int):
	moneyAmount += x
	GameManager.ui.update_ui()
	
func how_much_money():
	return moneyAmount
	
	
