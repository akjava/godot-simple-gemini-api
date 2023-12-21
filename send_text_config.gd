extends Control


#see https://ai.google.dev/tutorials/rest_quickstart

var api_key = ""
var http_request
func _ready():
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://settings.json"))
	api_key = settings.api_key
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_request_completed)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_send_button_pressed():
	var input = find_child("InputEdit").text
	_request_text(input)

func _request_text(prompt):
	var url = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=%s"%api_key
	
	var stop_sequence = find_child("StopSequenceEdit").text
	var tempature = str(find_child("TempatureSlider").value)
	var output_length = str(find_child("OutputLengthSpinBox").value)
	var top_k=str(find_child("TopKSpinBox").value)
	var top_p=str(find_child("TopPSlider").value)
	var body = JSON.new().stringify({
		"contents":[
			{ "parts":[{
				"text": prompt
			}]
			}
			
		],"safety_settings":[
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
			],
			"generationConfig": {
			"stopSequences": [
				stop_sequence
			],
			"temperature": tempature,
			"maxOutputTokens": output_length,
			"topP": top_p,
			"topK": top_k
		}
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
	if response.candidates[0].finishReason != "STOP" and response.candidates[0].finishReason !="MAX_TOKENS":
		find_child("FinishedLabel").text = "Safety"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = ""
	else:
		
		var newStr = response.candidates[0].content.parts[0].text
		find_child("ResponseEdit").text = newStr
		if response.candidates[0].finishReason =="MAX_TOKENS":
			find_child("FinishedLabel").text = "MAX_TOKENs"
			find_child("FinishedLabel").visible = true
		else:
			find_child("FinishedLabel").text = ""
			find_child("FinishedLabel").visible = false
	




func _on_tempature_slider_value_changed(value):
	find_child("TempatureLabel").text = str(value)


func _on_top_p_slider_value_changed(value):
	find_child("TopPLabel").text = str(value)
