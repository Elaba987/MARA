/// obj_menu  –  Step Event
/// Captura entrada de teclado alfanumérica y valida el código de sala.

audio_play_sound(sfx_room, 10, true);

cursor_blink = (cursor_blink + 1) mod 60;

// ── Temporizador de mensaje ───────────────────────────────────────────────────
if (msg_timer > 0) {
    msg_timer--;
    if (msg_timer == 0) msg_text = "";
}

// ── Captura de carácter alfanumérico ─────────────────────────────────────────
var _ch = keyboard_lastchar;
if (_ch != "" && string_length(input_text) < max_input) {
    var _up   = string_upper(_ch);
    var _code = ord(_up);
    // Sólo letras A-Z y dígitos 0-9
    var _is_alpha = (_code >= 65 && _code <= 90);
    var _is_digit = (_code >= 48 && _code <= 57);
    if (_is_alpha || _is_digit) {
        input_text += _up;
    }
}
keyboard_lastchar = "";   // consumir el carácter

// ── Borrar con BACKSPACE ──────────────────────────────────────────────────────
if (keyboard_check_pressed(vk_backspace) && string_length(input_text) > 0) {
    input_text = string_copy(input_text, 1, string_length(input_text) - 1);
}

// ── Enviar código con ENTER ───────────────────────────────────────────────────
if (keyboard_check_pressed(vk_enter) && string_length(input_text) > 0) {

    var _submitted = string_upper(input_text);

    if (ds_map_exists(valid_rooms, _submitted)) {
        // ── CÓDIGO CORRECTO ─────────────────────────────────────────────────
        var _name = ds_map_find_value(valid_rooms, _submitted);

        if (ds_list_find_index(discovered, _submitted) == -1) {
            // Primera vez: guardar y crear TXT
            ds_list_add(discovered, _submitted);
            scr_save_discovered_rooms(discovered);
            scr_create_room_txt(_submitted);
            msg_text  = "¡SALA DESBLOQUEADA: " + _name + "!";
            msg_color = make_color_rgb(80, 255, 120);
        } else {
            msg_text  = "Accediendo a " + _name + "…";
            msg_color = make_color_rgb(160, 220, 255);
        }
        msg_timer  = 90;
        input_text = "";

        // Ir a la sala de juego después de un breve delay (alarm 0)
        alarm[0] = 60;

    } else {
        // ── CÓDIGO INCORRECTO ───────────────────────────────────────────────
        msg_text   = "Código inválido: " + _submitted;
        msg_color  = make_color_rgb(255, 80, 80);
        msg_timer  = 120;
        input_text = "";
    }
}
