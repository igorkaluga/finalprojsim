extends Node3D

@onready var Base: StaticBody3D = $Base
@onready var BaseJoint: HingeJoint3D = $Base/BaseJoint
@onready var Shoulder: RigidBody3D = $Base/BaseJoint/Shoulder
@onready var ShoulderJoint: HingeJoint3D = $Base/BaseJoint/Shoulder/ShoulderJoint
@onready var Arm1: RigidBody3D = $Base/BaseJoint/Shoulder/ShoulderJoint/Arm1
@onready var ElbowJoint: HingeJoint3D = $Base/BaseJoint/Shoulder/ShoulderJoint/Arm1/ElbowJoint
@onready var Arm2: RigidBody3D = $Base/BaseJoint/Shoulder/ShoulderJoint/Arm1/ElbowJoint/Arm2
@onready var EndEffector: Area3D = $Base/BaseJoint/Shoulder/ShoulderJoint/Arm1/ElbowJoint/Arm2/EF
#@onready var EndEffectorJoint = $Base/BaseJoint/Shoulder/ShoulderJoint/Arm1/ElbowJoint/Arm2/EF/Generic6DOFJoint3D
@onready var CarryObject = "/root/Main/SubViewport/CarryObject"
@onready var panel_scene = get_node("/root/Main/Panel")

@onready var button_left = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer/Button")
@onready var button_right = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer/Button2")
@onready var button_shoulder_up = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer2/Button")
@onready var button_shoulder_down = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer2/Button2")
@onready var button_elbow_up = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer3/Button")
@onready var button_elbow_down = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer3/Button2")

@onready var vector_controls = get_node("/root/Main/Panel/HBoxContainer/Button")
@onready var ui_controls = get_node("/root/Main/Panel/HBoxContainer/Button2")
@onready var release = get_node("/root/Main/Panel/UIControls/HBoxContainer/VBoxContainer2/Button3")


const MAX_MOTOR_VELOCITY = 1.5
const MOTOR_ACCELERATION = 2.0
const DAMPING = 0.5
var debug = false

var current_velocities = {
	"base": 0.0,
	"shoulder": 0.0,
	"elbow": 0.0
}

var target_position: Vector3 = Vector3(1000,0,0) 
var is_ik_enabled: bool = false

signal _on_body_entered_signal
	
func _ready():
	configure_physics()
	setup_joints()
	panel_scene.cord_update.connect(_test_cord_update)
	EndEffector.body_entered.connect(_on_body_entered)
	EndEffector.body_exited.connect(_on_body_exited)
	# Connect left buttons
	button_left.button_down.connect(_on_button_button_down_left)
	button_left.button_up.connect(_on_button_button_up_left)
	
	# Connect right buttons
	button_right.button_down.connect(_on_button_2_button_right)
	button_right.button_up.connect(_on_button_2_button_up)
	
	# Connect shoulder up buttons
	button_shoulder_up.button_down.connect(_on_button_button_shoulder_up)
	button_shoulder_up.button_up.connect(_on_button_button_up_shoulder_up)
	release.pressed.connect(_release_cube)
	
	# Connect shoulder down buttons
	button_shoulder_down.button_down.connect(_on_button_2_button_down_shoulder_down)
	button_shoulder_down.button_up.connect(_on_button_2_button_up_shoulder_down)
	
	# Connect elbow up buttons
	button_elbow_up.button_down.connect(_on_button_button_down)  # elbow up
	button_elbow_up.button_up.connect(_on_button_button_up_elbow_up)
	
	# Connect elbow down buttons
	button_elbow_down.button_down.connect(_on_button_2_button_down_elbow_down)
	button_elbow_down.button_up.connect(_on_button_2_button_up_elbow_down)
	
	vector_controls.pressed.connect(_on_button_pressed)
	ui_controls.pressed.connect(_on_ui_button_pressed)

	
func configure_physics():
	configure_rigid_body(Shoulder, 100.0, 0.8)
	configure_rigid_body(Arm1, 2.0, 0.6)
	configure_rigid_body(Arm2, 1.0, 0.4)

func configure_rigid_body(body: RigidBody3D, mass: float, friction: float):
	body.mass = mass
	body.gravity_scale = 0.001
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.friction = friction
	body.can_sleep = false
	body.continuous_cd = true
	body.custom_integrator = false
	body.angular_damp = DAMPING
	body.linear_damp = DAMPING * 0.5

func setup_joints():
	setup_hinge(BaseJoint, -180, 180, 2.0)
	setup_hinge(ShoulderJoint, -90, 90, 1.5)
	setup_hinge(ElbowJoint, -120, 120, 1.0)

func setup_hinge(hinge: HingeJoint3D, lower_limit: float, upper_limit: float, max_force: float):
	hinge.set("angular_limit/enable", true)
	hinge.set("angular_limit/lower", deg_to_rad(lower_limit))
	hinge.set("angular_limit/upper", deg_to_rad(upper_limit))
	hinge.set("motor/enable", true)
	hinge.set("motor/target_velocity", 0.0)
	hinge.set("motor/max_impulse", max_force)

