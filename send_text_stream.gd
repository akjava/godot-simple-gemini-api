extends Control


#see https://ai.google.dev/tutorials/rest_quickstart

var api_key = ""
var http_client
func _ready():
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://settings.json"))
	api_key = settings.api_key
	http_client = HTTPClient.new()
	#add_child(http_client)
	#http_request.connect("request_completed", _on_request_completed)
	
@onready var path_text_regex = RegEx.new()
# Called every frame. 'delta' is the elapsed time since the previous frame.
var receiving = false
func _process(_delta):
	
	path_text_regex.compile(r'"parts":\s*\[\s*{\s*"text":\s*"((?:[^"\\]|\\.)*)"\s*}\s*\]')
			
	#print("status:%s"%http_client.get_status())
	if http_client and http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		
	if http_client and http_client.get_status() == HTTPClient.STATUS_BODY:
		#print("body")
		receiving = true
		var response_body = http_client.read_response_body_chunk()
		if response_body.size() > 0:
		   # Process the response body
			var texts = response_body.get_string_from_utf8()
			#print(texts)
			var result = path_text_regex.search(texts)
			if result:
				var text = result.get_string(1).replace("\\n\\n","\n") #somehow return double
				text = text.replace("\\n", "\n")  # 
				text = text.replace("\\r", "\r")  # 
				text = text.replace("\\t", "\t")  # 
				text = text.replace("\\\\", "\\") # 
				text = text.replace("\\\"", "\"") # 
				text = text.replace("\\\'", "\'") # 
				find_child("ResponseEdit").text = find_child("ResponseEdit").text + text
				print(result.get_string(1))
			
	if receiving and http_client.get_status() == HTTPClient.STATUS_CONNECTED:
		_on_request_finished()
		receiving = false

func _on_request_finished():
	find_child("SendButton").disabled = false
	
func _on_send_button_pressed():
	var input = find_child("InputEdit").text
	_request_text(input)

func _request_text(prompt):
	find_child("ResponseEdit").text = ""
	
	var body = JSON.stringify({
		"contents":[
			{ "parts":[{
				"text": prompt
			}]
			}
		]
	})
	var fields = {
		"contents":[
			{ "parts":[{
				"text": prompt
			}]
			}
		]
	}
	
	print("send-content"+str(body))
	find_child("SendButton").disabled = true
	
	var error0 = http_client.connect_to_host("https://generativelanguage.googleapis.com",-1) # Connect to the host on port 80
	if error0 != OK:
		push_error("connect_to_host error")
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		#print("Connecting...")
		if not OS.has_feature("web"):
			OS.delay_msec(30)
		else:
			await Engine.get_singleton("SceneTree").create_timer(0.0).wait_one_frame()

	#print(http_client.get_status())
	assert(http_client.get_status() == HTTPClient.STATUS_CONNECTED) 
	#while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
	#	print(http_client.get_status())
		
	
	var error = http_client.request(HTTPClient.METHOD_POST,"/v1/models/gemini-pro:streamGenerateContent?key=%s"%api_key, ["User-Agent: Pirulo/1.0 (Godot)","Accept: */*","Content-Type: application/json"], body)
	if error != OK:
		push_error("requested but error happen code = %s"%error)

func _on_request_completed(result, responseCode, _headers, body):
	if result != OK:
		print("request faild error code: ", result)
		return
	if responseCode != 200:
		print("response is not 200 error code: ", responseCode)
		return
		
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
	
