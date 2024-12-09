extends RigidBody3D

@onready var robotScene = get_node("../RobotArmRoot")
# Called when the node enters the scene tree for the first time.
var material = StandardMaterial3D.new()
var has_released = false
func _ready():
	robotScene._on_body_entered_signal.connect(_on_carry_obj_enered)
		# Create new material
	material.albedo_color = Color(1, 0, 0)  # Red color (R,G,B)
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 0
	physics_material_override = physics_material
	# Assign to mesh
	$MeshInstance3D.material_override = material

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var linear_speed = linear_velocity.length()
	if (linear_velocity.length() < 0.1):
		set_collision_layer_value(14, true)
		set_collision_mask_value(14, true)
	pass

func picked_up():
	# Disable physics while being held
	freeze = true

func dropped():
	# Re-enable physics
	freeze = false
	
func _on_carry_obj_enered(data):
	if data == "body_entered":
		material.albedo_color = Color(0, 1, 0)
		set_collision_layer_value(14, false)
		set_collision_mask_value(14, false)
	else:
		material.albedo_color = Color(1, 0, 0) 
		$MeshInstance3D.material_override = material

func _on_button_pressed():
	get_node("../RobotArmRoot")._on_body_entered_signal.connect(_on_carry_obj_enered)
