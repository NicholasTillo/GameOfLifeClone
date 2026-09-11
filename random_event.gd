extends Resource

class_name random_event


@export var name: String
@export var text: String
@export var id: int
@export var enabled: bool

#Chapter gate. The event stays out of the random pool until the player has seen this many
#cutscenes; 0 (the default) means available from the first run. GameManager's
#current_cutscene_index only ever counts up and is written to the save file, so an event
#unlocked this way stays unlocked for good.
@export var required_cutscene: int = 0
