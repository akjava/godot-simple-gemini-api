class_name GeminiStreamClient extends HTTPClient

var _api_key

signal receive_text(text)
signal receive_finished

var _thread = Thread.new()
func _init(api_key):
	_api_key = api_key
	_thread.start(_loop_process)
	print("thread started")
	
var path_text_regex = RegEx.new()
func request_text(prompt):
	
	var url = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:streamGenerateContent?key=%s"%_api_key
	
	var body = JSON.new().stringify({
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
	
	print("send-content:"+str(body))
	
	var status = self.get_status()
	if status!=Status.STATUS_CONNECTED:
		var error0 = self.connect_to_host("https://generativelanguage.googleapis.com",-1) # Connect to the host on port 80
		if error0 != OK:
			return error0
			
		while self.get_status() == HTTPClient.STATUS_CONNECTING or self.get_status() == HTTPClient.STATUS_RESOLVING:
			self.poll()
			if not OS.has_feature("web"):
				OS.delay_msec(30)
			else:
				# TODO test
				await Engine.get_singleton("SceneTree").create_timer(0.0).wait_one_frame()
	else:
		print("status:%s"%get_status_text(status))
		assert(self.get_status() == HTTPClient.STATUS_CONNECTED) 
	
		
	var query_string = self.query_string_from_dict(fields)
	
	var error = self.request(HTTPClient.METHOD_POST,"/v1/models/gemini-pro:streamGenerateContent?key=%s"%_api_key, ["User-Agent: Pirulo/1.0 (Godot)","Accept: */*","Content-Type: application/json"], body)
	
	return error

var receiving = false
var last_status = 0
func _loop_process():
	while _thread:
		_process()
		OS.delay_msec(30)
		
func _process():
	var status = self.get_status()
	if status!=last_status:
		print("status:%s"%get_status_text(status))
		last_status = status
		
	path_text_regex.compile(r'"parts":\s*\[\s*{\s*"text":\s*"((?:[^"\\]|\\.)*)"\s*}\s*\]')
			
	#print("status:%s"%http_client.get_status())
	if self.get_status() == HTTPClient.STATUS_REQUESTING:
		self.poll()
		
	elif self.get_status() == HTTPClient.STATUS_BODY:
		#print("body")
		receiving = true
		var response_body = self.read_response_body_chunk()
		if response_body.size() > 0:
		   # Process the response body
			var texts = response_body.get_string_from_utf8()
			#print(texts)
			var result = path_text_regex.search(texts)
			#print(result)
			if result:
				call_deferred("emit_signal","receive_text",result.get_string(1))
			else:
				# possible show some remaining.
				print("somehow no text:%s"%texts)
			
	elif receiving and self.get_status() == HTTPClient.STATUS_CONNECTED:
		call_deferred("emit_signal","receive_finished")
		receiving = false
	OS.delay_msec(30)
		
func dispose():
	_thread.free()
	
func get_status_text(status):
	match status:
		Status.STATUS_DISCONNECTED:
			return "Disconnected from the server."
		Status.STATUS_RESOLVING:
			return "Currently resolving the hostname for the given URL into an IP."
		Status.STATUS_CANT_RESOLVE:
			return "DNS failure: Can't resolve the hostname for the given URL."
		Status.STATUS_CONNECTING:
			return "Currently connecting to server."
		Status.STATUS_CANT_CONNECT:
			return "Can't connect to the server."
		Status.STATUS_CONNECTED:
			return "Connection established."
		Status.STATUS_REQUESTING:
			return "Currently sending request."
		Status.STATUS_BODY:
			return "HTTP body received."
		Status.STATUS_CONNECTION_ERROR:
			return "Error in HTTP connection."
		Status.STATUS_TLS_HANDSHAKE_ERROR:
			return "Error in TLS handshake."
		_:
			return "Unknown status."
