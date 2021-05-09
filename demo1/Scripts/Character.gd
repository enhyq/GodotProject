extends RigidBody2D

enum State {GROUND, AIR}
var _state = State.AIR

func _ready():
	pass

func _input(event):
	if _state == State.GROUND:
		if event is InputEventMouseButton:
			# BUTTON_LEFT = 1
			# BUTTON_RIGHT = 2
			# BUTTON_MIDDLE = 3
			if event.button_index == 1:
				apply_central_impulse((Vector2(-35,-50)).rotated(rotation))
				_state = State.AIR
			if event.button_index == 2:
				apply_central_impulse((Vector2(35,-50)).rotated(rotation))
				_state = State.AIR

func _physics_process(delta):	
	# this character will always face GLOBAL ORIGIN -> (0,0)
	var my_pos = get_global_position().normalized()
	var x = my_pos.x
	var y = my_pos.y
	if x == 0: 
		if y > 0:
			rotation = deg2rad(180)
		else:
			pass
	else:
		rotation = atan(y/x) + deg2rad(90) * sign(x)
		
	if $RayCast2D.is_colliding():
		_state = State.GROUND
	
