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


func _on_list_model_button_pressed():
	_request_list_models()

func _request_list_model():
	var url = "https://generativelanguage.googleapis.com/v1/models?key=%s"%api_key
	
	find_child("ListModelButton").disabled = true
	var error = http_request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	
	if error != OK:
		push_error("requested but error happen code = %s"%error)

func _request_get_model(model_name = ""):
	var version = _get_option_selected_text("Version")
	var url = "https://generativelanguage.googleapis.com/%s/models/%s?key=%s"%[version,model_name,api_key]
	
	
	find_child("ListModelButton").disabled = true
	find_child("ModelButton").disabled = true
	var error = http_request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	
	if error != OK:
		push_error("requested but error happen code = %s"%error)
				
func _request_list_models(model_name = ""):
	var version = _get_option_selected_text("Version")
	var url = "https://generativelanguage.googleapis.com/%s/models?key=%s"%[version,api_key]
	
	
	find_child("ListModelButton").disabled = true
	var error = http_request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	
	if error != OK:
		push_error("requested but error happen code = %s"%error)

func _on_request_completed(result, responseCode, headers, body):
	find_child("ListModelButton").disabled = false
	find_child("ModelButton").disabled = false
	
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
	
	# model list
	if response.has("models"):
		find_child("FinishedLabel").visible = false
		find_child("ResponseEdit").text = str(response.models)
		_update_model_option_button(response.models)
		#maybe blocked
		return
		
	find_child("FinishedLabel").text = ""
	find_child("FinishedLabel").visible = false
	var newStr = str(response)
	find_child("ResponseEdit").text = newStr
		
	
func _update_model_option_button(models):
	var model_option_button = find_child("ModelOptionButton")
	model_option_button.clear()
	for model in models:
		var names = model.name.split("/")
		model_option_button.add_item(names[names.size()-1])
	
	find_child("ModelButton").disabled = false



func _on_model_button_pressed():
	var selection = _get_option_selected_text("Model")
	_request_get_model(selection)

func _get_option_selected_text(key):
	var option = find_child(key+"OptionButton")
	var text = option.get_item_text(option.get_selected_id())
	return  text
