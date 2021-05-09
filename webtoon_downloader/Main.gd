extends Node2D


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
        printerr("Error has accured while trying to read file...  error code", error)
        return error
    file.seek_end()
    file.store_line(string)
    file.close()


func get_naver_comic(titleId:int, episode:int):
    var base_url = "https://comic.naver.com/webtoon/detail.nhn?titleId=%d&no=%d"
    var request_url = base_url % [titleId, episode]
    $HTTPRequest.request(request_url)


func parse_img_data_from_html(html_data_buffer:PoolByteArray):
    var xml = XMLParser.new()
    var error = xml.open_buffer(html_data_buffer)
    if error != OK:
        printerr("Error has accured while trying to OPEN xml buffer...  error code:", error)
        return error
        
    error = xml.read()
    if error != OK:
        printerr("Error has accured while trying to READ xml buffer...  error code:", error)
        return error
    
    while !error:
        match xml.get_node_type():
            XMLParser.NODE_NONE:
                pass
            XMLParser.NODE_TEXT:
                pass
#                append_to_text_file("user://test.txt", xml.get_node_data())
            XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END:
#                append_to_text_file("user://test.txt", xml.get_node_name())
                if xml.get_node_name() == "img":
                    var string = ""
                    for i in range(xml.get_attribute_count()):
                        string += xml.get_attribute_name(i) + " --> " + xml.get_attribute_value(i) + "\n"
                    string += "\n\n"
                    append_to_text_file("user://test.txt", string)
                
            _:
#                print("type: ", xml.get_node_type())
                pass
        error = xml.read()
        if error != OK:
            printerr("Error has accured while trying to READ xml buffer...  error code:", error)
            return error


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
    add_text($Node/OuputLabel, "result: " + str(result))
    add_text($Node/OuputLabel, "response code: " + str(response_code))
    add_text($Node/OuputLabel, "headers: ")
    for i in headers:
        add_text($Node/OuputLabel, i)
    
    parse_img_data_from_html(body)
    

func _on_DownloadButton_pressed():
    var titleid = $Node/TitleIdInput.text.to_int()
    var episode_from = $Node/EpisodeFrom.value
    var episode_to= $Node/EpisodeTo.value
    if episode_from == episode_to:
        get_naver_comic(titleid, episode_to)
    else:
        var message = "downloading multiple episode function is not ready yet!"
        add_text($Node/OuputLabel, message)


func _on_EpisodeFrom_value_changed(value):
    if $Node/EpisodeFrom.value > $Node/EpisodeTo.value:
        $Node/EpisodeTo.value = value
    $Node/EpisodeTo.min_value = value
