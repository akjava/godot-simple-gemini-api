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
	var example_result = { "candidates": [{ "content": { "parts": [{ "text": "The current Prime Minister of the United Kingdom is Keir Starmer.  He assumed office after the Labour Party won a landslide victory in a general election in July 2024.  Rishi Sunak, previously the Prime Minister,  served from October 2022 until July 2024.  This information is current as of today, November 4, 2024.\n" }], "role": "model" }, "finishReason": "STOP", "safetyRatings": [{ "category": "HARM_CATEGORY_HATE_SPEECH", "probability": "NEGLIGIBLE" }, { "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "probability": "NEGLIGIBLE" }, { "category": "HARM_CATEGORY_HARASSMENT", "probability": "NEGLIGIBLE" }, { "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "probability": "NEGLIGIBLE" }], "groundingMetadata": { "searchEntryPoint": { "renderedContent": "<style>\n.container {\n  align-items: center;\n  border-radius: 8px;\n  display: flex;\n  font-family: Google Sans, Roboto, sans-serif;\n  font-size: 14px;\n  line-height: 20px;\n  padding: 8px 12px;\n}\n.chip {\n  display: inline-block;\n  border: solid 1px;\n  border-radius: 16px;\n  min-width: 14px;\n  padding: 5px 16px;\n  text-align: center;\n  user-select: none;\n  margin: 0 8px;\n  -webkit-tap-highlight-color: transparent;\n}\n.carousel {\n  overflow: auto;\n  scrollbar-width: none;\n  white-space: nowrap;\n  margin-right: -12px;\n}\n.headline {\n  display: flex;\n  margin-right: 4px;\n}\n.gradient-container {\n  position: relative;\n}\n.gradient {\n  position: absolute;\n  transform: translate(3px, -9px);\n  height: 36px;\n  width: 9px;\n}\n@media (prefers-color-scheme: light) {\n  .container {\n    background-color: #fafafa;\n    box-shadow: 0 0 0 1px #0000000f;\n  }\n  .headline-label {\n    color: #1f1f1f;\n  }\n  .chip {\n    background-color: #ffffff;\n    border-color: #d2d2d2;\n    color: #5e5e5e;\n    text-decoration: none;\n  }\n  .chip:hover {\n    background-color: #f2f2f2;\n  }\n  .chip:focus {\n    background-color: #f2f2f2;\n  }\n  .chip:active {\n    background-color: #d8d8d8;\n    border-color: #b6b6b6;\n  }\n  .logo-dark {\n    display: none;\n  }\n  .gradient {\n    background: linear-gradient(90deg, #fafafa 15%, #fafafa00 100%);\n  }\n}\n@media (prefers-color-scheme: dark) {\n  .container {\n    background-color: #1f1f1f;\n    box-shadow: 0 0 0 1px #ffffff26;\n  }\n  .headline-label {\n    color: #fff;\n  }\n  .chip {\n    background-color: #2c2c2c;\n    border-color: #3c4043;\n    color: #fff;\n    text-decoration: none;\n  }\n  .chip:hover {\n    background-color: #353536;\n  }\n  .chip:focus {\n    background-color: #353536;\n  }\n  .chip:active {\n    background-color: #464849;\n    border-color: #53575b;\n  }\n  .logo-light {\n    display: none;\n  }\n  .gradient {\n    background: linear-gradient(90deg, #1f1f1f 15%, #1f1f1f00 100%);\n  }\n}\n</style>\n<div class=\"container\">\n  <div class=\"headline\">\n    <svg class=\"logo-light\" width=\"18\" height=\"18\" viewBox=\"9 9 35 35\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\">\n      <path fill-rule=\"evenodd\" clip-rule=\"evenodd\" d=\"M42.8622 27.0064C42.8622 25.7839 42.7525 24.6084 42.5487 23.4799H26.3109V30.1568H35.5897C35.1821 32.3041 33.9596 34.1222 32.1258 35.3448V39.6864H37.7213C40.9814 36.677 42.8622 32.2571 42.8622 27.0064V27.0064Z\" fill=\"#4285F4\"/>\n      <path fill-rule=\"evenodd\" clip-rule=\"evenodd\" d=\"M26.3109 43.8555C30.9659 43.8555 34.8687 42.3195 37.7213 39.6863L32.1258 35.3447C30.5898 36.3792 28.6306 37.0061 26.3109 37.0061C21.8282 37.0061 18.0195 33.9811 16.6559 29.906H10.9194V34.3573C13.7563 39.9841 19.5712 43.8555 26.3109 43.8555V43.8555Z\" fill=\"#34A853\"/>\n      <path fill-rule=\"evenodd\" clip-rule=\"evenodd\" d=\"M16.6559 29.8904C16.3111 28.8559 16.1074 27.7588 16.1074 26.6146C16.1074 25.4704 16.3111 24.3733 16.6559 23.3388V18.8875H10.9194C9.74388 21.2072 9.06992 23.8247 9.06992 26.6146C9.06992 29.4045 9.74388 32.022 10.9194 34.3417L15.3864 30.8621L16.6559 29.8904V29.8904Z\" fill=\"#FBBC05\"/>\n      <path fill-rule=\"evenodd\" clip-rule=\"evenodd\" d=\"M26.3109 16.2386C28.85 16.2386 31.107 17.1164 32.9095 18.8091L37.8466 13.8719C34.853 11.082 30.9659 9.3736 26.3109 9.3736C19.5712 9.3736 13.7563 13.245 10.9194 18.8875L16.6559 23.3388C18.0195 19.2636 21.8282 16.2386 26.3109 16.2386V16.2386Z\" fill=\"#EA4335\"/>\n    </svg>\n    <svg class=\"logo-dark\" width=\"18\" height=\"18\" viewBox=\"0 0 48 48\" xmlns=\"http://www.w3.org/2000/svg\">\n      <circle cx=\"24\" cy=\"23\" fill=\"#FFF\" r=\"22\"/>\n      <path d=\"M33.76 34.26c2.75-2.56 4.49-6.37 4.49-11.26 0-.89-.08-1.84-.29-3H24.01v5.99h8.03c-.4 2.02-1.5 3.56-3.07 4.56v.75l3.91 2.97h.88z\" fill=\"#4285F4\"/>\n      <path d=\"M15.58 25.77A8.845 8.845 0 0 0 24 31.86c1.92 0 3.62-.46 4.97-1.31l4.79 3.71C31.14 36.7 27.65 38 24 38c-5.93 0-11.01-3.4-13.45-8.36l.17-1.01 4.06-2.85h.8z\" fill=\"#34A853\"/>\n      <path d=\"M15.59 20.21a8.864 8.864 0 0 0 0 5.58l-5.03 3.86c-.98-2-1.53-4.25-1.53-6.64 0-2.39.55-4.64 1.53-6.64l1-.22 3.81 2.98.22 1.08z\" fill=\"#FBBC05\"/>\n      <path d=\"M24 14.14c2.11 0 4.02.75 5.52 1.98l4.36-4.36C31.22 9.43 27.81 8 24 8c-5.93 0-11.01 3.4-13.45 8.36l5.03 3.85A8.86 8.86 0 0 1 24 14.14z\" fill=\"#EA4335\"/>\n    </svg>\n    <div class=\"gradient-container\"><div class=\"gradient\"></div></div>\n  </div>\n  <div class=\"carousel\">\n    <a class=\"chip\" href=\"https://vertexaisearch.cloud.google.com/grounding-api-redirect/AZnLMfw6EewOCxCzP9HrHGnteRuRxwB590Gi_k83YJDXhqRND11vc1Ai7xE9SwUN0hK_gSKROBwiaitDT2uw3QYVeHHKqGuOqh9e62ZUbbN7sqx4NZP_lfHsFB45ZrYTw7VAoa7Zplh5-YaLSoLtgXBmVYmeHMihhw8aYXyHZGU-C8R7sKvWR2wEkVFGiQWGVNlByXgItfPANSiDjk8fhBHQwRA=\">who is the england president</a>\n  </div>\n</div>\n" }, "groundingChunks": [{ "web": { "uri": "https://vertexaisearch.cloud.google.com/grounding-api-redirect/AZnLMfyAdjZU29jvPvQoWqNzRC8mxDyMIk1hwplroEUe6HeDb5Oma8qGCd8PTlf45yobMTGbpxj_1VfwKrQQap2p-SBpSoBgAfDlLUZpacKtY67je1ZnrW2USRM-EzzhJWqB8MnE1MZZC_C2zoOdfzdR-EDgBZG8LsolliXasJqJK9pyoQ==", "title": "northeastern.edu" } }, { "web": { "uri": "https://vertexaisearch.cloud.google.com/grounding-api-redirect/AZnLMfwTtX5AQbfz7k_ZVzaKnt5R4qZ4tOVaZcAKV1aKsToAiv-5IipT-zU2TZiIcSiHggeRjvoFyVlDD1WpTdsK9djLkKr0RH9ABrE4yPlKp4FHJ4xWNyK2nHo1-6hwbsbGjrqrOy96F5SViZYfAw==", "title": "britannica.com" } }], "groundingSupports": [{ "segment": { "endIndex": 65, "text": "The current Prime Minister of the United Kingdom is Keir Starmer." }, "groundingChunkIndices": [0], "confidenceScores": [0.94584656] }, { "segment": { "startIndex": 67, "endIndex": 167, "text": "He assumed office after the Labour Party won a landslide victory in a general election in July 2024." }, "groundingChunkIndices": [0, 1], "confidenceScores": [0.7727694, 0.7727694] }, { "segment": { "startIndex": 169, "endIndex": 255, "text": "Rishi Sunak, previously the Prime Minister,  served from October 2022 until July 2024." }, "groundingChunkIndices": [1], "confidenceScores": [0.7620234] }], "retrievalMetadata": { "googleSearchDynamicRetrievalScore": 0.82421875 }, "webSearchQueries": ["who is the england president"] }, "avgLogprobs": -0.21539766648236 }], "usageMetadata": { "promptTokenCount": 5, "candidatesTokenCount": 85, "totalTokenCount": 90 }, "modelVersion": "gemini-1.5-flash-8b-001" }
	_request_text(input)

	#var chunks = text.groundingChunks
	#print(text)
	

func _request_text(prompt):
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-8b:generateContent?key=%s"%api_key
	
	var dynamic_threshold = 0.3 #default
	var body = JSON.new().stringify({
		"contents":[
			{ "parts":[{
				"text": prompt
			}]
			}
		],
		"tools":[
			{
				"google_search_retrieval":{
					"dynamic_retrieval_config":{
						"mode":"MODE_DYNAMIC",
						"dynamic_threshold":dynamic_threshold
					}
				}
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
		
		var chunks = response.candidates[0].groundingMetadata.groundingChunks
		for i in range(chunks.size()):
			print("%s = %s"%[i,chunks[i]["web"]["title"]])
		var supports = response.candidates[0].groundingMetadata.groundingSupports
		for i in range(supports.size()):
			print(supports[i]["segment"]["text"])
			print("%s = %s"%[supports[i].groundingChunkIndices,supports[i].confidenceScores])
		print(response.candidates[0].groundingMetadata.retrievalMetadata)
			
		find_child("ResponseEdit").text = newStr
	
