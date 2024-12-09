extends Control

@onready var line_edit = $Panel/VBoxContainer/HBoxContainer/LineEdit
@onready var line_edit2 = $Panel/VBoxContainer/HBoxContainer2/LineEdit
@onready var line_edit3 = $Panel/VBoxContainer/HBoxContainer3/LineEdit

signal on_input_execute
signal on_menu_collapse

func _on_button_pressed():
	var input_text = float(line_edit.text)
	var input_text2 = float(line_edit2.text)
	var input_text3 = float(line_edit3.text)
	var input_coords = [input_text,input_text2,input_text3]
	on_input_execute.emit(input_coords)
	
func _on_exec_button_pressed():
	pass
	
@onready var panel = $Panel
@onready var vbox = $Panel/VBoxContainer
@onready var button = $Panel/VBoxContainer/Button2
@onready var label = $Panel/VBoxContainer/Label
@onready var boxCont = $Panel/VBoxContainer/HBoxContainer
@onready var boxCont2 = $Panel/VBoxContainer/HBoxContainer2
@onready var boxCont3 = $Panel/VBoxContainer/HBoxContainer3
@onready var execButton = $Panel/VBoxContainer/Button

@onready var boxes_arr = [label, boxCont, boxCont2, boxCont3, execButton]
var is_collapsed := false
var expanded_size: float = 10
var collapsed_size: float = 10  # Height when collapsed (just showing button)
var animation_speed := 0.3

func _ready():
	# Store the original expanded size
	expanded_size = panel.size.y
	# Connect button signal
	button.pressed.connect(_on_toggle_button_pressed)
	execButton.pressed.connect(_on_button_pressed)
	# Optional: Set up initial appearance
	button.text = "▼ Menu"  # Down arrow when expanded
	
func _on_toggle_button_pressed():
	on_menu_collapse.emit(true)
	is_collapsed = !is_collapsed
	# Create a new tween
	var tween = create_tween()
	
	if is_collapsed:
		# Collapse animation
		tween.tween_property(panel, "custom_minimum_size:y", collapsed_size, animation_speed)
		button.text = "▶ Menu"  # Right arrow when collapsed
		for box in boxes_arr:
			box.visible = false

	else:
		# Expand animation
		tween.tween_property(panel, "custom_minimum_size:y", expanded_size, animation_speed)
		button.text = "▼ Menu"  # Down arrow when expanded
		for box in boxes_arr:
			#print("DEBUG: box", box)
			box.visible = true


# Optional: Add method to programmatically toggle the menu
func toggle_menu(collapse: bool):
	if is_collapsed != collapse:
		_on_toggle_button_pressed()

