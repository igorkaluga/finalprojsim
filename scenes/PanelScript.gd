extends Panel

@onready var input_scene2 = get_node("VectorControls/Control2")
@onready var control2_node = $VectorControls/Control2
@onready var target_box = $"../SubViewport/CarryObject"
@onready var lesson_container = $lesson_container
signal cord_update
var lesson: bool = false
@onready var button_left = $UIControls/HBoxContainer/VBoxContainer/Button
@onready var button_right = $UIControls/HBoxContainer/VBoxContainer/Button2
@onready var button_shoulder_up = $UIControls/HBoxContainer/VBoxContainer2/Button
@onready var button_shoulder_down = $UIControls/HBoxContainer/VBoxContainer2/Button2
@onready var button_elbow_up = $UIControls/HBoxContainer/VBoxContainer3/Button
@onready var button_elbow_down = $UIControls/HBoxContainer/VBoxContainer3/Button2
@onready var platform = $"../SubViewport/Platform"
@onready var level_goal = $"../SubViewport/LevelGoal"

var current_lvl = 0

var start_info = ["Hello and welcome to my final project for the class of CS6460. This application is meant to serve as an example of simulation based training, exploration based learning, and game based learning.",
				"In this application you will find two approaches to controlling the robot arm. One is through an X, Y, Z coordinate system, while the other is through live UI input.",
				"The user is encouraged to explore these various methods of controlling the robotic arm.",
				"Afterwards, the user is encouraged to open the levels tab and attempt to complete the three levels which are progressively more challenging.",
				"The initial controls that you will see will be the UI input. In on this tab you are able to control the rotation of the base joint by going left or right. Control the shoulder joint by going up or down. And finally, control the elbow joint by going up or donw. This is done by pressing the corresponding buttons.",
				"At any point you may click 'reset' in the top right of the screen to reset the robot simulation."]
				
var vector_info = ["Vector based control of the robot arm is done using Inverse Kinematics, where the angles of each joint is calculated based on the 3D vector provided.",
				 "Currently this section works within -2 to 2 abstract unit space, but you may enter any numbers.",
				"At this stage, some of the units do not work as intended and therefor this section is partially incomplete.",
				"You may try inputting (0,0,-2) or (0,1.5,2) for some examples of working calculations."]

var level_info = ["Welcome to the levels portion of the application. Here you will find 3 levels increasing in difficulty based on the size of the target.",
				"Your goal is to position the end of the robot arm, call an 'endeffector', into the red box. Then you must move this box on top of the blue cylinder.",
				"At the current stage, in some situations the physics are broken, so you may always reset if something unexpected occurs.",
				"To release the container you can click release inside of the UI tab."]
var current_tutorial = null

func _ready():
	input_scene2.on_input_execute.connect(_on_input_recieved2)	
	start_tutorial("start")
	
func start_tutorial(tutorial_type):
	current_index = 0
	match tutorial_type:
		"start":
			current_tutorial = start_info
		"vector":
			current_tutorial = vector_info
		"level":
			current_tutorial = level_info
	cycle_text()
	
func disable_all_input():
	$lesson_container.visible = true
	$HBoxContainer.visible = false
	$VectorControls.visible = false
	$UIControls.visible = false
	$LevelsContainer.visible = false
	$Button.visible = false
	
func enable_all_input(current_tutorial):
	$HBoxContainer.visible = true
	$VectorControls.visible = false
	$UIControls.visible = true
	$LevelsContainer.visible = false
	$Button.visible = true
	$lesson_container.visible = false
	
	if current_tutorial == level_info:
		$LevelsContainer.visible = true
		$UIControls.visible = false
	if current_tutorial == vector_info:
		$VectorControls.visible = true
		$UIControls.visible = false
	
var current_index = 0
func cycle_text():
	if current_tutorial and current_index < current_tutorial.size():
		disable_all_input()
		$lesson_container/RichTextLabel.text = current_tutorial[current_index]
		current_index += 1
		return true
	else:
		current_index = 0
		enable_all_input(current_tutorial)
		return false
	
