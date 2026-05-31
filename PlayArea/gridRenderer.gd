
extends Area2D
class_name GridRenderer

const CELL_SIZE = 13
const ALIVE_COLOR = Color.WHITE
const DEAD_COLOR  = Color(0.1, 0.1, 0.1)

var popup_scene = preload("res://Popup.tscn")
var popup
var _should_draw: bool
var popup_enabled: bool = false
var wing_texture_top_right: Texture2D = preload("res://Assets/Top Right.png")  # your texture here
var wing_texture_right: Texture2D = preload("res://Assets/WingRight.png")  # your texture here
var wing_texture_bottom_right: Texture2D = preload("res://Assets/RightBottom.png")  # your texture here
var wing_texture_top_left: Texture2D = preload("res://Assets/TopLeftt.png")  # your texture here
var wing_texture_left: Texture2D = preload("res://Assets/WingLeft.png")  # your texture here
var wing_texture_bottom_left: Texture2D = preload("res://Assets/LeftBottom.png")  # your texture here
var wing_texture_top: Texture2D = preload("res://Assets/Top.png")  # your texture here
var wing_texture_bottom: Texture2D = preload("res://Assets/Bottom.png")  # your texture here




func clear():
	_should_draw = false
	redraw()
	
func _draw() -> void:
	var state = GameManager.state
	var grid_pixel_size = state.full_grid_size * CELL_SIZE
	var offset = (get_viewport_rect().size * Vector2(0.66,1) - Vector2(grid_pixel_size, grid_pixel_size)) / 2.0
	
	if not _should_draw:
		_should_draw = true
		return
	for y in range(state.full_grid_size):
		for x in range(state.full_grid_size):
			var color = state.get_cell(x, y).contains.color
			var rect  = Rect2(x * CELL_SIZE + offset.x, y * CELL_SIZE + offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
			draw_rect(rect, color)
	#Draw LEft Wing
	var grid_px = state.full_grid_size * CELL_SIZE
	var dest_rect = Rect2(offset.x - 30, offset.y, 30, 30)
	
	draw_left_wing(state, CELL_SIZE, offset, state.full_grid_size)
	draw_right_wing(state, CELL_SIZE, offset, state.full_grid_size)
	draw_top_wing(state, CELL_SIZE, offset, state.full_grid_size)
	#Draw Bottom 
	draw_bottom_wing(state, CELL_SIZE, offset, state.full_grid_size)
	
	
	#Draw Subships
	for i in range(len(state.subgrids)):
		if i == 0:
			offset = (get_viewport_rect().size * Vector2(0.66, 1) - Vector2(state.subgrid_sizes[i] * CELL_SIZE, state.subgrid_sizes[i] * CELL_SIZE)) * Vector2(0.80,0.20)
		else: 
			offset = (get_viewport_rect().size * Vector2(0.66, 1) - Vector2(state.subgrid_sizes[i] * CELL_SIZE, state.subgrid_sizes[i] * CELL_SIZE)) * Vector2(0.20,0.80)
			
		for y in range(state.subgrid_sizes[i]):
			for x in range(state.subgrid_sizes[i]):
				var color = state.get_subship_cell(x, y, i).contains.color
				var rect  = Rect2(x * CELL_SIZE + offset.x, y * CELL_SIZE + offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
				draw_rect(rect, color)
		print(state.subgrids[i])
		draw_left_wing(state.subgrids[i], CELL_SIZE, offset, state.subgrid_sizes[i])
		draw_right_wing(state.subgrids[i], CELL_SIZE, offset, state.subgrid_sizes[i])
		draw_top_wing(state.subgrids[i], CELL_SIZE, offset, state.subgrid_sizes[i])
		#Draw Bottom 
		draw_bottom_wing(state.subgrids[i], CELL_SIZE, offset, state.subgrid_sizes[i])


func draw_left_wing(state, size, offset, full_grid_size):
	var grid_px = full_grid_size * size
	var dest_rect = Rect2(offset.x - 30, offset.y, 30, 30)
	#Draw Top
	draw_texture_rect(wing_texture_top_left, dest_rect, false)
	
	#Draw Middle Section
	dest_rect = Rect2(offset.x - 30, offset.y + 30, 30, grid_px - 60)
	draw_texture_rect(wing_texture_left, dest_rect, false)
	
	dest_rect = Rect2(offset.x - 30, offset.y + grid_px - 30, 30, 30)
	#Draw Bottom
	draw_texture_rect(wing_texture_bottom_left, dest_rect, false)
	
func draw_right_wing(state, size, offset, full_grid_size):
	var grid_px = full_grid_size * size
	var dest_rect = Rect2(offset.x + grid_px, offset.y, 30, 30)
	draw_texture_rect(wing_texture_top_right, dest_rect, false)
	dest_rect = Rect2(offset.x + grid_px, offset.y + 30, 30, grid_px - 60)
	draw_texture_rect(wing_texture_right, dest_rect, false)
	dest_rect = Rect2(offset.x + grid_px, offset.y + grid_px - 30, 30, 30)
	draw_texture_rect(wing_texture_bottom_right, dest_rect, false)

func draw_top_wing(state, size, offset, full_grid_size):
	var grid_px = full_grid_size * size
	var dest_rect = Rect2(offset.x, offset.y-30, grid_px, 30)
	draw_texture_rect(wing_texture_top, dest_rect, false)
	
func draw_bottom_wing(state, size, offset, full_grid_size):
	var grid_px = full_grid_size * size
	var dest_rect = Rect2(offset.x , offset.y + grid_px, grid_px, 30)
	draw_texture_rect(wing_texture_bottom, dest_rect, false)

func _input_event(port, event, ints):
	if event is InputEventMouseButton and event.pressed:
		if popup_enabled: 
			popup_enabled = false
			popup.queue_free()
		else: 
			var state = GameManager.state
			
			# Check Main Grid
			var grid_pixel_size = state.full_grid_size * CELL_SIZE
			var offset = (get_viewport_rect().size * Vector2(0.66,1) - Vector2(grid_pixel_size, grid_pixel_size)) / 2.0
			
			var x = int((event.position.x - offset.x )/ CELL_SIZE)
			var y = int((event.position.y - offset.y )/ CELL_SIZE)
			if x >= 0 and x < state.full_grid_size and y >= 0 and y < state.full_grid_size and changeable_cell(y * state.full_grid_size + x):
				_spawn_popup(event.position, y * state.full_grid_size + x, -1)
				return

			# Check Subgrids
			for i in range(len(state.subgrids)):
				var sub_offset: Vector2
				if i == 0:
					sub_offset = (get_viewport_rect().size * Vector2(0.66, 1) - Vector2(state.subgrid_sizes[i] * CELL_SIZE, state.subgrid_sizes[i] * CELL_SIZE)) * Vector2(0.80,0.20)
				else: 
					sub_offset = (get_viewport_rect().size * Vector2(0.66, 1) - Vector2(state.subgrid_sizes[i] * CELL_SIZE, state.subgrid_sizes[i] * CELL_SIZE)) * Vector2(0.20,0.80)
				
				var sx = int((event.position.x - sub_offset.x) / CELL_SIZE)
				var sy = int((event.position.y - sub_offset.y) / CELL_SIZE)
				
				if sx >= 0 and sx < state.subgrid_sizes[i] and sy >= 0 and sy < state.subgrid_sizes[i] and changeable_cell(y * state.full_grid_size + x):
					_spawn_popup(event.position, sy * state.subgrid_sizes[i] + sx, i)
					return

func _spawn_popup(pos: Vector2, cell_idx: int, g_idx: int):
	popup = popup_scene.instantiate()
	popup.position = pos
	popup.cell_num = cell_idx
	popup.grid_index = g_idx
	add_child(popup)
	queue_redraw()
	popup_enabled = true

func changeable_cell(location:int):
	var valid_classes= ["Alive", "Dead", "Wall","Chef","Nurse","Pet1","Pet2","Pet3"]
	if GameManager.state.cells[location].contains.id in valid_classes :
		return true
	else:
		return false
func redraw():
	queue_redraw()
