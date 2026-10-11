function add_chat_message(_text) {
    ds_list_insert(global.chat, 0, _text);
    while (ds_list_size(global.chat) > 5) ds_list_delete(global.chat, ds_list_size(global.chat) - 1);
}

function received_packet(_buffer, _socket, _size) {
    if (!packet_has(_buffer, _size, 1)) return;
    var _message = buffer_read(_buffer, buffer_u8);
    if (_message == network.player_establish) {
        var _name = packet_read_text(_buffer, _size, 24);
        if (is_undefined(_name)) return;
        _name = string_trim(string_replace_all(string_replace_all(_name, "\n", " "), "\r", " "));
        if (_name == "") _name = "Player";
        network_player_join(_name, _socket);
        return;
    }
    if (!ds_map_exists(socket_to_instanceid, _socket)) return;
    var _player = socket_to_instanceid[? _socket];
    if (!instance_exists(_player)) return;

    switch (_message) {
        case network.move:
            if (!packet_has(_buffer, _size, 16)) return;
            var _x = buffer_read(_buffer, buffer_f32);
            var _y = buffer_read(_buffer, buffer_f32);
            var _angle = buffer_read(_buffer, buffer_f32);
            var _direction = buffer_read(_buffer, buffer_f32);
            if (is_nan(_x) || is_nan(_y) || is_nan(_angle) || is_nan(_direction)
                || is_infinity(_x) || is_infinity(_y) || is_infinity(_angle) || is_infinity(_direction)) return;
            var _old_x = _player.x;
            var _allowed = 3.2 * clamp((current_time - _player.last_move_time) / 16.667, 1, 12) + 8;
            _player.last_move_time = current_time;
            if (global.race.phase != 2 || !_player.participating || _player.rank > 0) return;
            if (!on_track(_x, _y) || point_distance(_player.x, _player.y, _x, _y) > _allowed) { send_correction(_socket, _player); return; }
            _player.x = _x; _player.y = _y;
            _player.image_angle = ((_angle mod 360) + 360) mod 360;
            _player.direction = ((_direction mod 360) + 360) mod 360;
            check_race_progress(_player, _old_x);
            buffer_seek(server_buffer, buffer_seek_start, 0);
            buffer_write(server_buffer, buffer_u8, network.move);
            buffer_write(server_buffer, buffer_u32, _socket);
            buffer_write(server_buffer, buffer_f32, _player.x);
            buffer_write(server_buffer, buffer_f32, _player.y);
            buffer_write(server_buffer, buffer_f32, _player.image_angle);
            buffer_write(server_buffer, buffer_f32, _player.direction);
            // Do not overwrite the local driver's newer position with an old echo.
            for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
                var _peer = socket_list[| _i];
                if (_peer != _socket) network_send_packet(_peer, server_buffer, buffer_tell(server_buffer));
            }
            break;

        case network.chat:
            var _text = packet_read_text(_buffer, _size, 120);
            if (is_undefined(_text)) return;
            _text = string_trim(string_replace_all(string_replace_all(_text, "\n", " "), "\r", " "));
            if (_text == "") return;
            broadcast_chat(_player.username + ": " + _text);
            break;
    }
}

function broadcast_chat(_text) {
    add_chat_message(_text);
    buffer_seek(server_buffer, buffer_seek_start, 0);
    buffer_write(server_buffer, buffer_u8, network.chat);
    buffer_write(server_buffer, buffer_string, _text);
    for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
        network_send_packet(socket_list[| _i], server_buffer, buffer_tell(server_buffer));
    }
}

// Never read beyond the actual network payload, including its string terminator.
function packet_has(_buffer, _size, _bytes) {
    return _size >= 0 && _size <= buffer_get_size(_buffer)
        && buffer_tell(_buffer) + _bytes <= _size;
}

function packet_read_text(_buffer, _size, _limit) {
    var _start = buffer_tell(_buffer);
    var _end = min(_size, _start + _limit * 4 + 1);
    for (var _i = _start; _i < _end; _i++) {
        if (buffer_peek(_buffer, _i, buffer_u8) == 0) {
            var _text = buffer_read(_buffer, buffer_string);
            if (string_length(_text) <= _limit) return _text;
            return undefined;
        }
    }
    return undefined;
}

