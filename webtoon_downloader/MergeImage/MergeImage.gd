extends Node2D

var img_src_dir = "res://ConcatenateImage/sample_image/"
var img_poolByteArray:PoolByteArray = PoolByteArray([])

func _ready():
	var a = load_image(img_src_dir+"sample.png")
	var b = load_image(img_src_dir+"sample.png")
	
	var img = Image.new()
	img.create(640, 1280, false, a.get_format())
	img.blit_rect(a, Rect2(Vector2(0,0), Vector2(640,640)), Vector2(0,0))
	img.blit_rect(b, Rect2(Vector2(0,0), Vector2(640,640)), Vector2(0,640))
	img.save_png("res://ConcatenateImage/test")

func load_image(file_path:String) -> Image:
	var image = Image.new()
	# load method may not work in exported projects.
	image.load(file_path)
	return image
