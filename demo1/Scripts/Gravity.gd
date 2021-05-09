extends Area2D

var planet_rad
var gravity_rad
export var planet_col : Color = Color("b292e6ff")

func _ready():
	planet_rad = $Planet/CollisionShape2D.shape.radius
	$CollisionShape2D.shape.radius = planet_rad + 1000
	gravity_rad = $CollisionShape2D.shape.radius

func _draw():
	draw_circle(Vector2(0,0), planet_rad, planet_col)
	for i in range(0,340,20):
		draw_arc(Vector2(0,0), gravity_rad, i, i+10, 20, planet_col)
