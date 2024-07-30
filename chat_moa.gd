extends Control


#see https://ai.google.dev/tutorials/rest_quickstart

var api_key = ""
var http_request
var conversations = []
var last_user_prompt
var main_model = "v1beta/models/gemini-1.5-pro-latest"

var REFERENCE_SYSTEM_PROMPT = """\
		You have been provided with a set of responses from various open-source models to the latest user query. 
		Your task is to synthesize these responses into a single, high-quality response. 
		It is crucial to critically evaluate the information provided in these responses, recognizing that some of it may be biased or incorrect. 
		Your response should not simply replicate the given answers but should offer a refined, accurate, and comprehensive reply to the instruction. 
		Ensure your response is well-structured, coherent, and adheres to the highest standards of accuracy and reliability.
		Responses from models:
		{responses}
		"""
		
class Agent:
	var model = "v1beta/models/gemini-1.5-flash-latest"
	var system_prompt = ""
	
var agents = []
var messages_option_button_dic ={}
func update_main_model():
	var option = find_child("MainModelOptionButton")
	var text = option.get_item_text(option.get_selected_id())
	main_model = "v1beta/models/%s"%[text]
func _ready():
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://settings.json"))
	api_key = settings.api_key
	http_request = HTTPRequest.new()
	add_child(http_request)
	#http_request.connect("request_completed", _on_request_completed)

	update_main_model()
	
	
	find_child("LineEdit1").text = "You are a writer exploring the concept of artificial intelligence and its potential to change our world."
	find_child("LineEdit2").text = "You are a software developer creating an AI assistant that can help people learn a new skill."
	find_child("LineEdit3").text = "You are a painter creating a surreal landscape that represents the inner workings of a human mind."
	find_child("LineEdit4").text = "You are a powerful sorcerer in a medieval fantasy realm, tasked with crafting a unique spell to protect your village from a looming threat."
	find_child("LineEdit5").text = "You are a celestial being observing the rise and fall of civilizations across countless galaxies, reflecting on the nature of life, death, and the universe"
	find_child("LineEdit6").text = "You are a time traveler who accidentally swapped bodies with a grumpy old cat. Describe your daily life and your attempts to get back to your own body."
	find_child("LineEdit7").text = "You are a scientist contemplating the possibility of life on other planets. What are the biggest challenges and potential solutions in the search for extraterrestrial life?"
	

	var agent_container = find_child("AgentContainer")
	for child in agent_container.get_children():
		if child is LineEdit:
			var agent = Agent.new()
			agent.system_prompt = child.text
			agents.append(agent)
			#print("append %s"%agent.system_prompt)
			#break
			

	# for safety filter
	var  option_keys = ["SexuallyExplicit","HateSpeech","Harassment","DangerousContent"]
	for key in option_keys:
		var option = find_child(key+"OptionButton")
		option.add_item("BLOCK_NONE")
		option.add_item("HARM_BLOCK_THRESHOLD_UNSPECIFIED")
		option.add_item("BLOCK_LOW_AND_ABOVE")
		option.add_item("BLOCK_MEDIUM_AND_ABOVE")
		option.add_item("BLOCK_ONLY_HIGH")
		
	#var name = main_model.split("/")[-1]
	#find_child("ModelName").text = name
	#conversations.append({"user":"I am aki","model":"Hello aki"})
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _get_option_selected_text(key):
	var option = find_child(key+"OptionButton")
	var text = option.get_item_text(option.get_selected_id())
	return  text

func _add_messages_option_button(label):
	find_child("MessagesOptionButton").add_item(label)
	
