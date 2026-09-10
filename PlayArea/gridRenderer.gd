
extends Area2D
class_name GridRenderer

const CELL_SIZE = 13
const ALIVE_COLOR = Color.WHITE
const DEAD_COLOR  = Color(0.1, 0.1, 0.1)

var popup_scene = preload("res://Popup.tscn")
var popup
var _should_draw: bool
var popup_enabled: bool = false
var frame_texture: Texture2D = preload("res://Assets/ShipUpCLose1.png")
var booster_texture: Texture2D = preload("res://Assets/SPrite2.png")

#Booster hangs off the bottom of the main ship only. Both of these are eyeball knobs:
#SCALE sizes the 64x64 art against the grid, OFFSET_Y is how far below the hull's
#bottom edge it sits - raise it to drop the booster further down the screen.
const BOOSTER_SCALE := 2.0
const BOOSTER_OFFSET_Y := 292.0

#Hull frame drawn around every grid, from the Aseprite 9-slice in
#Assets/ShipUpCLose1.json (slice "Slice 1"). Aseprite gives "center" relative to
#"bounds", so the margins below are center.x/y and bounds.wh - (center.xy + center.wh).
const FRAME_REGION := Rect2(13, 6, 37, 41)
const FRAME_TL := Vector2(7, 3)   #left, top margins in source pixels
const FRAME_BR := Vector2(6, 3)   #right, bottom margins in source pixels
#Nine-patch corners draw at their source size, so the art is scaled up to reach
#BORDER thickness. Tune FRAME_SCALE against the art until the corners look right.
const FRAME_SCALE := 4.0
const BORDER := 30.0
#The nine-patch middle is hollow, so it gets filled with this first - otherwise the
#gaps between cells are transparent and show whatever is behind the play area.
const BACKGROUND_COLOR := Color.BLACK




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
	#Booster first, so the hull frame draws over the end that tucks under it.
	draw_booster(offset, state.full_grid_size * CELL_SIZE)
	#Frame next: it fills the background the cells then draw on top of.
	draw_frame(offset, state.full_grid_size * CELL_SIZE)
	for y in range(state.full_grid_size):
		for x in range(state.full_grid_size):
			var color = state.get_cell(x, y).contains.color
			var rect  = Rect2(x * CELL_SIZE + offset.x, y * CELL_SIZE + offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
			draw_rect(rect, color)
	
	
	#Draw Subships
	for i in range(len(state.subgrids)):
		if i == 0:
			offset = (get_viewport_rect().size * Vector2(0.66, 1) - Vector2(state.subgrid_sizes[i] * CELL_SIZE, state.subgrid_sizes[i] * CELL_SIZE)) * Vector2(0.80,0.20)
		else: 
			offset = (get_viewport_rect().size * Vector2(0.66, 1) - Vector2(state.subgrid_sizes[i] * CELL_SIZE, state.subgrid_sizes[i] * CELL_SIZE)) * Vector2(0.20,0.80)
			
		draw_frame(offset, state.subgrid_sizes[i] * CELL_SIZE)
		for y in range(state.subgrid_sizes[i]):
			for x in range(state.subgrid_sizes[i]):
				var color = state.get_subship_cell(x, y, i).contains.color
				var rect  = Rect2(x * CELL_SIZE + offset.x, y * CELL_SIZE + offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
				draw_rect(rect, color)


#Booster centred below the bottom of a grid.
func draw_booster(offset: Vector2, grid_px: float) -> void:
	var size := booster_texture.get_size() * BOOSTER_SCALE
	var pos := Vector2(
			offset.x + grid_px * 0.5 - size.x * 0.5,
			offset.y + grid_px + BORDER + BOOSTER_OFFSET_Y)
	draw_texture_rect(booster_texture, Rect2(pos, size), false)


#One nine-patch hull frame around a grid, hollow in the middle so the cells show
#through. Replaces the eight hand-placed wing textures this used to draw.
func draw_frame(offset: Vector2, grid_px: float) -> void:
	var rect := Rect2(offset.x - BORDER, offset.y - BORDER,
			grid_px + BORDER * 2.0, grid_px + BORDER * 2.0)

	#Fill what the nine-patch leaves hollow. The centre is the frame rect inset by the
	#scaled margins, not the grid rect - the margins are uneven, so it is not symmetric.
	var inset_tl := FRAME_TL * FRAME_SCALE
	var inset_br := FRAME_BR * FRAME_SCALE
	draw_rect(Rect2(rect.position + inset_tl, rect.size - inset_tl - inset_br), BACKGROUND_COLOR)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(FRAME_SCALE, FRAME_SCALE))
	RenderingServer.canvas_item_add_nine_patch(
			get_canvas_item(),
			Rect2(rect.position / FRAME_SCALE, rect.size / FRAME_SCALE),
			FRAME_REGION,
			frame_texture.get_rid(),
			FRAME_TL, FRAME_BR,
			RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH,
			false)
	draw_set_transform_matrix(Transform2D.IDENTITY)


	
		
		
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
				
				if sx >= 0 and sx < state.subgrid_sizes[i] and sy >= 0 and sy < state.subgrid_sizes[i] and changeable_cell(sy * state.subgrid_sizes[i] + sx, i):
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

func changeable_cell(location: int, grid_index: int = -1) -> bool:
	var valid_classes = ["Alive", "Dead", "Wall", "Chef", "Innovator", "Pet1", "Pet2", "Pet3"]
	var cell = GameManager.state.subgrids[grid_index][location] if grid_index >= 0 else GameManager.state.cells[location]
	return cell.contains.id in valid_classes
func redraw():
	queue_redraw()
