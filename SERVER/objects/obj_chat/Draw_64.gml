draw_race_hud();
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_set_valign(fa_top);
var _chat_y = 399;
for (var _i = 0; _i < min(ChatSize, ds_list_size(global.chat)); _i++) {
    var _text = global.chat[| _i];
    _chat_y -= string_height_ext(_text, 18, 672) + 4;
    if (_chat_y < 285) break;
    draw_text_ext(24, _chat_y, _text, 18, 672);
}
draw_set_valign(fa_middle);
draw_set_colour(active ? c_yellow : c_white);
draw_text(24, 415, active ? "> " + chat_text : "Enter to chat");
draw_set_colour(c_white);
draw_text(24, 470, "Space: start / restart race   Enter: chat");
