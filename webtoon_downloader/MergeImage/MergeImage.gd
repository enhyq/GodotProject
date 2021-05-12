extends Node2D

var img_src_dir = "res://MergeImage/sample_image/"

func _ready():
	pass
	var img = Image.new()
	print(img.get_height())
	
	
#	var a = load_image_file(img_src_dir+"sample.png")
#	var b = load_image_file(img_src_dir+"sample.png")
#
#	var img = Image.new()
#	img = merge_image_vertical(a,b)
#	img.save_png("res://MergeImage/sample_image/test")


func load_image_file(file_path:String) -> Image:
	var image = Image.new()
	# load method may not work in exported projects.
	image.load(file_path)
	return image


func merge_image_vertical(top, bottom) -> Image:
	var merged_image = Image.new()
	var top_height = top.get_height()
	var top_width = top.get_width()
	var bottom_height = bottom.get_height()
	var bottom_width = bottom.get_width()
	
	if top.get_format() != bottom.get_format():
		if not top.is_empty():
			print_debug("Format error: format does not match while trying to merge...")
			return merged_image
		# if "top" image is just an empty image, convert "top" image format to "bottom" image format
		else:
			top.convert(bottom.get_format())
		
	var greater_width = top_width if top_width >= bottom_width else bottom_width
	var total_height = top_height + bottom_height
	print(total_height)
	merged_image.create(greater_width, total_height, false, bottom.get_format())
	merged_image.blit_rect(top, Rect2(Vector2(0,0), top.get_size()), Vector2(0,0))
	merged_image.blit_rect(bottom, Rect2(Vector2(0,0), bottom.get_size()), Vector2(0, top.get_height()))
	
	return merged_image
