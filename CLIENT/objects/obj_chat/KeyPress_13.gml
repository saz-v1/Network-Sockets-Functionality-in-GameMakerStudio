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

if (!instance_exists(obj_client) || !obj_client.connected) exit;
buffer_seek(obj_client.client_buffer, buffer_seek_start, 0);
buffer_write(obj_client.client_buffer, buffer_u8, network.chat);
buffer_write(obj_client.client_buffer, buffer_string, chat_text);
network_send_packet(obj_client.client, obj_client.client_buffer, buffer_tell(obj_client.client_buffer));
