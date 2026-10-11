function network_player_join(_username, _socket) {
    if (ds_map_exists(socket_to_instanceid, _socket)) return;
    var _slot = ds_map_size(socket_to_instanceid);
    var _player = instance_create_depth(540 - _slot * 90, 85, depth, obj_player);
    _player.username = _username;
    socket_to_instanceid[? _socket] = _player;
    send_player_packet(_socket, network.player_connect, _socket, _player);

    for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
        var _peer = socket_list[| _i];
        if (_peer == _socket || !ds_map_exists(socket_to_instanceid, _peer)) continue;
        var _other = socket_to_instanceid[? _peer];
        if (!instance_exists(_other)) continue;
        send_player_packet(_socket, network.player_joined, _peer, _other);
        send_player_packet(_peer, network.player_joined, _socket, _player);
    }
    broadcast_race();
}

function send_player_packet(_recipient, _message, _socket, _player) {
    buffer_seek(server_buffer, buffer_seek_start, 0);
    buffer_write(server_buffer, buffer_u8, _message);
    buffer_write(server_buffer, buffer_u32, _socket);
    buffer_write(server_buffer, buffer_f32, _player.x);
    buffer_write(server_buffer, buffer_f32, _player.y);
    buffer_write(server_buffer, buffer_f32, _player.image_angle);
    buffer_write(server_buffer, buffer_f32, _player.direction);
    buffer_write(server_buffer, buffer_string, _player.username);
    network_send_packet(_recipient, server_buffer, buffer_tell(server_buffer));
}
