extends Node2D

var img_src_dir = "res://ConcatenateImage/고수_프롤로그/"
var img_poolByteArray:PoolByteArray = PoolByteArray([])

func _ready():
	var a = load_image(img_src_dir+"0.png")
	var b = load_image(img_src_dir+"1.png")
	img_poolByteArray.append_array(a)
	img_poolByteArray.append_array(b)
	
	var img = Image.new()
	img.load_png_from_buffer(img_poolByteArray)
	img.save_png("res://ConcatenateImage/test")

func load_image(file_path:String) -> Image:
	var image = Image.new()
	# load method may not work in exported projects.
	image.load(file_path)
	return image.get_data()
