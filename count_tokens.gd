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
	var url = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:countTokens?key=%s"%api_key
	
	var body = JSON.new().stringify({
		"contents":[
			{ "parts":[{
				"text": prompt
			}]
			}
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
	if !response.has("totalTokens"):
		find_child("FinishedLabel").text = "Blocked"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = ""
		#maybe blocked
		return
		
	find_child("FinishedLabel").text = ""
	find_child("FinishedLabel").visible = false
	var newStr = response.totalTokens
	find_child("ResponseEdit").text = str(newStr)
		
	
