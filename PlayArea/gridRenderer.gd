
extends Area2D
class_name GridRenderer

const CELL_SIZE = 13
const ALIVE_COLOR = Color.WHITE
const DEAD_COLOR  = Color(0.1, 0.1, 0.1)

var popup_scene = preload("res://Popup.tscn")
var popup

var popup_enabled: bool = false
var wing_texture_top_right: Texture2D = preload("res://Assets/Top Right.png")  # your texture here
var wing_texture_right: Texture2D = preload("res://Assets/WingRight.png")  # your texture here
var wing_texture_bottom_right: Texture2D = preload("res://Assets/RightBottom.png")  # your texture here
var wing_texture_top_left: Texture2D = preload("res://Assets/TopLeftt.png")  # your texture here
var wing_texture_left: Texture2D = preload("res://Assets/WingLeft.png")  # your texture here
var wing_texture_bottom_left: Texture2D = preload("res://Assets/LeftBottom.png")  # your texture here
var wing_texture_top: Texture2D = preload("res://Assets/Top.png")  # your texture here
var wing_texture_bottom: Texture2D = preload("res://Assets/Bottom.png")  # your texture here





func _draw() -> void:
	var state = GameManager.state
	var grid_pixel_size = state.gridSize * CELL_SIZE
	var offset = (get_viewport_rect().size * Vector2(0.66,1) - Vector2(grid_pixel_size, grid_pixel_size)) / 2.0
	
	for y in range(state.gridSize):
		for x in range(state.gridSize):
			var color = state.get_cell(x, y).contains.color
			var rect  = Rect2(x * CELL_SIZE + offset.x, y * CELL_SIZE + offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
			draw_rect(rect, color)
	#Draw LEft Wing
	var grid_px = state.gridSize * CELL_SIZE
	var dest_rect = Rect2(offset.x - 30, offset.y, 30, 30)
	
	draw_left_wing(state, CELL_SIZE, offset)
	draw_right_wing(state, CELL_SIZE, offset)
	draw_top_wing(state, CELL_SIZE, offset)
	#Draw Bottom 
	draw_bottom_wing(state, CELL_SIZE, offset)


func draw_left_wing(state, size, offset):
	var grid_px = state.gridSize * size
	var dest_rect = Rect2(offset.x - 30, offset.y, 30, 30)
	#Draw Top
	draw_texture_rect(wing_texture_top_left, dest_rect, false)
	
	#Draw Middle Section
	dest_rect = Rect2(offset.x - 30, offset.y + 30, 30, grid_px - 60)
	draw_texture_rect(wing_texture_left, dest_rect, false)
	
	dest_rect = Rect2(offset.x - 30, offset.y + grid_px - 30, 30, 30)
	#Draw Bottom
	draw_texture_rect(wing_texture_bottom_left, dest_rect, false)
	
func draw_right_wing(state, size, offset):
	var grid_px = state.gridSize * size
	var dest_rect = Rect2(offset.x + grid_px, offset.y, 30, 30)
	draw_texture_rect(wing_texture_top_right, dest_rect, false)
	dest_rect = Rect2(offset.x + grid_px, offset.y + 30, 30, grid_px - 60)
	draw_texture_rect(wing_texture_right, dest_rect, false)
	dest_rect = Rect2(offset.x + grid_px, offset.y + grid_px - 30, 30, 30)
	draw_texture_rect(wing_texture_bottom_right, dest_rect, false)

func draw_top_wing(state, size, offset):
	var grid_px = state.gridSize * size
	var dest_rect = Rect2(offset.x, offset.y-30, grid_px, 30)
	draw_texture_rect(wing_texture_top, dest_rect, false)
	
func draw_bottom_wing(state, size, offset):
	var grid_px = state.gridSize * size
	var dest_rect = Rect2(offset.x , offset.y + grid_px, grid_px, 30)
	draw_texture_rect(wing_texture_bottom, dest_rect, false)

func _input_event(port, event, ints):
	if event is InputEventMouseButton and event.pressed:
		if popup_enabled: 
			popup_enabled = false
			popup.queue_free()
		else: 
			var grid_pixel_size = GameManager.state.gridSize * CELL_SIZE
			var offset = (get_viewport_rect().size * Vector2(0.66,1) - Vector2(grid_pixel_size, grid_pixel_size)) / 2.0
			
			var x = int((event.position.x - offset.x )/ CELL_SIZE)
			var y = int((event.position.y - offset.y )/ CELL_SIZE)
			if x >= 0 and x < GameManager.state.gridSize and y >= 0 and y < GameManager.state.gridSize:
				var cell = GameManager.state.cells[y * GameManager.state.gridSize + x]
				popup = popup_scene.instantiate()
				popup.position = Vector2(event.position.x,event.position.y)
				popup.cell_num = y * GameManager.state.gridSize + x
				popup.script = self
				add_child(popup)
				queue_redraw()
				popup_enabled = true

func redraw():
	queue_redraw()
