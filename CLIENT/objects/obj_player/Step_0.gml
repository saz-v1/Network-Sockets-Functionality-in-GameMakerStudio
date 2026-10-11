if (!instance_exists(obj_client) || !obj_client.connected) exit;
// Use custom movement, rather than GameMaker's automatic speed integration.
speed = 0;
var _dt = clamp(delta_time / 16666.667, 0, 3);
var _can_drive = global.race.phase == 2 && participating && rank == 0
    && !(instance_exists(obj_chat) && obj_chat.active);
if (_can_drive) {
    if (keyboard_check(vk_up)) drive_speed += 0.075 * _dt;
    else drive_speed = max(0, drive_speed - 0.025 * _dt);
    if (keyboard_check(vk_down)) drive_speed -= 0.15 * _dt;
    drive_speed = clamp(drive_speed, 0, 3.2);
    // Clockwise on this track: Right turns down, Left turns up.
    var _steer = keyboard_check(vk_left) - keyboard_check(vk_right);
    direction = ((direction + _steer * 2.4 * min(drive_speed, 1) * _dt) mod 360 + 360) mod 360;
    var _nx = x + lengthdir_x(drive_speed * _dt, direction);
    var _ny = y + lengthdir_y(drive_speed * _dt, direction);
    if (on_track(_nx, _ny)) { x = _nx; y = _ny; }
    else drive_speed = 0;
} else drive_speed = 0;
image_angle = direction;
send_tick = (send_tick + 1) mod 3;
if (send_tick != 0) exit;
buffer_seek(obj_client.client_buffer, buffer_seek_start, 0);
buffer_write(obj_client.client_buffer, buffer_u8, network.move);
buffer_write(obj_client.client_buffer, buffer_f32, x);
buffer_write(obj_client.client_buffer, buffer_f32, y);
buffer_write(obj_client.client_buffer, buffer_f32, image_angle);
buffer_write(obj_client.client_buffer, buffer_f32, direction);
network_send_packet(obj_client.client, obj_client.client_buffer, buffer_tell(obj_client.client_buffer));
