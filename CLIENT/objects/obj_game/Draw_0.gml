if (room != rm_main) exit;
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text(room_width / 2, room_height / 3, "NETWORK SOCKETS DEMO");
draw_text(room_width / 2, room_height / 2, username_ready ? "Hello " + username + ". Press Enter to connect." : "Choose a username in the dialog.");
draw_text(room_width / 2, room_height / 2 + 40, "Arrow keys: drive / stop / steer     Enter: chat");
draw_set_colour(c_yellow);
draw_text_ext(room_width / 2, room_height / 2 + 85, connection_error, 20, room_width - 60);
