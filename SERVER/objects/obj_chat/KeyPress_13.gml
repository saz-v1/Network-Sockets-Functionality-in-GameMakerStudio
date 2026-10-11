if (!active) {
    active = true;
    keyboard_string = "";
    chat_text = "";
    exit;
}
active = false;
chat_text = string_trim(string_copy(keyboard_string, 1, 120));
keyboard_string = "";
if (chat_text == "") exit;
with (obj_server) broadcast_chat("SERVER: " + other.chat_text);
