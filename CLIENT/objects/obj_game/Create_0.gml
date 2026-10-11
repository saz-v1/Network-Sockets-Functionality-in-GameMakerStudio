username = "Player";
username_ready = false;
connection_error = "";
window_set_caption("Network Client");
username_dialog = get_string_async("Enter your name (up to 24 characters)", "Player");
