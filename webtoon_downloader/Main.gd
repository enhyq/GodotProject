extends Node2D


# global variables to store shared data
var IMG_URLS:Array = []
var IMG_SAVE_PATH := ""
var CURRENT_EPISODE_NUM:int # for storing currently downloading episode number
var CURRENT_EPISODE_NAME # current episode name
var MERGED_IMAGE = Image.new() # not used anymore, cannot merge large images with godot api
var END_EPISODE_NUM

# node shortcuts
var _output_display
var _titleid_input
var _episode_from_input
var _episode_to_input


func _ready():
	_output_display = $UINode/OuputDisplay
	_titleid_input = $UINode/TitleIdInput
	_episode_from_input = $UINode/EpisodeFromInput
	_episode_to_input = $UINode/EpisodeToInput


func get_titleid_val():
	return _titleid_input.text.to_int()
func get_episode_from_val():
	return _episode_from_input.value
func get_episode_to_val():
	return _episode_to_input.value


# adds string to OuputDisplay node
func print_on_output_display(string:String, newline:bool = true):
	if newline:
		_output_display.text += "\n" + string
	else:
		_output_display.text += string


# function for saving data on OS file -- for debugging
func append_to_text_file(file_path:String, string:String):
	var dir = Directory.new()
	if dir.file_exists(file_path):
		pass
	else:
		dir.make_dir_recursive(file_path)
		dir.remove(file_path)
	
	var file = File.new()
	var error = file.open(file_path, file.READ_WRITE)
	if error != OK:
		if error == ERR_FILE_NOT_FOUND:
			file.open(file_path, file.WRITE)
		else:
			print_debug("Error has accured while trying to read file...  error code", error)
			return error
	file.seek_end()
	file.store_line(string)
	file.close()


# creates a valid url address to specific title and episode of naver comic
func create_naver_comic_url(titleId, episode) -> String:
	return "https://comic.naver.com/webtoon/detail.nhn?titleId=%d&no=%d" % [titleId, episode]


# ***** 1 *****
func _on_DownloadButton_pressed():
	CURRENT_EPISODE_NUM = get_episode_from_val()
	END_EPISODE_NUM = get_episode_to_val()
	
	# download a single episode
	if get_episode_from_val() == get_episode_to_val():
		# controls signal conenction (maybe take it out as a separate function later...)
		if $HTTPRequest.is_connected("request_completed", self, "_on_downloadMultipleImgs_request_completed"): 
			$HTTPRequest.disconnect("request_completed", self, "_on_downloadMultipleImgs_request_completed")
		if not $HTTPRequest.is_connected("request_completed", self, "_on_getWebtoonPage_request_completed"):
			$HTTPRequest.connect("request_completed", self, "_on_getWebtoonPage_request_completed")

		$HTTPRequest.request(create_naver_comic_url(get_titleid_val(), CURRENT_EPISODE_NUM))
	
	# download multiple episodes
	else:
#		print_on_output_display("downloading multiple episode function is not ready yet!")
		print_on_output_display("BEGINNING MULTIPLE DOWNLOADS")
		# controls signal conenction (maybe take it out as a separate function later...)
		if $HTTPRequest.is_connected("request_completed", self, "_on_downloadMultipleImgs_request_completed"): 
			$HTTPRequest.disconnect("request_completed", self, "_on_downloadMultipleImgs_request_completed")
		if not $HTTPRequest.is_connected("request_completed", self, "_on_getWebtoonPage_request_completed"):
			$HTTPRequest.connect("request_completed", self, "_on_getWebtoonPage_request_completed")

		$HTTPRequest.request(create_naver_comic_url(get_titleid_val(), CURRENT_EPISODE_NUM))

# ***** 2 *****
func _on_getWebtoonPage_request_completed(_result, _response_code, _headers, body):
#	print_HTTPRequest_RRH_on_output_display(result, response_code, headers)
	IMG_URLS.clear()
	IMG_URLS = parse_img_data_from_html(body)
	
	# debug in linux pc only!!!!
#	for i in IMG_URLS:
#		append_to_text_file("/tmp/guest-ibezl0/Desktop/doesthiswork/test.txt", i)
	
	if IMG_URLS != []:
		# downlaoding single episode
		if IMG_SAVE_PATH == "":
			$FileDialog.popup_centered()
		elif IMG_SAVE_PATH != "":
			IMG_SAVE_PATH = $FileDialog.current_dir
			IMG_SAVE_PATH += "/" + episode_number_to_string(CURRENT_EPISODE_NUM) + "_" + CURRENT_EPISODE_NAME
			request_for_image()
	else:
		print_on_output_display("No Imgage url was Found...")


# ***** 2.1 ***** (used in step 2)
# need 2.2 function to parse episode title from webtoon page
# extracts img urls from webtoon page
func parse_img_data_from_html(html_data_buffer:PoolByteArray) -> Array:
	var img_scr_list = []
	var xml = XMLParser.new()
	var error = xml.open_buffer(html_data_buffer)
	if error != OK:
		print_debug("Error has accured while trying to OPEN xml buffer...  error code:", error)
		return []
		
	error = xml.read()	# begin reading the first line of xml
	if error != OK:
		print_debug("Error has accured while trying to READ xml buffer...  error code:", error)
		return []
	
#	var temp_path = "C:/Users/admin/Documents/GitHub/test.txt" # for windows computer debug
#	var temp_path = "/tmp/guest-6fr2gu/Desktop/test.txt" # for linux computer debug
#	var path= "user://test.txt"
	
	while !error:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END:
				if xml.get_node_name() == "img":
					var value = xml.get_named_attribute_value_safe("alt")
					if value == "comic content":
						img_scr_list.push_back(xml.get_named_attribute_value_safe("src"))
					
