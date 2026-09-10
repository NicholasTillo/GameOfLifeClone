extends Control

# Click-through text tutorial covering the main gameplay loop. Each entry is one
# page: [title, body]. Clicking (or pressing space/enter) advances a page, and
# advancing past the last one returns to the main menu.

@export var title_label: Label
@export var body_label: RichTextLabel
@export var hint_label: Label

const PAGES: Array = [
	["The Ship",
		"You are the captian of the Titan's Wake with one goal, find the Meaning of Life, this quest could take years, generations even. So you must ensure your ships populations stays alive until you find it.
		\n\nThe grid is your crew. Every square is one cell of the ship's population, and your only job is to keep them alive and changing, round after round."],
	["The Rules Of Life",
		"Every round, each cell lives or dies by its neighbours.\n\nAn ALIVE cell with 2 or 3 alive neighbours survives. With fewer than 2, or more than 3, it dies.\n\nA dead cell with exactly 3 alive neighbours becomes ALIVE."],
	["Taking A Turn",
		"[b]Do One[/b] advances the ship a single generation.\n\n[b]Play[/b] runs rounds automatically until you press it again.\n\nWatch how your pattern moves for a few rounds predicting the next move."],
	["Money",
		"Every alive cell that survives a round pays you MONEY.\n\nMoney is spent inside the run: placing new cells, growing the ship, and raising taxes.\n\nIt does not carry over. When the run ends, the money dies with it."],
	["Building",
		"Click any cell on the ship to open the build menu.\n\nALIVE costs 10 money.\nWALL costs 10, never changes, and is useful for shaping a pattern.\nClearing a cell back to DEAD refunds you 10."],
	["The Crew",
		"Some cells work for you.\n\nMECHANIC earns +1 resource each round.\nINNOVATOR earns +1 money each round.\nCHEF keeps every neighbouring cell alive no matter the rules, but eats 25 money a round.\n\nMechanics and innovators die if no alive cell is beside them."],
	["Resource",
		"RESOURCE is the currency that survives death. Mechanics produce it.\n\nSpend it in the Shop between runs on permanent upgrades: more starting money, bigger ships, new crew types, and rewinds.\n\nThis is how you get stronger."],
	["Events",
		"Every 25 rounds something finds the ship: asteroid belts, alien infestations, fires, traders.\n\nEvents change the board permanently, introduce a new threat, or have other unique abilities."],
	["How A Run Ends",
		"The run ends when the board repeats a state it has already been in. The ship has settled, and nothing new will ever happen, forever in a cycle never finding the meaning of life.\n\nYour score is the number of rounds you survived. Every 20 rounds reaches the next chapter of the story."],
	["Good Luck",
		"Keep the pattern alive.\nKeep it changing.\nPush for one more round.\n\nClick to begin."],
]

var index: int = 0


func _ready() -> void:
	_show_page()


func _unhandled_input(event: InputEvent) -> void:
	var clicked = event is InputEventMouseButton and event.pressed
	var keyed = event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_SPACE, KEY_ENTER]
	if not (clicked or keyed):
		return

	get_viewport().set_input_as_handled()
	index += 1
	if index >= PAGES.size():
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else:
		_show_page()


func _show_page() -> void:
	title_label.text = PAGES[index][0]
	body_label.text = PAGES[index][1]
	hint_label.text = "Click to continue      %d / %d" % [index + 1, PAGES.size()]
