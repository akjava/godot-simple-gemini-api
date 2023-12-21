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
	
	var task_type_option=find_child("TaskTypeOptionButton")
	task_type_option.add_item("SEMANTIC_SIMILARITY")
	task_type_option.add_item("RETRIEVAL_QUERY")
	task_type_option.add_item("RETRIEVAL_DOCUMENT")
	task_type_option.add_item("CLASSIFICATION")
	task_type_option.add_item("CLUSTERING")
	task_type_option.add_item("TASK_TYPE_UNSPECIFIED")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _get_option_selected_text(key):
	var option = find_child(key+"OptionButton")
	var text = option.get_item_text(option.get_selected_id())
	return  text
	

func _on_send_button_pressed():
	var input = find_child("InputEdit").text
	_request_embedding(input)

func _request_embedding(prompt):
	var url = "https://generativelanguage.googleapis.com/v1/models/embedding-001:embedContent?key=%s"%api_key
	
	var body = JSON.new().stringify({
		"model": "models/embedding-001",
		"content":
			{ "parts":[{
				"text": prompt
			}]
			},"taskType":_get_option_selected_text("TaskType")
		
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
	if response.has("embedding"):
		find_child("FinishedLabel").text = ""
		find_child("FinishedLabel").visible = false
		find_child("ResponseEdit").text = str(response.embedding.values)
	else:
		find_child("FinishedLabel").text = "Unknown"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = str(response)
		
	




