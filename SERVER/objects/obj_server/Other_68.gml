var _type = async_load[? "type"];
switch (_type) {
    case network_type_connect:
        var _socket = async_load[? "socket"];
        if (ds_list_find_index(socket_list, _socket) >= 0) break;
        network_set_config(network_config_avoid_time_wait, _socket);
        network_set_config(network_config_message_size_limit, _socket, 1024);
        ds_list_add(socket_list, _socket);
        buffer_seek(server_buffer, buffer_seek_start, 0);
        buffer_write(server_buffer, buffer_u8, network.player_establish);
        buffer_write(server_buffer, buffer_u32, _socket);
        network_send_packet(_socket, server_buffer, buffer_tell(server_buffer));
        break;

    case network_type_disconnect:
        var _socket = async_load[? "socket"];
        var _index = ds_list_find_index(socket_list, _socket);
        if (_index >= 0) ds_list_delete(socket_list, _index);
        // A connection can close before completing the username handshake.
        if (!ds_map_exists(socket_to_instanceid, _socket)) break;
        var _player = socket_to_instanceid[? _socket];
        if (instance_exists(_player)) with (_player) instance_destroy();
        ds_map_delete(socket_to_instanceid, _socket);
        buffer_seek(server_buffer, buffer_seek_start, 0);
        buffer_write(server_buffer, buffer_u8, network.player_disconnect);
        buffer_write(server_buffer, buffer_u32, _socket);
        for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
            network_send_packet(socket_list[| _i], server_buffer, buffer_tell(server_buffer));
        }
        break;

    case network_type_data:
        var _socket = async_load[? "id"];
        if (ds_list_find_index(socket_list, _socket) < 0) break;
        var _buffer = async_load[? "buffer"];
        buffer_seek(_buffer, buffer_seek_start, 0);
        received_packet(_buffer, _socket, async_load[? "size"]);
        break;
}
