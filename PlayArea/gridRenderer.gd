
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
const BOOSTER_OFFSET_Y := 40.0

#Booster exhaust: the same particle system as the thruster plume in the opening cutscene
#(Scenes/Cutscene0.tscn) - same 15x15 noise texture, same orange-to-red ramp, same spin and
#orbit drift, same slow 20fps step - with ONE change. The cutscene pushes its particles
#left across the screen (gravity -200 on X) because the ship is flying past; here the ship
#is pointing up the screen, so the exhaust goes straight down instead.
const THRUST_GRAVITY := 200.0          #pixels/sec^2. +Y is down in 2D
const THRUST_LIFETIME := 1.72
const THRUST_FPS := 20
const THRUST_AMOUNT := 8               #GPUParticles2D default, kept deliberately
const THRUST_AMOUNT_RATIO := 0.1718
const THRUST_SPIN := 10.0              #angular_velocity, +/- this
const THRUST_ORBIT := 0.05             #orbit_velocity, +/- this
const THRUST_NOISE_SIZE := 15
const THRUST_BUMP := 3.2
const THRUST_HOT := Color(0.85490197, 0.6509804, 0.3137255, 1.0)
const THRUST_COOL := Color(0.8039216, 0.14509805, 0.15686275, 1.0)

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
#The strips of that fill above and below the cells. Empty cells are black too, so on a black
#strip there was no telling where the grid stopped and the hull began.
const GUTTER_COLOR := Color("9badb7")
#Radiation shielding, drawn over the cells while the grid is locked. Kept translucent on
#purpose: opaque enough to read as "hands off", thin enough to watch the board through.
const SHIELD_COLOR := Color(1.0, 0.72, 0.20, 0.28)

#Little 8x8 markers that float up off a cell and fade: a skull where somebody died, a green
#$ where somebody got paid, an orange triangle where resource was produced. Eyeball knobs.
#
#A skull can afford to be near-invisible because it appears over a cell that just turned
#BLACK - all the contrast is free. Money and resource are the opposite: they fire over a
#cell that is still ALIVE and bright (white crew, orange mechanic), so a faint marker is
#washed out completely. That is why they are near-opaque and, more importantly, are given
#an initial upward SPEED - gravity alone accelerates from zero, which parks the marker on
#top of the bright cell for exactly the frames when it is at its most visible.
const SKULL_ALPHA := 0.28       #peak opacity, before the fade to nothing
const SKULL_LIFETIME := 1.2     #seconds from spawn to fully faded
const SKULL_RISE := 18.0        #upward acceleration, pixels/sec^2
const SKULL_SPEED := 0.0        #no kick; it drifts off a dark cell and reads fine
const SKULL_CAP := 128          #max concurrent; past this the oldest is recycled

#Money is far denser than death - every surviving crew member earns EVERY round, so a
#40-strong crew on autoplay is ~160 signs/second, where deaths come in occasional bursts.
#Hence the short life. Turn MONEY_ALPHA down if the board starts looking green.
const MONEY_ALPHA := 0.85
const MONEY_LIFETIME := 0.8
const MONEY_RISE := 26.0
const MONEY_SPEED := 34.0       #clears the white cell it was earned on within ~0.15s
const MONEY_CAP := 128
#Deep saturated green: a pale green is unreadable against a white living cell.
const MONEY_COLOR := Color(0.05, 0.75, 0.15)

#Resource is much rarer than money - only Mechanics make it.
const RESOURCE_ALPHA := 0.85
const RESOURCE_LIFETIME := 0.9
const RESOURCE_RISE := 26.0
const RESOURCE_SPEED := 34.0
const RESOURCE_CAP := 64
const RESOURCE_COLOR := Color(1.0, 0.5, 0.0)

