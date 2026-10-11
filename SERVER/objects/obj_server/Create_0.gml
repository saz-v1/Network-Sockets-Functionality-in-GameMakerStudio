enum network {
    player_establish, player_connect, player_joined,
    player_disconnect, move, chat, race_state, correction
}
port = 10000;
MaxClients = 5;
server_buffer = buffer_create(10240, buffer_fixed, 1);
socket_list = ds_list_create();
socket_to_instanceid = ds_map_create();
playerSpawn_x = 100;
playerSpawn_y = 100;
server_socket = network_create_server(network_socket_tcp, port, MaxClients);
if (server_socket < 0) show_error("Could not start server on port " + string(port), true);
network_set_config(network_config_avoid_time_wait, server_socket);
window_set_caption("Network Server | TCP port " + string(port));

global.race = { phase: 0, countdown: 0, elapsed: 0, entries: [] };
race_tick = 0; finish_count = 0;
