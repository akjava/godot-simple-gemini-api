extends Control


#see https://ai.google.dev/tutorials/rest_quickstart

var api_key = ""
var gemini_stream_client
var response_edit
func _ready():
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://settings.json"))
	api_key = settings.api_key
	gemini_stream_client = GeminiStreamClient.new(api_key)
	gemini_stream_client.receive_text.connect(_on_receive_text)
	gemini_stream_client.receive_finished.connect(_on_receive_finished)
	
	response_edit = find_child("ResponseEdit")
func _on_request_finished():
	find_child("SendButton").disabled = false
	
func _on_send_button_pressed():
	var input = find_child("InputEdit").text
	_request_text(input)

func _request_text(prompt):
	find_child("ResponseEdit").text = ""
	find_child("SendButton").disabled = true
	var error = gemini_stream_client.request_text(prompt)
	
	if error != OK:
		push_error("Some error happened:%s"%error)
		
func _on_receive_text(text):
	text = text.replace("\\n\\n","\n") #somehow return double
	text = text.replace("\\n", "\n")  # 
	text = text.replace("\\r", "\r")  # 
	text = text.replace("\\t", "\t")  # 
	text = text.replace("\\\\", "\\") # 
	text = text.replace("\\\"", "\"") # 
	text = text.replace("\\\'", "\'") # 
	
	response_edit.text = response_edit.text + text
	
func _on_receive_finished():
	find_child("SendButton").disabled = false