var skull_texture: Texture2D = preload("res://Assets/Skull.png")
var money_texture: Texture2D = preload("res://Assets/Money.png")
var resource_texture: Texture2D = preload("res://Assets/Resource.png")
var _thrust: GPUParticles2D
#The markers are drawn by hand on _pop_layer, not emitted as GPU particles. The web build runs
#the Compatibility renderer, which ignores GPUParticles2D.emit_particle(), so every skull, $
#and triangle silently vanished there. One Dictionary per kind (see _pop_kind), its live
#markers in "pops" as [position, age], oldest first.
var _skulls: Dictionary
var _money: Dictionary
var _resource: Dictionary
var _pop_layer: Node2D
#Whether the layer had anything on it last frame, so it gets one last redraw to wipe the
#final marker off after it expires.
var _pops_visible: bool = false


#One vague sentence per cell type, shown when the mouse rests on a cell. Deliberately
#imprecise about the exact counts - the player is meant to work the rules out - and keyed
#by Class.id, so an id with no entry here simply shows no hint instead of erroring.
const CELL_HINTS := {
	"Alive": "Alive
A base crew member, staying alive makes money, and it dies to overcrowding and isolation.",
	"Dead": "Empty
An empty berth, which fills itself with new crew when just enough of them are gathered around it.",
	"Wall": "Wall
Bare hull plating, it never changes and nothing spreads through it.",
	"Chef": "Chef
Keeps every neighbour fed and alive no matter what, for a hefty wage every round.",
	"Innovator": "Innovator
Tinkers away for extra money each round, but will not last without crew beside it.",
	"Mechanic": "Mechanic
Works the ship for resources each round, but will not last without crew beside it.",
	"Revolutionary": "Revolutionary
Earns you nothing, and talks the crew around it into joining the cause.",
	"Springtrap": "Springtrap
Something in the vents kills the crew near it for a handful of nights, then is gone.",
	"Corpse": "Corpse
What the vents leave behind, and it will never change again.",
	"Zombie": "Zombie
Spreads into the crew it touches, and cannot survive alone or in a crowd.",
	"Fire": "Fire
Burns for a while, catches on whatever is beside it, and leaves an empty berth.",
	"Life": "Life
It gets into everything it touches, and it does not stop.",
	"Sandshark": "Sandshark
An exotic pet with an expensive appetite, and it leaves something useful behind.",
	"Plorian": "Plorian
An exotic pet that will not settle. It has somewhere to be, and it knows the dead.",
	"Dog": "Dog
A loyal pet. The crew beside it work twice as hard, and it pines away without people.",
	"TotallyAlive": "Totally Alive
Crew, as far as anything around it can tell, and nothing aboard can take it.",
	"Doctor": "Doctor
Works like any crew member, and puts the bodies beside it back on their feet.",
	"Robot": "Robot
Props up the crew around it and asks nothing of the room, but it seizes up with no Mechanic aboard.",
	"NuclearEngineer": "Nuclear Engineer
Crew like any other, until you stand it next to the machines. Then it makes resource, and more of it the more machines there are.",
	"Captain": "Captain
While one is aboard the whole crew is paid better, and some of those who should be lost are not.",
}

#Hint panel geometry. HINT_WIDTH is what the text wraps at; the offset keeps the panel
#clear of the cursor so it never covers the cell being asked about.
const HINT_WIDTH := 300.0
const HINT_OFFSET := Vector2(16.0, 16.0)
#How long the cursor has to sit still before the hint appears. A hint that tracked the
#mouse live flickered through a cell type per pixel and was pure noise.
const HINT_DELAY := 1.0

var _hint: PanelContainer
var _hint_label: RichTextLabel
var _hint_timer: Timer
var _hint_pos: Vector2


func _ready() -> void:
	_skulls = _pop_kind(skull_texture, Color.WHITE, SKULL_ALPHA,
			SKULL_LIFETIME, SKULL_RISE, SKULL_SPEED, SKULL_CAP)
	_money = _pop_kind(money_texture, MONEY_COLOR, MONEY_ALPHA,
			MONEY_LIFETIME, MONEY_RISE, MONEY_SPEED, MONEY_CAP)
	_resource = _pop_kind(resource_texture, RESOURCE_COLOR, RESOURCE_ALPHA,
			RESOURCE_LIFETIME, RESOURCE_RISE, RESOURCE_SPEED, RESOURCE_CAP)
	#Its own canvas item, so the markers can redraw every frame without the whole board
	#redrawing with them.
	_pop_layer = Node2D.new()
	_pop_layer.draw.connect(_draw_pops)
	add_child(_pop_layer)
	_thrust = _build_thrust()
	add_child(_thrust)
	_build_hint()
	mouse_exited.connect(_hide_hint)


