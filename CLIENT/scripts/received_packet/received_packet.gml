function add_chat_message(_text) {
    ds_list_insert(global.chat, 0, _text);
    while (ds_list_size(global.chat) > 5) ds_list_delete(global.chat, ds_list_size(global.chat) - 1);
}

function received_packet(_buffer, _size) {
    if (!packet_has(_buffer, _size, 1)) return;
    var _message = buffer_read(_buffer, buffer_u8);
    switch (_message) {
        case network.player_establish:
            if (!packet_has(_buffer, _size, 4)) return;
            global.mysocket = buffer_read(_buffer, buffer_u32);
            buffer_seek(client_buffer, buffer_seek_start, 0);
            buffer_write(client_buffer, buffer_u8, network.player_establish);
            buffer_write(client_buffer, buffer_string, obj_game.username);
            network_send_packet(client, client_buffer, buffer_tell(client_buffer));
            break;

        case network.player_connect:
        case network.player_joined:
            if (!packet_has(_buffer, _size, 20)) return;
            var _socket = buffer_read(_buffer, buffer_u32);
            var _x = buffer_read(_buffer, buffer_f32);
            var _y = buffer_read(_buffer, buffer_f32);
            var _angle = buffer_read(_buffer, buffer_f32);
            var _direction = buffer_read(_buffer, buffer_f32);
            var _name = packet_read_text(_buffer, _size, 24);
            if (is_undefined(_name) || ds_map_exists(socket_to_instanceid, _socket)) return;
            var _object = (_socket == global.mysocket) ? obj_player : obj_player2;
            var _player = instance_create_depth(_x, _y, depth, _object);
            _player.socket = _socket;
            _player.username = _name;
            _player.image_angle = _angle;
            _player.direction = _direction;
            socket_to_instanceid[? _socket] = _player;
            break;

        case network.player_disconnect:
            if (!packet_has(_buffer, _size, 4)) return;
            var _socket = buffer_read(_buffer, buffer_u32);
            if (!ds_map_exists(socket_to_instanceid, _socket)) return;
            var _player = socket_to_instanceid[? _socket];
            if (instance_exists(_player)) with (_player) instance_destroy();
            ds_map_delete(socket_to_instanceid, _socket);
            break;

        case network.correction:
        case network.move:
            if (!packet_has(_buffer, _size, 20)) return;
            var _socket = buffer_read(_buffer, buffer_u32);
            if ((_socket == global.mysocket && _message == network.move) || !ds_map_exists(socket_to_instanceid, _socket)) return;
            var _player = socket_to_instanceid[? _socket];
            if (!instance_exists(_player)) return;
            _player.x = buffer_read(_buffer, buffer_f32);
            _player.y = buffer_read(_buffer, buffer_f32);
            _player.image_angle = buffer_read(_buffer, buffer_f32);
            _player.direction = buffer_read(_buffer, buffer_f32);
            if (_message == network.correction) _player.drive_speed = 0;
            break;

        case network.race_state:
            if (!packet_has(_buffer, _size, 10)) return;
            var _phase = buffer_read(_buffer, buffer_u8);
            var _countdown = buffer_read(_buffer, buffer_f32);
            var _elapsed = buffer_read(_buffer, buffer_f32);
            var _count = buffer_read(_buffer, buffer_u8);
            if (_phase > 3 || _count > 5 || !packet_has(_buffer, _size, _count * 20)) return;
            var _reset = _phase == 1 && global.race.phase != 1;
            var _entries = [];
            for (var _i = 0; _i < _count; _i++) {
                var _e = { socket: buffer_read(_buffer, buffer_u32), laps: buffer_read(_buffer, buffer_u8),
                    checkpoint: buffer_read(_buffer, buffer_u8), rank: buffer_read(_buffer, buffer_u8),
                    finish: buffer_read(_buffer, buffer_f32), x: buffer_read(_buffer, buffer_f32),
                    y: buffer_read(_buffer, buffer_f32), participating: buffer_read(_buffer, buffer_bool) };
                array_push(_entries, _e);
                if (ds_map_exists(socket_to_instanceid, _e.socket)) {
                    var _p = socket_to_instanceid[? _e.socket];
                    if (instance_exists(_p)) {
                        _p.laps = _e.laps; _p.checkpoint = _e.checkpoint; _p.rank = _e.rank;
                        _p.finish_time = _e.finish; _p.participating = _e.participating;
                        if (_reset || _e.socket != global.mysocket) { _p.x = _e.x; _p.y = _e.y; }
                        if (_reset) { _p.direction = 0; _p.image_angle = 0; }
                    }
                }
            }
            global.race = { phase: _phase, countdown: _countdown, elapsed: _elapsed, entries: _entries };
            break;

        case network.chat:
            var _text = packet_read_text(_buffer, _size, 160);
            if (!is_undefined(_text)) add_chat_message(_text);
            break;
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
        var _map = obj_client.socket_to_instanceid;
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