func _on_input_recieved(data):
	lesson_container.visible = false
	#control_node.custom_minimum_size.y = 30

func _on_input_recieved2(data):
	print("input position: ", data)
	var x = data[0]
	var y = data[1]
	var z = data[2]
	
	target_box.position.x = x
	target_box.position.y = y
	target_box.position.z = z
	
	cord_update.emit(data)

var has_shown_vector_info = false
func on_3d_vector_button_pressed():
	$VectorControls.visible = true
	$UIControls.visible = false
	$LevelsContainer.visible = false
	if not has_shown_vector_info:
		start_tutorial("vector")
		has_shown_vector_info = true

func _on_ui_button_pressed():
	$VectorControls.visible = false
	$UIControls.visible = true
	$LevelsContainer.visible = false

var has_shown_levels_info = false
func _on_levels_pressed():
	$VectorControls.visible = false
	$UIControls.visible = false
	$LevelsContainer.visible = true
	if not has_shown_levels_info:
		start_tutorial("level")
		has_shown_levels_info = true
	
func reload_node(node: Node, scene_path: String):
	var parent = node.get_parent()
	var new_node = load(scene_path).instantiate()
	parent.remove_child(node)
	parent.add_child(new_node)
	node.queue_free()

func _on_robot_reset():
	reload_node($"../SubViewport/RobotArmRoot", "res://robot_arm_root_test.tscn")
	$"../SubViewport/RobotArmRoot"["position"].y = -0.5
	if current_lvl == 1:
		_on_select_lvl_1()
	elif current_lvl == 2:
		_on_select_lvl_2()
	elif current_lvl == 3:
		_on_select_lvl_3()
	else:
		platform.visible = false
		target_box.visible = false
		level_goal.visible = false
	

func _on_button_pressed():
	#deals with level complete continue
	$LevelCompleted.visible = false
	_on_robot_reset()

func _on_select_lvl_1():
	reload_node($"../SubViewport/RobotArmRoot", "res://robot_arm_root_test.tscn")
	$"../SubViewport/RobotArmRoot"["position"].y = -0.5
	current_lvl = 1
	platform.visible = false
	target_box.visible = true
	level_goal.visible = true
	var tween = create_tween()
	tween.tween_property(target_box, "global_position", 
		Vector3(0, 0, -2), 0.0001)
	tween.tween_property(level_goal, "global_position", 
		Vector3(2, -15, 2), 0.0001)
	level_goal.scale = Vector3(3,3,3)

func _on_select_lvl_2():
	reload_node($"../SubViewport/RobotArmRoot", "res://robot_arm_root_test.tscn")
	$"../SubViewport/RobotArmRoot"["position"].y = -0.5
	var tween = create_tween()
	platform.visible = true
	target_box.visible = true
	level_goal.visible = true
	tween.tween_property(target_box, "global_position", 
		Vector3(1, 3, -3), 0.0001)
	tween.tween_property(platform, "global_position", 
		Vector3(1, 1, -3), 0.0001)
	tween.tween_property(level_goal, "global_position", 
		Vector3(0, -8, 3), 0.0001)
	current_lvl = 2
	level_goal.scale = Vector3(2,2,2)

func _on_select_lvl_3():
	reload_node($"../SubViewport/RobotArmRoot", "res://robot_arm_root_test.tscn")
	$"../SubViewport/RobotArmRoot"["position"].y = -0.5
	current_lvl = 3
	target_box.visible = true
	platform.visible = true
	level_goal.visible = true
	var tween = create_tween()
	tween.tween_property(target_box, "global_position", 
		Vector3(1, 4, 2.1), .0001)
	tween.tween_property(platform, "global_position", 
		Vector3(1, 1.5, 2.1), 0.0001)
	tween.tween_property(level_goal, "global_position", 
		Vector3(0, -2, -3), 0.0001)
	level_goal.scale = Vector3(1,1,1)



func _lesson_continue_pressed():
	cycle_text()
