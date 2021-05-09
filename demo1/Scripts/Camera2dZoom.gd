extends Camera2D


func _ready():
	pass

func _input(event):
	if event is InputEventMouse:
		# enum ButtonList:
		# BUTTON_WHEEL_UP = 4
		# BUTTON_WHEEL_DOWN = 5
		
		# if mouse scroll up: zoom in
		# if mouse scroll down: zoom out
		if event.button_mask == 16:
			zoom += Vector2(0.1, 0.1)
		if event.button_mask == 8:
			zoom -= Vector2(0.1, 0.1)
