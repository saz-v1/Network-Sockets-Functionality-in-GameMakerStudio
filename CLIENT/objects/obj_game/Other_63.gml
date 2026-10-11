if (async_load[? "id"] != username_dialog) exit;
if (async_load[? "status"]) {
    var _name = string_trim(async_load[? "result"]);
    if (_name != "") username = string_copy(_name, 1, 24);
}
username_ready = true;
window_set_caption("Network Client | " + username);
