if (client >= 0) network_destroy(client);
buffer_delete(client_buffer);
ds_map_destroy(socket_to_instanceid);
global.mysocket = -1;
