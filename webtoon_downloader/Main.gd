extends Node2D


# global variables to store shared data
var img_urls:Array = []
var img_save_path:String
var request_header
var current_episode:int # for storing currently downloading episode number

# node shortcuts
var _output_display
var _titleid_input
var _episode_from_input
var _episode_to_input


func _ready():
	_output_display = $Node/OuputDisplay
	_titleid_input = $Node/TitleIdInput
	_episode_from_input = $Node/EpisodeFromInput
	_episode_to_input = $Node/EpisodeToInput


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
	var file = File.new()
	var error = file.open(file_path, file.READ_WRITE)
	if error != OK:
		if error == ERR_FILE_NOT_FOUND:
			file.close()
			file.open(file_path, file.WRITE)
			file.close()
		else:
			printerr("Error has accured while trying to read file...  error code", error)
			return error
	file.seek_end()
	file.store_line(string)
	file.close()


# creates a valid url address to specific title and episode of naver comic
func create_naver_comic_url(titleId, episode) -> String:
	return "https://comic.naver.com/webtoon/detail.nhn?titleId=%d&no=%d" % [titleId, episode]


# ***** 1 *****
func _on_DownloadButton_pressed():
	# download single episode page
	if get_episode_from_val() == get_episode_to_val():
		$HTTPRequest.connect("request_completed", self, "_on_getWebtoonPage_request_completed")
		$HTTPRequest.request(create_naver_comic_url(get_titleid_val(), get_episode_to_val()))
	else:
		print_on_output_display("downloading multiple episode function is not ready yet!")


# ***** 2 *****
func _on_getWebtoonPage_request_completed(result, response_code, headers, body):
	print_HTTPRequest_RRH_on_output_display(result, response_code, headers)
	img_urls.clear()
	img_urls = parse_img_data_from_html(body)
	
	# debug
	for i in img_urls:
		append_to_text_file("/tmp/guest-6fr2gu/Desktop/test.txt", i)
	
	if img_urls != []:
		$FileDialog.popup_centered()
	else:
		print_on_output_display("No Imgage url was Found...")


# ***** 2.5 ***** (used in step 2)
# extracts img urls from webtoon page
func parse_img_data_from_html(html_data_buffer:PoolByteArray) -> Array:
	var img_scr_list = []
	var xml = XMLParser.new()
	var error = xml.open_buffer(html_data_buffer)
	if error != OK:
		printerr("Error has accured while trying to OPEN xml buffer...  error code:", error)
		return []
		
	error = xml.read()	# begin reading the first line of xml
	if error != OK:
		printerr("Error has accured while trying to READ xml buffer...  error code:", error)
		return []
	
#	var temp_path = "C:/Users/admin/Documents/GitHub/test.txt" # for windows computer debug
	var temp_path = "/tmp/guest-6fr2gu/Desktop/test.txt" # for linux computer debug
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
			_:
				pass
		error = xml.read()
		if error != OK:
			# when reached EOF, break loop
			if error == ERR_FILE_EOF:
				break
			else:
				printerr("Error has accured while trying to READ xml buffer...  error code:", error)
				return []

	return img_scr_list


# ***** 3 *****
func _on_FileDialog_confirmed():
	img_save_path = $FileDialog.current_dir
	download_img_to_local()


# ***** 4 *****
func download_img_to_local():
	request_header = ["User-Agent: Mozilla/5.1 (Windows NT 10.1; Win64; x64) AppleWebKit/536.37 (KHTML, like Gecko) Chrome/91.1.4480.73 Safari/535.36",
				 "Referer: " + create_naver_comic_url(get_titleid_val(), get_episode_to_val()) 
				]
	if $HTTPRequest.is_connected("request_completed", self, "_on_getWebtoonPage_request_completed"):
		$HTTPRequest.disconnect("request_completed", self, "_on_getWebtoonPage_request_completed")
	if not $HTTPRequest.is_connected("request_completed", self, "_on_downloadMultipleImgs_request_completed"): 
		$HTTPRequest.connect("request_completed", self, "_on_downloadMultipleImgs_request_completed")
	$HTTPRequest.request(img_urls.pop_back(), request_header)
	print(img_urls.size())


# ***** 5 *****
# this fuction is requires global variable "img_urls"
func _on_downloadMultipleImgs_request_completed(result, response_code, headers, body):
	print_HTTPRequest_RRH_on_output_display(result, response_code, headers)
	if result == HTTPRequest.RESULT_SUCCESS: 
		if response_code != 403:
			var image = Image.new()
			var error = image.load_jpg_from_buffer(body)
			if error != OK:
				printerr("Couldn't load the image.")
			
			print_on_output_display("Saving image to  " + img_save_path + "/" + str(img_urls.size()))
			image.save_png(img_save_path + "/" + str(len(img_urls)) + ".png")
		else:
			printerr("response_code:", response_code)
	else:
		printerr("Unexpected result from HTTPRequest...  result code:", result)
	
	print(img_urls.size())
	if img_urls.size() > 0:
		download_img_to_local()


# prints http request result, response, and headers to output display -- for debugging
func print_HTTPRequest_RRH_on_output_display(result, response_code, headers):
	print_on_output_display("result: " + str(result))
	print_on_output_display("response code: " + str(response_code))
	print_on_output_display("headers: ")
	for i in headers:
		print_on_output_display(i)
	print_on_output_display("##################\n\n")


func _on_EpisodeFrom_value_changed(value):
	if value > get_episode_to_val():
		_episode_to_input.value = value
	_episode_to_input.min_value = value
