extends StaticBody3D

var material = StandardMaterial3D.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	$Area3D.body_entered.connect(_on_goal_entered)
	material.albedo_color = Color(0, 0, 1)  # Red color (R,G,B)
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 0
	physics_material_override = physics_material
	# Assign to mesh
	$MeshInstance3D.material_override = material


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_goal_entered(body):
	print("on goal")
	$"../../Panel/LevelCompleted".visible = true
	

