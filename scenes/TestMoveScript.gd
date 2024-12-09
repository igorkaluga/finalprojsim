extends Node3D

#@onready var base = $Base
#@onready var arm1 = $Link/CollisionShape3D
func _ready():
	#var this_mesh = self.get_mesh()
	#var global_pos = mesh_inst.global_position;
	#print("position", get_path())
	print("global pos", global_position)
	var input_scene = get_node("../../Control")
	#base.freeze = true
	#input_scene.on_input_execute.connect(_on_input_recieved)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
		
#func _on_input_recieved(data):
#
	## Using degrees (easier to read)
	#base.position.y = float(data)
	#
	#print(base.position.y)
	

