extends Control

@export var button1: Button
@export var button2: Button
@export var button3: Button
@export var close_button: Button

func _ready() -> void:
	close_button.pressed.connect(func(): queue_free())
	button1.pressed.connect(take_grid_upgrade)
	button2.pressed.connect(take_ship_upgrade)
	button3.pressed.connect(take_ship_taxes_upgrade)


func take_grid_upgrade():
	PlayerController.grant_free_grid_upgrade()
	queue_free()


func take_ship_upgrade():
	PlayerController.grant_free_ship_upgrade()
	queue_free()


func take_ship_taxes_upgrade():
	PlayerController.grant_free_ship_taxes_upgrade()
	queue_free()