#One marker kind: its look, its motion, and the markers of it currently on screen.
func _pop_kind(texture: Texture2D, tint: Color, alpha: float,
		life: float, rise: float, speed: float, cap: int) -> Dictionary:
	return {"texture": texture, "tint": tint, "alpha": alpha, "life": life,
			"rise": rise, "speed": speed, "cap": cap, "pops": []}


#Ages every marker and drops the expired ones. Markers of a kind share a lifetime and are
#appended in spawn order, so the expired ones are always at the front.
func _process(delta: float) -> void:
	var live := false
	for kind in [_skulls, _money, _resource]:
		var pops: Array = kind.pops
		for pop in pops:
			pop[1] += delta
		while not pops.is_empty() and pops[0][1] >= kind.life:
			pops.pop_front()
		live = live or not pops.is_empty()
	if live or _pops_visible:
		_pop_layer.queue_redraw()
	_pops_visible = live


#Each marker launches upward at `speed`, accelerates at `rise`, and fades linearly from
#`alpha` to nothing over its life - the same curve the particle version had. The textures
#are white, so the tint carries all the colour.
func _draw_pops() -> void:
	for kind in [_skulls, _money, _resource]:
		var texture: Texture2D = kind.texture
		var half: Vector2 = texture.get_size() * 0.5
		var life: float = kind.life
		for pop in kind.pops:
			var t: float = pop[1]
			var lift: float = kind.speed * t + 0.5 * kind.rise * t * t
			var colour := Color(kind.tint, kind.alpha * (1.0 - t / life))
			_pop_layer.draw_texture(texture, pop[0] - half - Vector2(0.0, lift), colour)


#The booster plume. Unlike the pop emitters this one runs continuously and is positioned
#from draw_booster(), because where the booster sits depends on the grid's current size.
func _build_thrust() -> GPUParticles2D:
	#Two stops at the Gradient's default 0.0/1.0 offsets: hot inner flame to cooler outer.
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([THRUST_HOT, THRUST_COOL])

	var noise := NoiseTexture2D.new()
	noise.width = THRUST_NOISE_SIZE
	noise.height = THRUST_NOISE_SIZE
	noise.noise = FastNoiseLite.new()
	noise.color_ramp = ramp
	noise.bump_strength = THRUST_BUMP

	var mat := ParticleProcessMaterial.new()
	#orbit_velocity is 2D-only and needs Z motion switched off to do anything.
	mat.particle_flag_disable_z = true
	mat.angular_velocity_min = -THRUST_SPIN
	mat.angular_velocity_max = THRUST_SPIN
	mat.orbit_velocity_min = -THRUST_ORBIT
	mat.orbit_velocity_max = THRUST_ORBIT
	#The one difference from the cutscene, whose gravity is Vector3(-200, 0, 0).
	mat.gravity = Vector3(0.0, THRUST_GRAVITY, 0.0)

	var emitter := GPUParticles2D.new()
	emitter.process_material = mat
	emitter.texture = noise
	emitter.amount = THRUST_AMOUNT
	emitter.amount_ratio = THRUST_AMOUNT_RATIO
	emitter.lifetime = THRUST_LIFETIME
	emitter.fixed_fps = THRUST_FPS
	#Starts mid-plume instead of coughing into life on the first frame of a run.
	emitter.preprocess = THRUST_LIFETIME
	#A particle falls THRUST_GRAVITY * lifetime^2 / 2 before it dies, so the default
	#200x200 rect would cull the plume the moment it left the booster.
	emitter.visibility_rect = Rect2(Vector2(-200.0, -200.0),
			Vector2(400.0, 400.0 + THRUST_GRAVITY * THRUST_LIFETIME * THRUST_LIFETIME))
	#Hidden until draw_booster() has somewhere to put it.
	emitter.hide()
	return emitter


