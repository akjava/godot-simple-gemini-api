# godot-simple-gemini-api
This is Example Project not addon.
As simply as possible, call the Gemini API.
## Update
### 2024-Apr-10
add Gemini 1.5 Pro example 'chat_1_5'
## API KEYS
This app requires an API key. Save it in settings.json. Take care of your keys. By default, it is added to .gitignore.
## LICENSE
MIT LICENSE - Akihito Miyazaki
## Examples
V1beta parts are not implemented yet.
see https://ai.google.dev/tutorials/rest_quickstart
### send_text
simple send text
### sent_text_safety
show how to control safety.
### set_text_config
send text with configuration (stopsequence ,temperature ..etc)
### send_text_stream
Send a text stream. This code uses HttpClient. I'm not familiar with this; please handle with care.
### chat_text
Send multiple-turn text.
### send_image
Send an image and text. I tested mp4, but it's not working.
### get_embedding
get single embedding
### batch_embedding
get  multiple embedding and cmpare them.
### count_tokens
count tokens
### get_list_model
get model list and info.

