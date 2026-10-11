enum network {
    player_establish, player_connect, player_joined,
    player_disconnect, move, chat, race_state, correction
}
client_buffer = buffer_create(10240, buffer_fixed, 1);
socket_to_instanceid = ds_map_create();
global.mysocket = -1;
connected = false;
network_set_config(network_config_connect_timeout, 1000);
client = network_create_socket(network_socket_tcp);
if (client >= 0) {
    network_set_config(network_config_avoid_time_wait, client);
    network_set_config(network_config_message_size_limit, client, 1024);
}
if (client >= 0) connected = network_connect(client, "127.0.0.1", 10000) >= 0;
if (!connected) {
    obj_game.connection_error = "Server unavailable. Start the server, then press Enter to retry.";
    room_goto(rm_main);
}

global.race = { phase: 0, countdown: 0, elapsed: 0, entries: [] };
last_packet_time = current_time;
