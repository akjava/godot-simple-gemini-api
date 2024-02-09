extends Control

var settings_path = "res://settings.json"
# Called when the node enters the scene tree for the first time.
func _ready():
	var container = find_child("GridContainer")
	var names = ["send_text","send_text_safety","send_text_config","send_text_stream","chat_text","send_image","get_embedding","batch_embedding","count_tokens","get_list_model"]
	for node_name in names:
		var button = Button.new()
		button.text = node_name
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(button))
		container.add_child(button)
		
	_update_ui()

func _on_button_pressed(button):
	var scene_path = "res://"+button.text+".tscn"
	get_tree().change_scene_to_file(scene_path)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _update_ui():
	if FileAccess.file_exists(settings_path):
		find_child("KeyContainer").visible = false
		find_child("ButtonContainer").visible = true
	else:
		find_child("KeyContainer").visible = true
		find_child("ButtonContainer").visible = false

func _on_set_api_button_pressed():
	var key = find_child("KeyEdit").text
	if key.is_empty():
		return
	var json_text = JSON.stringify({"api_key":key})
	var file = FileAccess.open(settings_path,FileAccess.WRITE)
	file.store_string(json_text)
	file.close()
	_update_ui()
