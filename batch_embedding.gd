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
	
	#test grid
	grid = find_child("GridContainer")
	#grid.visible = false
	#find_node("ScrollContainer").add_child(grid)
	_update_grid()
	
var sort_ascending = true
var sort_key = "text1"
var grid
var datas = []
func _update_grid():
	var headers = ["text1","text2","cosine similarity","euclidean distance"]
	#var grid = GridContainer.new()
	var scroll = find_child("ScrollContainer")
	
	grid.queue_free()
	grid = GridContainer.new()
	scroll.add_child(grid)
	grid.columns = headers.size()
	for head in headers:
		var button = Button.new()
		button.connect("pressed", Callable(self, "_on_header_pressed").bind(button))
		button.text = head
		grid.add_child(button)
	
		
	
	
	var sort_order = "_ascending" if sort_ascending else "_descending"
	var sort_method = "sort_"+sort_key.to_lower()+sort_order
	datas.sort_custom(Callable(self,sort_method))
	for data in datas:
		_data_to_grid(data)
		
	
func _convert_to_data(text1,text2,embedding1,embedding2) -> Dictionary:
	var dic = {}
	
	dic["text1"] = text1
	dic["text2"] = text2

	dic["cosine_similarity"] = cosine_similarity(embedding1,embedding2)
	dic["euclidean_distance"] = euclidean_distance(embedding1,embedding2)
	
	return dic
	
func _data_to_grid(data):
	var label = Label.new()
	label.text = data["text1"]
	grid.add_child(label)
	
	
	var label2 = Label.new()
	label2.text = data["text2"]
	grid.add_child(label2)
	
	
	var label_cs = Label.new()
	label_cs.text = str(data["cosine_similarity"])
	
	grid.add_child(label_cs)
	var label_ed = Label.new()
	label_ed.text = str(data["euclidean_distance"])
	grid.add_child(label_ed)
	
		
func cosine_similarity(vec1: PackedFloat32Array, vec2: PackedFloat32Array) -> float:
	var dot_product = 0.0
	var magnitude1 = 0.0
	var magnitude2 = 0.0

	for i in range(vec1.size()):
		dot_product += vec1[i] * vec2[i]
		magnitude1 += vec1[i] * vec1[i]
		magnitude2 += vec2[i] * vec2[i]

	if magnitude1 == 0.0 or magnitude2 == 0.0:
		return 0.0

	return dot_product / (sqrt(magnitude1) * sqrt(magnitude2))


# ユークリッド距離を計算する関数
func euclidean_distance(vec1: PackedFloat32Array, vec2: PackedFloat32Array) -> float:
	var distance = 0.0
	
	for i in range(vec1.size()):
		distance += pow(vec1[i] - vec2[i], 2)
	
	return sqrt(distance)
			
	
func _on_header_pressed(button):
	
	sort_key = button.text.replace(" ","_")
	
	_update_grid()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _get_option_selected_text(key):
	var option = find_child(key+"OptionButton")
	var text = option.get_item_text(option.get_selected_id())
	return  text
	

func _on_send_button_pressed():
	var input = find_child("InputEdit").text
	_request_batch_embeddings(input)

var texts = ["hello","world"]
var embeddings = []
func _request_batch_embeddings(prompt):
	var url = "https://generativelanguage.googleapis.com/v1/models/embedding-001:batchEmbedContents?key=%s"%api_key
	
	
	texts.clear()
	var request_value = []
	var lines = prompt.split("\n")
	for line in lines:
		if line.is_empty():
			continue
		texts.append(line)
		request_value.append({
			"model": "models/embedding-001",
			"content":
				{ "parts":[{
					"text": line
				}]
				},"taskType":_get_option_selected_text("TaskType")
			
		})
	
	var body = JSON.new().stringify({"requests":request_value})
	
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
	if response.has("embeddings"):
		find_child("FinishedLabel").text = ""
		find_child("FinishedLabel").visible = false
		find_child("ResponseEdit").text = str(response.embeddings)
		embeddings.clear()
		for embedding in response.embeddings:
			embeddings.append(PackedFloat32Array(embedding.values))
			
	else:
		find_child("FinishedLabel").text = "Unknown"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = str(response)
		
	datas.clear()
	for i in range(texts.size()):
		for j in range(i + 1, texts.size()):
			datas.append(_convert_to_data(texts[i],texts[j],embeddings[i],embeddings[j]))
			
	_update_grid()
	

static func sort_text1_ascending(a:Dictionary, b:Dictionary) -> bool:
	return a["text1"] < b["text1"]
	
static func sort_text2_ascending(a:Dictionary, b:Dictionary) -> bool:
	return a["text2"] < b["text2"] 
	
static func sort_cosine_similarity_ascending(a:Dictionary, b:Dictionary) -> bool:
	if a["cosine_similarity"] == b["cosine_similarity"]  :
		return sort_text1_ascending(a,b)
		#In cosine similarity, a value closer to 1 indicates that the two vectors are similar.
	return a["cosine_similarity"] > b["cosine_similarity"]

static func sort_euclidean_distance_ascending(a:Dictionary, b:Dictionary) -> bool:
	if a["euclidean_distance"] == b["euclidean_distance"]  :
		return sort_text1_ascending(a,b)
		#In Euclidean distance, a value closer to 0 indicates that the two points are similar. The larger the distance, the less similar the two points are.
	return a["euclidean_distance"] < b["euclidean_distance"]



