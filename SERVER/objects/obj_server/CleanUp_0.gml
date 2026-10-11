for (var _i = 0; _i < ds_list_size(socket_list); _i++) network_destroy(socket_list[| _i]);
if (server_socket >= 0) network_destroy(server_socket);
buffer_delete(server_buffer);
ds_list_destroy(socket_list);
ds_map_destroy(socket_to_instanceid);