// Rounded track boundaries match the room artwork; do not wrap through walls.
function inside_round_rect(_x, _y, _l, _t, _r, _b, _radius) {
    if (_x < _l || _x > _r || _y < _t || _y > _b) return false;
    var _cx = clamp(_x, _l + _radius, _r - _radius);
    var _cy = clamp(_y, _t + _radius, _b - _radius);
    return point_distance(_x, _y, _cx, _cy) <= _radius;
}
function on_track(_x, _y) {
    return inside_round_rect(_x, _y, 35, 42, 685, 455, 90)
        && !inside_round_rect(_x, _y, 117, 119, 603, 362, 60);
}
function draw_race_hud() {
    draw_set_alpha(0.75); draw_set_colour(c_black);
    draw_rectangle(145, 157, 575, 278, false);
    draw_set_alpha(1); draw_set_colour(c_white);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    var _race = global.race;
    var _title = "WAITING FOR HOST - 3 LAP RACE";
    if (_race.phase == 1) _title = "START IN " + string(ceil(_race.countdown));
    if (_race.phase == 2) _title = "RACING - " + string_format(_race.elapsed, 0, 1) + "s";
    if (_race.phase == 3) _title = "RACE FINISHED";
    draw_text(158, 166, _title);
    for (var _i = 0; _i < array_length(_race.entries); _i++) {
        var _e = _race.entries[_i];
        var _name = "Player";
        var _map = obj_server.socket_to_instanceid;
        if (ds_map_exists(_map, _e.socket) && instance_exists(_map[? _e.socket])) _name = (_map[? _e.socket]).username;
        _name = string_copy(_name, 1, 16);
        var _progress = _e.participating ? "Lap " + string(min(_e.laps + 1, 3)) + "/3" : (_race.phase == 0 ? "Ready" : "Next race");
        if (_e.rank > 0) _progress = "#" + string(_e.rank) + "  " + string_format(_e.finish, 0, 1) + "s";
        draw_text(158, 186 + 16 * _i, _name + "   " + _progress);
    }
    // Visible start / finish line on the upper straight.
    for (var _row = 0; _row < 4; _row++) {
        for (var _col = 0; _col < 2; _col++) {
            draw_set_colour(((_row + _col) mod 2) == 0 ? c_white : c_black);
            draw_rectangle(600 + _col * 6, 50 + _row * 15, 606 + _col * 6, 65 + _row * 15, false);
        }
    }
    draw_set_colour(c_white); draw_set_valign(fa_middle);
}

function start_race() {
    global.race.phase = 1; global.race.countdown = 3; global.race.elapsed = 0; finish_count = 0;
    var _slot = 0;
    for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
        var _s = socket_list[| _i];
        if (!ds_map_exists(socket_to_instanceid, _s)) continue;
        var _p = socket_to_instanceid[? _s];
        if (!instance_exists(_p)) continue;
        _p.x = 540 - _slot * 90; _p.y = 85;
        _p.image_angle = 0; _p.direction = 0;
        _p.laps = 0; _p.checkpoint = 0; _p.rank = 0; _p.finish_time = 0; _p.participating = true;
        _p.last_move_time = current_time; _slot++;
    }
    broadcast_chat("SERVER: Race starts in 3 seconds."); broadcast_race();
}
function check_race_progress(_p, _old_x) {
    if (global.race.phase != 2 || !_p.participating || _p.rank > 0) return;
    switch (_p.checkpoint) {
        case 0: if (_p.x > 620 && _p.y > 170 && _p.y < 320) _p.checkpoint = 1; break;
        case 1: if (_p.y > 390 && _p.x > 200 && _p.x < 520) _p.checkpoint = 2; break;
        case 2: if (_p.x < 100 && _p.y > 170 && _p.y < 320) _p.checkpoint = 3; break;
        case 3:
            if (_old_x < 600 && _p.x >= 600 && _p.y >= 42 && _p.y < 119) {
                _p.laps++; _p.checkpoint = 0;
                if (_p.laps == 3) {
                    finish_count++; _p.rank = finish_count; _p.finish_time = global.race.elapsed;
                    broadcast_chat("SERVER: " + _p.username + " finished #" + string(_p.rank) + ".");
                }
                broadcast_race();
            }
            break;
    }
}
function broadcast_race() {
    global.race.entries = [];
    for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
        var _s = socket_list[| _i];
        if (!ds_map_exists(socket_to_instanceid, _s)) continue;
        var _p = socket_to_instanceid[? _s];
        if (!instance_exists(_p)) continue;
        array_push(global.race.entries, {socket: _s, laps: _p.laps, checkpoint: _p.checkpoint,
            rank: _p.rank, finish: _p.finish_time, x: _p.x, y: _p.y, participating: _p.participating});
    }
    buffer_seek(server_buffer, buffer_seek_start, 0);
    buffer_write(server_buffer, buffer_u8, network.race_state);
    buffer_write(server_buffer, buffer_u8, global.race.phase);
    buffer_write(server_buffer, buffer_f32, global.race.countdown);
    buffer_write(server_buffer, buffer_f32, global.race.elapsed);
    buffer_write(server_buffer, buffer_u8, array_length(global.race.entries));
    for (var _i = 0; _i < array_length(global.race.entries); _i++) {
        var _e = global.race.entries[_i];
        buffer_write(server_buffer, buffer_u32, _e.socket);
        buffer_write(server_buffer, buffer_u8, _e.laps); buffer_write(server_buffer, buffer_u8, _e.checkpoint);
        buffer_write(server_buffer, buffer_u8, _e.rank); buffer_write(server_buffer, buffer_f32, _e.finish);
        buffer_write(server_buffer, buffer_f32, _e.x); buffer_write(server_buffer, buffer_f32, _e.y);
        buffer_write(server_buffer, buffer_bool, _e.participating);
    }
    for (var _i = 0; _i < ds_list_size(socket_list); _i++) network_send_packet(socket_list[| _i], server_buffer, buffer_tell(server_buffer));
}

function send_correction(_socket, _p) {
    buffer_seek(server_buffer, buffer_seek_start, 0);
    buffer_write(server_buffer, buffer_u8, network.correction);
    buffer_write(server_buffer, buffer_u32, _socket);
    buffer_write(server_buffer, buffer_f32, _p.x); buffer_write(server_buffer, buffer_f32, _p.y);
    buffer_write(server_buffer, buffer_f32, _p.image_angle); buffer_write(server_buffer, buffer_f32, _p.direction);
    network_send_packet(_socket, server_buffer, buffer_tell(server_buffer));
}