var attached_body: RigidBody3D = null
var target_node: Node3D

func _physics_process(delta: float):
	if is_ik_enabled:
		process_ik(delta)
	else:
		process_manual_control(delta)
	
	apply_motor_velocities(delta)
	debug_output()

	if attached_body and target_node:
		var target_pos = target_node.global_position
		# You can add smooth interpolation
		attached_body.global_position = attached_body.global_position.lerp(
			target_pos, 
			delta * 5.0 # Adjust this multiplier to change speed
		)
		
var button_left_pressed := false
var button_right_pressed := false
var button_shoulder_up_pressed := false
var button_shoulder_down_pressed := false
var button_elbow_up_pressed := false
var button_elbow_down_pressed := false

func process_manual_control(delta: float):
	var target_velocities = {
		"base": (float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q)) + float(button_right_pressed) - float(button_left_pressed)) * MAX_MOTOR_VELOCITY,
		"shoulder": (float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S)) + float(button_shoulder_up_pressed) - float(button_shoulder_down_pressed)) * MAX_MOTOR_VELOCITY,
		"elbow": (float(Input.is_key_pressed(KEY_A)) - float(Input.is_key_pressed(KEY_D)) + float(button_elbow_up_pressed) - float(button_elbow_down_pressed)) * MAX_MOTOR_VELOCITY
	}
	
	for joint in current_velocities.keys():
		current_velocities[joint] = lerp(
			current_velocities[joint],
			target_velocities[joint],
			MOTOR_ACCELERATION * delta
		)
	
	if Input.is_key_pressed(KEY_TAB):
		var joint_node = get_node("/root/Main/SubViewport/RobotArmRoot/@Generic6DOFJoint3D@3")
		release_obj()
	#print("endeffector position", get_end_effector_position_3d())

func process_ik(delta: float):
	var end_effector = get_end_effector_position_3d()
	var angles = calculate_ik(end_effector, target_position)
	
	# Calculate differences using z-axis rotations
	current_velocities.base = calculate_angle_difference(Shoulder.rotation.z, angles.base)
	current_velocities.shoulder = calculate_angle_difference(Arm1.rotation.z, angles.shoulder)
	# to do
	current_velocities.elbow = calculate_angle_difference(Arm2.rotation.z, angles.elbow, "elbow")

func calculate_ik(current_pos: Vector3, target_pos: Vector3) -> Dictionary:
	# Get arm lengths
	var l1 = 1.5  # shoulder to elbow length
	var l2 = 1.5  # elbow to end effector length
	
	# Calculate base angle (rotation around Y axis in Godot)
	var base_angle = atan2(target_pos.z, target_pos.x)
	base_angle = clamp(base_angle, deg_to_rad(-180), deg_to_rad(180))
	
	# Calculate the distance in the XZ plane from base to target
	var r_xy = sqrt(target_pos.x**2 + target_pos.z**2)
	
	# Calculate the distance from shoulder joint to target
	var relative_y = target_pos.y  # In Godot, Y is up
	var r = sqrt(r_xy**2 + relative_y**2)
	
	# Use law of cosines to find elbow angle
	var cos_elbow = (r_xy**2 - 2 * (l1**2)) / (2 * l1**2)
	cos_elbow = clamp(cos_elbow, -1.0, 1.0)
	# In calculate_ik function:
	var elbow_angle = acos(cos_elbow)

	# Normalize the elbow angle to [-PI, PI]
	elbow_angle = clamp(elbow_angle, deg_to_rad(-120), deg_to_rad(120))
	
	# Calculate shoulder angle
	var alpha = atan2(-relative_y, r_xy)  # Angle to target from horizontal
	var beta = acos((l2**2 + r**2 - l2**2) / (2 * l2 * r))
	# Invert the shoulder angle and adjust the direction
	var shoulder_angle = (alpha + beta)  # Added negative sign here
	#if shoulder_angle > 0:
		#shoulder_angle = -shoulder_angle
	shoulder_angle = clamp(shoulder_angle, deg_to_rad(-90), deg_to_rad(90))
	
	return {
		"base": base_angle,
		"shoulder": shoulder_angle,
		"elbow": elbow_angle
	}

func calculate_angle_difference(current: float, target: float, part = null) -> float:
#
	# Special handling for elbow joint to prevent oscillation
	if part == "elbow":
		# Convert to degrees and use absolute current angle for consistent comparison
		#var current_deg = rad_to_deg(abs(current))
		var current_deg = rad_to_deg(abs(current))
		var target_deg = rad_to_deg(target)
		var angle_diff = target_deg - current_deg
		
		if debug == true:
			print("Elbow - Current angle: ", current_deg)
			print("Elbow - Target angle: ", target_deg)
			print("Elbow - Difference: ", angle_diff)
		
		# If there's a significant difference, move at a constant small velocity
		# but in the correct direction based on whether we need to increase or decrease
		if abs(angle_diff) > 0.1:
			return 0.5 * sign(angle_diff)  # Will return -0.1 if we need to decrease
		return 0.0
	
		
	var diff = target - current
	if diff > PI:
		diff -= 2 * PI
	elif diff < -PI:
		diff += 2 * PI
	return diff * MAX_MOTOR_VELOCITY

