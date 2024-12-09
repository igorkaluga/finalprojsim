extends SubViewport

@onready var CarryObject: RigidBody3D = $CarryObject
# Called when the node enters the scene tree for the first time.
func _ready():
	CarryObject.body_entered.connect(_on_body_entered)
	
func _process(delta):
	pass
	
func _on_body_entered():
	print("somethings in ma body")