#A skull at the centre of a cell that just lost somebody. Called by GridNode, which is the
#only place that knows a death happened. grid_index -1 is the main grid, 0/1 a subship.
func spawn_death_skull(cell_index: int, grid_index: int) -> void:
	_emit_pop(_skulls, cell_index, grid_index)


#A green $ over a cell that just got paid this round.
func spawn_money_pop(cell_index: int, grid_index: int) -> void:
	_emit_pop(_money, cell_index, grid_index)


#An orange triangle over a cell that just produced resource.
func spawn_resource_pop(cell_index: int, grid_index: int) -> void:
	_emit_pop(_resource, cell_index, grid_index)


func _emit_pop(kind: Dictionary, cell_index: int, grid_index: int) -> void:
	#_should_draw is false before the first draw and after clear() at the end of a run -
	#either way there is no board on screen to put a marker on.
	if kind.is_empty() or not _should_draw:
		return
	var pops: Array = kind.pops
	#Past the cap the oldest makes way, so a mass die-off on autoplay can't pile up forever.
	if pops.size() >= kind.cap:
		pops.pop_front()
	pops.append([cell_centre(cell_index, grid_index), 0.0])


#--- Grid geometry. Single source of truth: _draw(), _input_event() and the skull
#--- spawner all place cells through these. grid_index -1 means the main grid.
#--- These return coordinates in this node's own space. The Area2D sits at the origin
#--- with no transform, so that is also screen space - which is why cell_at() can be
#--- handed a raw global event.position. Move or scale the Area2D and all three break
#--- together, not one at a time.

func grid_cells_across(grid_index: int) -> int:
	var state = GameManager.state
	return state.full_grid_size if grid_index < 0 else state.subgrid_sizes[grid_index]


func grid_offset(grid_index: int) -> Vector2:
	var span := grid_cells_across(grid_index) * CELL_SIZE
	var free_space := get_viewport_rect().size * Vector2(0.66, 1) - Vector2(span, span)
	if grid_index < 0:
		return free_space / 2.0
	elif grid_index == 0:
		return free_space * Vector2(0.80, 0.20)
	else:
		return free_space * Vector2(0.20, 0.80)


func cell_centre(index: int, grid_index: int) -> Vector2:
	var across := grid_cells_across(grid_index)
	return grid_offset(grid_index) \
			+ Vector2(index % across + 0.5, index / across + 0.5) * CELL_SIZE


#Which cell a screen position falls on, or -1 if it misses this grid.
func cell_at(pos: Vector2, grid_index: int) -> int:
	var across := grid_cells_across(grid_index)
	var local := (pos - grid_offset(grid_index)) / CELL_SIZE
	var x := int(local.x)
	var y := int(local.y)
	if local.x < 0 or local.y < 0 or x >= across or y >= across:
		return -1
	return y * across + x


func clear():
	_should_draw = false
	_hide_hint()
	#The markers live on this autoloaded renderer, so without this the last round's skulls
	#would keep floating over the death screen or cutscene.
	for kind in [_skulls, _money, _resource]:
		kind.pops.clear()
	#The run is over and the ship is gone; the booster stops with it.
	if _thrust != null:
		_thrust.hide()
	redraw()