#					var string = ""
#					for i in range(xml.get_attribute_count()):
#						string += xml.get_attribute_name(i) + " --> " + xml.get_attribute_value(i) + "\n"
#					string += "\n\n"
#					append_to_text_file(temp_path, string)
				if xml.get_node_name() == "meta":
					var value = xml.get_named_attribute_value_safe("property")
					if value == "og:description":
#						print_debug(xml.get_named_attribute_value_safe("content"))
						CURRENT_EPISODE_NAME = xml.get_named_attribute_value_safe("content")
			_:
				pass
		error = xml.read()
		if error != OK:
			# when reached EOF, break loop
			if error == ERR_FILE_EOF:
				break
			else:
				print_debug("Error has accured while trying to READ xml buffer...  error code:", error)
				return []

	return img_scr_list


# ***** 3 *****
# sets IMG_FILE_PATH value
func _on_FileDialog_confirmed():
	IMG_SAVE_PATH = $FileDialog.current_dir
	IMG_SAVE_PATH += "/" + episode_number_to_string(CURRENT_EPISODE_NUM) + "_" + CURRENT_EPISODE_NAME
	request_for_image()


# ***** 4 *****
func request_for_image():
	var request_header = ["User-Agent: Mozilla/5.1 (Windows NT 10.1; Win64; x64) AppleWebKit/536.37 (KHTML, like Gecko) Chrome/91.1.4480.73 Safari/535.36",
				 "Referer: " + create_naver_comic_url(get_titleid_val(), CURRENT_EPISODE_NUM) 
				]
	
	# controls signal conenction (maybe take it out as a separate function later...)
	if $HTTPRequest.is_connected("request_completed", self, "_on_getWebtoonPage_request_completed"):
		$HTTPRequest.disconnect("request_completed", self, "_on_getWebtoonPage_request_completed")
	if not $HTTPRequest.is_connected("request_completed", self, "_on_downloadMultipleImgs_request_completed"): 
		$HTTPRequest.connect("request_completed", self, "_on_downloadMultipleImgs_request_completed")
	$HTTPRequest.request(IMG_URLS.pop_back(), request_header)


# ***** 5 *****
# this fuction is requires global variable "IMG_URLS"
func _on_downloadMultipleImgs_request_completed(result, response_code, _headers, body):
#	print_HTTPRequest_RRH_on_output_display(result, response_code, headers)
	if result == HTTPRequest.RESULT_SUCCESS: 
		if response_code != 403:
			var image = Image.new()
			var error = image.load_jpg_from_buffer(body)
			if error != OK:
				print_debug("Couldn't load the image.")
			
			# 1 merge images together vertically
			# this cannot be done with godot api because it only supports images size of 16384×16384 pixels
#			print_on_output_display("Downloading merging image: " + str(IMG_URLS.size()))
#			MERGED_IMAGE = $MergeImage.merge_image_vertical(MERGED_IMAGE, image)
			
			# 2 save images individually
			print_on_output_display("Saving image to  " + IMG_SAVE_PATH + "/" + str(IMG_URLS.size()+1))
#			image.save_png(IMG_SAVE_PATH + "/" + str(len(IMG_URLS)))

			# 3 use file api instead of imgaes for jpg saving
			var dir = Directory.new()
			if dir.file_exists(IMG_SAVE_PATH):
				pass
			else:
				dir.make_dir_recursive(IMG_SAVE_PATH)
			var file = File.new()
			file.open(IMG_SAVE_PATH + "/" + str(len(IMG_URLS)+1), file.WRITE)
			file.store_buffer(body)
			file.close()
		else:
			print_debug("response_code:", response_code)
	else:
		print_debug("Unexpected result from HTTPRequest...  result code:", result)
	
	if IMG_URLS.size() > 0:
		# if urls are left, keep downloading and merging
		request_for_image()
	else:
		# when all the img urls are downloaded
		print_on_output_display("Download Complete")
		if CURRENT_EPISODE_NUM == END_EPISODE_NUM:
			IMG_SAVE_PATH = ""
			print_on_output_display("ALL DOWNLOADS COMPLETED")
		# when there are episode yet to download
		elif CURRENT_EPISODE_NUM < END_EPISODE_NUM:
			CURRENT_EPISODE_NUM += 1
			
			# controls signal conenction (maybe take it out as a separate function later...)
			if $HTTPRequest.is_connected("request_completed", self, "_on_downloadMultipleImgs_request_completed"): 
				$HTTPRequest.disconnect("request_completed", self, "_on_downloadMultipleImgs_request_completed")
			if not $HTTPRequest.is_connected("request_completed", self, "_on_getWebtoonPage_request_completed"):
				$HTTPRequest.connect("request_completed", self, "_on_getWebtoonPage_request_completed")

			$HTTPRequest.request(create_naver_comic_url(get_titleid_val(), CURRENT_EPISODE_NUM))
		

func save_image_to_local(image:Image):
	print_on_output_display("Saving image to  " + IMG_SAVE_PATH + "/test.png")
	image.save_png(IMG_SAVE_PATH + "/test")

# prints http request result, response, and headers to output display -- for debugging
func print_HTTPRequest_RRH_on_output_display(result, response_code, headers):
	print_on_output_display("result: " + str(result))
	print_on_output_display("response code: " + str(response_code))
	print_on_output_display("headers: ")
	for i in headers:
		print_on_output_display(i)
	print_on_output_display("##################\n\n")


# this prevents episode_to from being lower than episode_from value
func _on_EpisodeFrom_value_changed(value):
	if value > get_episode_to_val():
		_episode_to_input.value = value
	_episode_to_input.min_value = value


func episode_number_to_string(num:int) -> String:
	return "%04d" % num
