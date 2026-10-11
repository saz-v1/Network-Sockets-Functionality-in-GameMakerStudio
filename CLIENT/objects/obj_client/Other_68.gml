if (async_load[? "id"] != client) exit;
switch (async_load[? "type"]) {
    case network_type_data:
        if (!connected) break;
        last_packet_time = current_time;
        var _buffer = async_load[? "buffer"];
        buffer_seek(_buffer, buffer_seek_start, 0);
        received_packet(_buffer, async_load[? "size"]);
        break;
    case network_type_disconnect:
        connected = false;
        obj_game.connection_error = "Connection closed. Start the server, then press Enter to reconnect.";
        room_goto(rm_main);
        break;
}