func _draw() -> void:
	var state = GameManager.state
	var offset := grid_offset(-1)

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
	draw_shield(offset, state.full_grid_size * CELL_SIZE)


	#Draw Subships
	for i in range(len(state.subgrids)):
		offset = grid_offset(i)
		draw_frame(offset, state.subgrid_sizes[i] * CELL_SIZE)
		for y in range(state.subgrid_sizes[i]):
			for x in range(state.subgrid_sizes[i]):
				var color = state.get_subship_cell(x, y, i).contains.color
				var rect  = Rect2(x * CELL_SIZE + offset.x, y * CELL_SIZE + offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
				draw_rect(rect, color)
		draw_shield(offset, state.subgrid_sizes[i] * CELL_SIZE)


#Radiation shielding over a grid while an event has the board locked. Drawn after the
#cells and only over them, so the board stays readable through it - the player can watch
#the round play out, they just cannot reach it. The hull frame is left clear.
func draw_shield(offset: Vector2, grid_px: float) -> void:
	if not GameManager.grid_locked():
		return
	draw_rect(Rect2(offset, Vector2(grid_px, grid_px)), SHIELD_COLOR)


#Booster centred below the bottom of a grid.
func draw_booster(offset: Vector2, grid_px: float) -> void:
	var size := booster_texture.get_size() * BOOSTER_SCALE
	var pos := Vector2(
			offset.x + grid_px * 0.5 - size.x * 0.5,
			offset.y + grid_px + BORDER + BOOSTER_OFFSET_Y)
	draw_texture_rect(booster_texture, Rect2(pos, size), false)

	#Exhaust leaves the bottom edge of the booster art, centred on it. Set here rather
	#than in _ready() because the booster moves whenever the grid is upgraded.
	if _thrust != null:
		_thrust.position = pos + Vector2(size.x * 0.5, size.y)
		_thrust.show()


#One nine-patch hull frame around a grid, hollow in the middle so the cells show
#through. Replaces the eight hand-placed wing textures this used to draw.
func draw_frame(offset: Vector2, grid_px: float) -> void:
	var rect := Rect2(offset.x - BORDER, offset.y - BORDER,
			grid_px + BORDER * 2.0, grid_px + BORDER * 2.0)

	#Fill what the nine-patch leaves hollow. The centre is the frame rect inset by the
	#scaled margins, not the grid rect - the margins are uneven, so it is not symmetric.
	var inset_tl := FRAME_TL * FRAME_SCALE
	var inset_br := FRAME_BR * FRAME_SCALE
	var inner := Rect2(rect.position + inset_tl, rect.size - inset_tl - inset_br)
	draw_rect(inner, BACKGROUND_COLOR)
	#Stops 1px short of the cells so a black line sits above the top row, matching the 1px
	#gap every cell already leaves below itself (which is the line under the bottom row).
	draw_rect(Rect2(inner.position.x, inner.position.y,
			inner.size.x, offset.y - inner.position.y - 1.0), GUTTER_COLOR)
	#1px taller than the hollow: at every other grid size the offset lands on a half pixel and
	#a black row showed between this strip and the hull art. The frame draws over the extra.
	draw_rect(Rect2(inner.position.x, offset.y + grid_px,
			inner.size.x, inner.end.y - offset.y - grid_px + 1.0), GUTTER_COLOR)

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
	if event is InputEventMouseMotion:
		_update_hint(event.position)
		return
	if event is InputEventMouseButton and event.pressed:
		if popup_enabled: 
			popup_enabled = false
			popup.queue_free()
		else:
			var state = GameManager.state

			# Check Main Grid
			var hit := cell_at(event.position, -1)
			if hit >= 0 and changeable_cell(hit):
				_spawn_popup(event.position, hit, -1)
				return

			# Check Subgrids
			for i in range(len(state.subgrids)):
				var sub_hit := cell_at(event.position, i)
				if sub_hit >= 0 and changeable_cell(sub_hit, i):
					_spawn_popup(event.position, sub_hit, i)
					return

func _spawn_popup(pos: Vector2, cell_idx: int, g_idx: int):
	_hide_hint()
	popup = popup_scene.instantiate()
	popup.position = pos
	popup.cell_num = cell_idx
	popup.grid_index = g_idx
	add_child(popup)
	queue_redraw()
	popup_enabled = true

#The Cell at an index. grid_index -1 is the main grid, 0/1 a subship. Its occupant is
#cell.contains - this hands back the Cell, not the Class, so callers can reach either.
func cell_at_index(location: int, grid_index: int = -1) -> Cell:
	var state = GameManager.state
	return state.subgrids[grid_index][location] if grid_index >= 0 else state.cells[location]


func changeable_cell(location: int, grid_index: int = -1) -> bool:
	#Cells the player is allowed to click and replace. Hostile/trap cells (Zombie,
	#Springtrap, Corpse, Fire, Life, Revolutionary) are deliberately absent - they
	#cannot be cleared away. "Pet1"/"Pet2"/"Pet3" used to be listed here and matched
	#nothing; the pets' real ids are below.
	var valid_classes = ["Alive", "Dead", "Wall", "Chef", "Innovator", "Mechanic",
			"Sandshark", "Plorian", "Dog", "TotallyAlive", "Doctor",
			"Robot", "NuclearEngineer", "Captain"]
	#An event can take the whole board away for a few rounds (Solar Flare). Asked here
	#rather than in _input_event because this is the one gate every click path goes
	#through, main grid and subships alike.
	if GameManager.grid_locked():
		return false
	return cell_at_index(location, grid_index).contains.id in valid_classes


#Closes any open cell popup. Used when an event shuts the board down underneath one.
func dismiss_popup() -> void:
	if popup_enabled:
		popup_enabled = false
		if is_instance_valid(popup):
			popup.queue_free()

#--- Hover hint. A small panel naming the cell the cursor has come to rest on.

func _build_hint() -> void:
	_hint_label = RichTextLabel.new()
	#fit_content plus a fixed width is what makes the panel size itself to the wrapped
	#text; without it a RichTextLabel collapses to nothing inside a container.
	_hint_label.bbcode_enabled = false
	_hint_label.fit_content = true
	_hint_label.scroll_active = false
	_hint_label.custom_minimum_size = Vector2(HINT_WIDTH, 0.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.border_color = Color(0.6, 0.6, 0.7, 0.8)
	style.set_border_width_all(1)
	style.set_content_margin_all(8.0)

	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", style)
	#The hint must never eat a click meant for the cell underneath it.
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_child(_hint_label)
	_hint.hide()
	add_child(_hint)

	#One-shot, restarted by every mouse move, so it only ever fires on a cursor that
	#has come to rest.
	_hint_timer = Timer.new()
	_hint_timer.one_shot = true
	_hint_timer.wait_time = HINT_DELAY
	_hint_timer.timeout.connect(_show_hint)
	add_child(_hint_timer)


func _hide_hint() -> void:
	if _hint != null:
		_hint.hide()
	#Without this a hint queued before the board was cleared still pops up afterwards.
	if _hint_timer != null:
		_hint_timer.stop()


#Every mouse move drops the current hint and restarts the wait, so the hint only ever
#shows up once the player has stopped on a cell.
func _update_hint(pos: Vector2) -> void:
	_hide_hint()
	if _hint == null or not _should_draw or popup_enabled:
		return
	_hint_pos = pos
	_hint_timer.start()


#Fired by _hint_timer. The cell is looked up now rather than when the mouse stopped, so a
#board that advanced during the wait still gets described correctly.
func _show_hint() -> void:
	if _hint == null or not _should_draw or popup_enabled:
		return

	var pos := _hint_pos
	var id := ""
	var hit := cell_at(pos, -1)
	if hit >= 0:
		id = cell_at_index(hit).contains.id
	else:
		for i in range(len(GameManager.state.subgrids)):
			var sub_hit := cell_at(pos, i)
			if sub_hit >= 0:
				id = cell_at_index(sub_hit, i).contains.id
				break

	if not CELL_HINTS.has(id):
		_hide_hint()
		return

	_hint_label.text = CELL_HINTS[id]
	#Flip the panel back over the cursor rather than letting it run off screen.
	var size := _hint.get_combined_minimum_size()
	var screen := get_viewport_rect().size
	var spot := pos + HINT_OFFSET
	if spot.x + size.x > screen.x:
		spot.x = pos.x - size.x - HINT_OFFSET.x
	if spot.y + size.y > screen.y:
		spot.y = pos.y - size.y - HINT_OFFSET.y
	_hint.position = spot
	_hint.show()


func redraw():
	queue_redraw()
