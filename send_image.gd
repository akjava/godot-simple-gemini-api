extends Control


#see https://ai.google.dev/tutorials/rest_quickstart

var api_key = ""
var http_request

var file_dialog: FileDialog
var is_mp4 = false # mp4 not working so far
var mp4_path
func _ready():
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://settings.json"))
	api_key = settings.api_key
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_request_completed)
	
	file_dialog = FileDialog.new()
	
	
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.png; *.jpg; *.jpeg", "Image files (*.png, *.jpg, *.jpeg)"]
	
	add_child(file_dialog)
	
	
	file_dialog.connect("file_selected", Callable(self,"_on_FileDialog_file_selected"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_FileDialog_file_selected(path: String):
	
	if path.to_lower().ends_with(".mp4"):
		is_mp4 = true
		mp4_path = path
		var textureRect = find_child("TextureRect")
		print("mp4")
		var image = Image.new()
		var error = image.load("res://files/video_file.png")
		textureRect.set_texture(ImageTexture.create_from_image(image))
		return
		
	is_mp4 = false
	
	# image case
	var image = Image.new()
	var error = image.load(path)
	
	if error == OK:
		print("Image loaded successfully: ", path)
		_set_selected_image(image)
	else:
		print("Failed to load image: ", path)

var created_image = null
func _set_selected_image(image,fixed_size = false):
	var size_text = _get_option_selected_text("Size")
	var max_width = int(size_text)
	var max_height = int(size_text)
	print("Image-Format:%s"%image.get_format())
	created_image = Image.create(max_width,max_height,false,image.get_format())
	
	var aspect_ratio = image.get_width() / float(image.get_height())

	
	var new_width = max_width
	var new_height = round(new_width / aspect_ratio)
	
	print("resized-size=%s x %s"%[new_width,new_height])
	
	if new_height > max_height:
		new_height = max_height
		new_width = round(new_height * aspect_ratio)

	
	
	var center_x = (max_width -new_width)/2 
	var center_y = (max_height -new_height)/2 
	print("center-x %s center-y %s"%[center_x,center_y])
	image.resize(new_width, new_height, Image.INTERPOLATE_BILINEAR)
	created_image.blit_rect(image,Rect2(0,0,image.get_width(),image.get_height()),Vector2(center_x,center_y))
	
	if !fixed_size:
		created_image = image
	
	var textureRect = find_child("TextureRect")
	var texture = ImageTexture.create_from_image(created_image)
	textureRect.set_texture(texture)
	
	

func _on_send_button_pressed():
	var input = find_child("InputEdit").text
	request_image_text(input)

func request_image_text(prompt):
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=%s"%api_key
	
	
	
	var raw_data 
	if is_mp4:
		raw_data = FileAccess.get_file_as_bytes(mp4_path)
		print(mp4_path)
	else:
		raw_data = created_image.save_jpg_to_buffer(0.9)
		print("create-image w =%s h =%s"%[created_image.get_width(),created_image.get_height()])
	# Encode Base64
	var base64_data = Marshalls.raw_to_base64(raw_data)

	# MP4 not working so far.
	var mime_type = "video/mp4" if is_mp4 else "image/jpeg"
	#print(base64_image_data)
	var body = JSON.new().stringify({
		"contents":[
			{ "parts":[{
				"text": prompt
			},{
		  	"inline_data": {
			"mime_type":mime_type,
			"data": base64_data
		  }
		}]
			}
		]
		,"safety_settings":[
			{
			"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
			"threshold": "BLOCK_NONE",
			},
			{
			"category": "HARM_CATEGORY_HATE_SPEECH",
			"threshold": "BLOCK_NONE",
			},
			{
			"category": "HARM_CATEGORY_HARASSMENT",
			"threshold": "BLOCK_NONE",
			},
			{
			"category": "HARM_CATEGORY_DANGEROUS_CONTENT",
			"threshold": "BLOCK_NONE",
			},
			]
	})
	
	print("send-content"+str(body))
	find_child("SendButton").disabled = true
	var error = http_request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	
	if error != OK:
		push_error("requested but error happen code = %s"%error)

func _on_request_completed(result, responseCode, headers, body):
	find_child("SendButton").disabled = false
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	print("response")
	print(response)
	
	if response == null:
		print("response is null")
		find_child("FinishedLabel").text = "No Response"
		find_child("FinishedLabel").visible = true
		return
	
	if response.has("error"):
		find_child("FinishedLabel").text = "ERROR"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = str(response.error)
		#maybe blocked
		return
		
	#No Answer
	if !response.has("candidates"):
		find_child("FinishedLabel").text = "Blocked"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = ""
		#maybe blocked
		return
		
	#I can not talk about
	if response.candidates[0].finishReason != "STOP":
		find_child("FinishedLabel").text = "Safety"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = ""
	else:
		find_child("FinishedLabel").text = ""
		find_child("FinishedLabel").visible = false
		var newStr = response.candidates[0].content.parts[0].text
		find_child("ResponseEdit").text = newStr
	


func _on_choose_image_button_pressed():
	file_dialog.popup_centered(Vector2(600, 400))
	
func _get_option_selected_text(key):
	var option = find_child(key+"OptionButton")
	var text = option.get_item_text(option.get_selected_id())
	return  text


