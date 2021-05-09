extends Node2D

var img_data:Array = []
var img_save_path:String
var base_url = "https://comic.naver.com/webtoon/detail.nhn?titleId=%d&no=%d"

func _ready():
	pass


func add_text(RTlabel:RichTextLabel, string:String, newline:bool = true):
	if newline:
		RTlabel.text += "\n" + string
	else:
		RTlabel.text += string


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


func get_requeste_url() -> String:
	var titleid = $Node/TitleIdInput.text.to_int()
	var episode_from = $Node/EpisodeFrom.value
	var episode_to= $Node/EpisodeTo.value
	var request_url = base_url % [titleid, episode_to]
	return request_url

func get_naver_comic():
	$HTTPRequest.request(get_requeste_url())


func parse_img_data_from_html(html_data_buffer:PoolByteArray) -> Array:
	var img_scr_list = []
	var xml = XMLParser.new()
	var error = xml.open_buffer(html_data_buffer)
	if error != OK:
		printerr("Error has accured while trying to OPEN xml buffer...  error code:", error)
		return []
		
	error = xml.read()
	if error != OK:
		printerr("Error has accured while trying to READ xml buffer...  error code:", error)
		return []
	
	var temp_path = "C:/Users/admin/Documents/GitHub/test.txt" #for windows computer
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
			if error == ERR_FILE_EOF:
				break
			printerr("Error has accured while trying to READ xml buffer...  error code:", error)
			return []
	return img_scr_list


func download_img_to_local(urls:Array, dir:String):
	var i = 0
	var header = ["User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36",
				 "Referer: " + get_requeste_url() 
				]
	$HTTPRequestImg.request(urls[0], header)
	
#	for img_url in urls:
#		$HTTPRequestImg.request(img_url, header)
#		img_save_path = dir + str(i) + ".png"
#		print("worked!", i)
#		i += 1


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	add_text($Node/OuputLabel, "result: " + str(result))
	add_text($Node/OuputLabel, "response code: " + str(response_code))
	add_text($Node/OuputLabel, "headers: ")
	for i in headers:
		add_text($Node/OuputLabel, i)
	
	img_data.clear()
	img_data = parse_img_data_from_html(body)
	if img_data != []:
		$FileDialog.popup_centered()
	

func _on_DownloadButton_pressed():
	var titleid = $Node/TitleIdInput.text.to_int()
	var episode_from = $Node/EpisodeFrom.value
	var episode_to= $Node/EpisodeTo.value
	if episode_from == episode_to:
		get_naver_comic()
	else:
		var message = "downloading multiple episode function is not ready yet!"
		add_text($Node/OuputLabel, message)


func _on_EpisodeFrom_value_changed(value):
	if $Node/EpisodeFrom.value > $Node/EpisodeTo.value:
		$Node/EpisodeTo.value = value
	$Node/EpisodeTo.min_value = value


func _on_FileDialog_confirmed():
	img_save_path = $FileDialog.current_dir + "test.jpeg"
	download_img_to_local(img_data, $FileDialog.current_dir)


func _on_HTTPRequestImg_request_completed(result, response_code, headers, body):
	add_text($Node/OuputLabel, "result: " + str(result))
	add_text($Node/OuputLabel, "response code: " + str(response_code))
	add_text($Node/OuputLabel, "headers: ")
	for i in headers:
		add_text($Node/OuputLabel, i)
	
	if result == HTTPRequest.RESULT_SUCCESS: 
		if response_code != 403:
			var image = Image.new()
			var error = image.load_jpg_from_buffer(body)
			if error != OK:
				printerr("Couldn't load the image.")
			
			add_text($Node/OuputLabel, "Saving image to  " + img_save_path)
			image.save_png(img_save_path)
		else:
			printerr("response_code:", response_code)
	else:
		printerr("Unexpected result from HTTPRequest...  result code:", result)
	
