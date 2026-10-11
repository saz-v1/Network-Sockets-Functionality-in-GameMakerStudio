var _dt = clamp(delta_time / 1000000, 0, 0.05);
if (keyboard_check_pressed(vk_space) && global.race.phase != 1 && !obj_chat.active && ds_map_size(socket_to_instanceid) > 0) start_race();
if (global.race.phase == 1) {
    global.race.countdown = max(0, global.race.countdown - _dt);
    if (global.race.countdown == 0) { global.race.phase = 2; broadcast_chat("SERVER: Go! Three clockwise laps."); }
} else if (global.race.phase == 2) {
    global.race.elapsed += _dt;
    var _unfinished = 0;
    for (var _i = 0; _i < ds_list_size(socket_list); _i++) {
        var _s = socket_list[| _i];
        if (ds_map_exists(socket_to_instanceid, _s)) {
            var _p = socket_to_instanceid[? _s];
            if (instance_exists(_p) && _p.participating && _p.rank == 0) _unfinished++;
        }
    }
    if (_unfinished == 0) global.race.phase = 3;
}
race_tick = (race_tick + 1) mod 15;
if (race_tick == 0) broadcast_race();
