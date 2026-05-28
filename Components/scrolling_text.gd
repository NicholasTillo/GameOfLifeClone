extends RichTextLabel

class_name Scrolling_Text
@export var typing_speed: float = 0.05 # Seconds per character
var current_text_index = -1
var list_of_texts: Array
func display_text(new_text: String):
	var tween = create_tween()
	text = new_text
	visible_ratio = 0.0 # Start with 0% of text visible
	# Calculate duration based on text length
	var duration = text.length() * typing_speed
	# Animate visible_ratio from 0 to 1
	tween.tween_property(self, "visible_ratio", 1.0, duration)
	# Optional: Connect to a signal when finished
	tween.finished.connect(_on_typing_finished)
	
	
func list_of_text(text_array):
	list_of_texts = text_array
	
func _on_typing_finished():
	current_text_index += 1
	if len(list_of_texts) > current_text_index:
		await get_tree().create_timer(1.5).timeout
		display_text(list_of_texts[current_text_index])
	else:
		on_finish_list()
	
	
func on_finish_list():
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