func _on_send_button_pressed():
	conversations = []
	messages_option_button_dic.clear()
	find_child("MessagesOptionButton").clear()
	
	find_child("SendButton").disabled = true
	var input = find_child("InputEdit").text
	#_request_chat(input)
	var cycle = find_child("CycleOptionButton").get_selected_id() 
	print(cycle)
	var final_system_prompt = ""
	
	for i in range(cycle):
		print("cycle %s"%i)
		var cycle_conversations = []
		#var responses = []
		for agent in agents:
			print("[%s]"%agent.system_prompt)
			var system = agent.system_prompt + "\n\n"+final_system_prompt
			var error =  _request_chat(agent.model,input,system)
			if error != OK:
				push_error("requested but error happen code = %s"%error)
				return
			
			# TODO support thread
			var res = await http_request.request_completed
			#var result, responseCode, headers, body = res
			var response = _get_response_text(res[0],res[1],res[2],res[3])
			find_child("TextEditA").text = response
			find_child("TextEditB").text = system
			
			var max_text = 80
			var label = "Cycle %02d:%s"%[i,agent.system_prompt.substr(0,max_text)]
			_add_messages_option_button(label)
			var dic = {"user":input,"model":response,"system":system}
			messages_option_button_dic[label] = dic
			cycle_conversations.append(dic)
		
			
		var response_text = ""
		for j in range(cycle_conversations.size()):
			var index = j+1
			var current_response = cycle_conversations[j]["model"]
			response_text +=  "[Assistant%s]%s\n"%[index,current_response]
			conversations.append(cycle_conversations[j])
		
		final_system_prompt = REFERENCE_SYSTEM_PROMPT.replace("{responses}",response_text)
	
	print("[Final]")
	var error_main =  _request_chat(main_model,input,final_system_prompt)
	if error_main != OK:
		push_error("requested but error happen code = %s"%error_main)
		return
		
	
	var res_main = await http_request.request_completed
	var main_response = _get_response_text(res_main[0],res_main[1],res_main[2],res_main[3])
	find_child("ResponseEdit").text = main_response
	find_child("SendButton").disabled = false 


func _request_chat(model_name,prompt,system_prompt=""):
	
	var url = "https://generativelanguage.googleapis.com/%s:generateContent?key=%s"%[model_name,api_key]
	print(url)
	var contents_value = []
	
	for conversation in conversations:
		contents_value.append({
			"role":"user",
			"parts":[{"text":conversation["user"]}]
		})
		contents_value.append({
			"role":"model",
			"parts":[{"text":conversation["model"]}]
		})
		
	var system_parts = []
	if system_prompt!="":
		pass
		system_parts.append({"text":system_prompt})
	contents_value.append({
			"role":"user",
			"parts":[{"text":prompt}],
			
		})
	var body = JSON.new().stringify({
		"contents":contents_value
		,"system_instruction":{
				"parts":system_parts
			},
		# basically useless,just they say 'I cant talk about that.'
		"safety_settings":[
			{
			"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
			"threshold": _get_option_selected_text("SexuallyExplicit"),
			},
			{
			"category": "HARM_CATEGORY_HATE_SPEECH",
			"threshold": _get_option_selected_text("HateSpeech"),
			},
			{
			"category": "HARM_CATEGORY_HARASSMENT",
			"threshold": _get_option_selected_text("Harassment"),
			},
			{
			"category": "HARM_CATEGORY_DANGEROUS_CONTENT",
			"threshold": _get_option_selected_text("DangerousContent"),
			},
			]
	})
	last_user_prompt = prompt
	print("### send-content")
	print(str(body))
	var error = http_request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	return error
	

func _set_label_text(key,text):
	var label = find_child(key)
	if text == "HIGH":
		label.get_label_settings().set_font_color(Color(1,0,0,1))
	else:
		label.get_label_settings().set_font_color(Color(1,1,1,1))
	label.text = text
func _on_request_completed(result, responseCode, headers, body):
	pass
	
func _get_response_text(result, responseCode, headers, body):
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
	
	
	if response.has("promptFeedback"):
		var ratings = response.promptFeedback.safetyRatings
		for rate in ratings:
			match rate.category:
				"HARM_CATEGORY_SEXUALLY_EXPLICIT":
					_set_label_text("SexuallyExplicitStatus",rate.probability)
					
				"HARM_CATEGORY_HATE_SPEECH":
					_set_label_text("HateSpeechStatus",rate.probability)
					
				"HARM_CATEGORY_HARASSMENT":
					_set_label_text("HarassmentStatus",rate.probability)
					
				"HARM_CATEGORY_DANGEROUS_CONTENT":
					_set_label_text("DangerousContentStatus",rate.probability)
					
	
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
		return newStr
		#find_child("ResponseEdit").text = newStr
		#conversations.append({"user":"%s"%last_user_prompt,"model":"%s"%newStr})
	


func _on_messages_option_button_item_selected(index):
	var text = find_child("MessagesOptionButton").get_item_text(index)
	var dict = messages_option_button_dic[text]
	var response = dict["model"]
	find_child("TextEditA").text = response
	var system = dict["system"]
	find_child("TextEditB").text = system
	


func _on_main_model_option_button_item_selected(index):
	update_main_model()
