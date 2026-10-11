// GameMaker does not notify TCP clients when their server disconnects.
// The server sends race snapshots every 15 frames, also acting as a heartbeat.
if (connected && current_time - last_packet_time > 5000) {
    connected = false;
    obj_game.connection_error = "Server connection lost. Start the server, then press Enter to reconnect.";
    room_goto(rm_main);
}