func apply_motor_velocities(delta: float):
	BaseJoint.set("motor/target_velocity", current_velocities.base)
	ShoulderJoint.set("motor/target_velocity", current_velocities.shoulder)
	ElbowJoint.set("motor/target_velocity", current_velocities.elbow)

func get_end_effector_position_3d() -> Vector3:
	var pos = EndEffector.global_transform.origin
	return Vector3(pos.x, pos.y, pos.z)

func set_target_position(position: Vector3):
	target_position = position
	is_ik_enabled = true
	
func debug_output():
	if Input.is_key_pressed(KEY_SPACE):
		print("Joint Angles (degrees):")
		print("Base: ", rad_to_deg(Shoulder.rotation.z))
		print("Shoulder: ", rad_to_deg(Arm1.rotation.z))
		print("Elbow: ", rad_to_deg(Arm2.rotation.z))
		print("Current Velocities:", current_velocities)
		
func _test_cord_update(data):
	is_ik_enabled = true
	var x = float(data[0])
	var y = float(data[1])
	var z = float(data[2])
	target_position = Vector3(x,y,z)

var current_joint: Generic6DOFJoint3D = null

func _on_body_entered(body):
	# First, verify we have a valid object to connect to
	if not body or not body is RigidBody3D:
		return
		
	if body:
		attached_body = body
		target_node = get_node("Base/BaseJoint/Shoulder/ShoulderJoint/Arm1/ElbowJoint/Arm2/EF")
		
	var EndEffectorJoint = Generic6DOFJoint3D.new()
	add_child(EndEffectorJoint)
	current_joint = EndEffectorJoint
	
	print(EndEffectorJoint.get_path())
	
	# Get the path to your arm node properly
	var arm_node = get_node("Base/BaseJoint/Shoulder/ShoulderJoint/Arm1/ElbowJoint/Arm2")
	if not arm_node:
		print("Couldn't find arm node!")
		return
		
	# Set the nodes using get_path()
	EndEffectorJoint.node_a = arm_node.get_path()
	EndEffectorJoint.node_b = body.get_path()  # Use the entering body directly
	
	# Lock all axes
	EndEffectorJoint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	EndEffectorJoint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	EndEffectorJoint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	
	EndEffectorJoint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	EndEffectorJoint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	EndEffectorJoint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	
	# Set limits
	EndEffectorJoint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	EndEffectorJoint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	EndEffectorJoint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	EndEffectorJoint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	EndEffectorJoint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	EndEffectorJoint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	
	# You might also want to add angular limits
	EndEffectorJoint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	EndEffectorJoint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	EndEffectorJoint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	EndEffectorJoint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	EndEffectorJoint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	EndEffectorJoint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	
	# Emit signal if needed
	_on_body_entered_signal.emit("body_entered")
	
func _on_body_exited(body):
	_on_body_entered_signal.emit("")
	
func release_obj():
	if current_joint:
		current_joint.queue_free()  # Properly remove the joint
		current_joint = null
	
	if attached_body:
		# Optional: Add any physics properties for dropping
		attached_body.linear_damp = 5.0
		attached_body.angular_damp = 5.0
		attached_body = null

var is_button_held
# Add these variables at the top of your script
func _on_button_button_down_left():
	button_left_pressed = true
	while button_left_pressed:
		print("pressing left")
		await get_tree().create_timer(0.1).timeout
		
func _on_button_button_up_left():
	button_left_pressed = false

func _on_button_2_button_right():
	button_right_pressed = true
	while button_right_pressed:
		print("pressing right")
		await get_tree().create_timer(0.1).timeout
	   
func _on_button_2_button_up():
	button_right_pressed = false

func _on_button_button_shoulder_up():
	button_shoulder_up_pressed = true
	while button_shoulder_up_pressed:
		print("pressing shoulder up")
		await get_tree().create_timer(0.1).timeout
	   
func _on_button_button_up_shoulder_up():
	button_shoulder_up_pressed = false

func _on_button_2_button_down_shoulder_down():
	button_shoulder_down_pressed = true
	while button_shoulder_down_pressed:
		print("pressing shoulder down")
		await get_tree().create_timer(0.1).timeout
	   
func _on_button_2_button_up_shoulder_down():
	button_shoulder_down_pressed = false

func _on_button_button_down():  # elbow up
	button_elbow_up_pressed = true
	while button_elbow_up_pressed:
		print("pressing elbow up")
		await get_tree().create_timer(0.1).timeout
	   
func _on_button_button_up_elbow_up():
	button_elbow_up_pressed = false

func _on_button_2_button_down_elbow_down():
	button_elbow_down_pressed = true
	while button_elbow_down_pressed:
		print("pressing elbow down")
		await get_tree().create_timer(0.1).timeout
	   
func _on_button_2_button_up_elbow_down():
	button_elbow_down_pressed = false
	
func _on_button_pressed():
	is_ik_enabled = true

func _on_ui_button_pressed():
	is_ik_enabled = false

func _release_cube():
	release_obj()
