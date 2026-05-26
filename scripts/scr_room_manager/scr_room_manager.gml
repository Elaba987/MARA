/// @desc  Gestión de códigos de sala, persistencia y creación de archivos TXT.
/// Usa buffer API (buffer_write / buffer_save / buffer_load) en lugar de
/// file_text_write, que no está disponible en todas las versiones de GMS2.

// ─────────────────────────────────────────────────────────────────────────────
//  HELPER INTERNO: escribe un string en un buffer con salto de línea Windows
// ─────────────────────────────────────────────────────────────────────────────
function _buf_writeln(_buf, _str) {
    buffer_write(_buf, buffer_text, _str);
    buffer_write(_buf, buffer_u8, 13);   // CR
    buffer_write(_buf, buffer_u8, 10);   // LF
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREAR TXT DE SALA
// ─────────────────────────────────────────────────────────────────────────────

/// @desc  Genera ROOM_<código>.txt en working_directory con Lorem Ipsum.
function scr_create_room_txt(_code) {

    var _lorem =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod" + chr(10) +
        "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam," + chr(10) +
        "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo" + chr(10) +
        "consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse" + chr(10) +
        "cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat" + chr(10) +
        "non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." + chr(10) +
        chr(10) +
        "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium" + chr(10) +
        "doloremque laudantium, totam rem aperiam eaque ipsa quae ab illo inventore" + chr(10) +
        "veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim" + chr(10) +
        "ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia" + chr(10) +
        "consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.";

    var _fecha = string(current_year) + "-" +
                 string_format(current_month, 2, 0) + "-" +
                 string_format(current_day,   2, 0);
    var _hora  = string_format(current_hour,   2, 0) + ":" +
                 string_format(current_minute, 2, 0) + ":" +
                 string_format(current_second, 2, 0);

    var _path = working_directory + "ROOM_" + _code + ".txt";
    var _buf  = buffer_create(4096, buffer_grow, 1);

    _buf_writeln(_buf, "============================================================");
    _buf_writeln(_buf, "  SALA DESBLOQUEADA: " + _code);
    _buf_writeln(_buf, "  Fecha : " + _fecha);
    _buf_writeln(_buf, "  Hora  : " + _hora);
    _buf_writeln(_buf, "============================================================");
    _buf_writeln(_buf, "");
    _buf_writeln(_buf, _lorem);
    _buf_writeln(_buf, "");
    _buf_writeln(_buf, "============================================================");

    buffer_save(_buf, _path);
    buffer_delete(_buf);

    show_debug_message("Room TXT creado: " + _path);
}

// ─────────────────────────────────────────────────────────────────────────────
//  GUARDAR LISTA DE SALAS DESCUBIERTAS  →  discovered_rooms.sav
// ─────────────────────────────────────────────────────────────────────────────

function scr_save_discovered_rooms(_list) {

    var _n    = ds_list_size(_list);
    var _buf  = buffer_create(512, buffer_grow, 1);
    var _path = working_directory + "discovered_rooms.sav";

    for (var i = 0; i < _n; i++) {
        _buf_writeln(_buf, string(ds_list_find_value(_list, i)));
    }

    buffer_save(_buf, _path);
    buffer_delete(_buf);
    show_debug_message("Salas guardadas: " + string(_n));
}

// ─────────────────────────────────────────────────────────────────────────────
//  CARGAR LISTA DE SALAS DESCUBIERTAS  ←  discovered_rooms.sav
// ─────────────────────────────────────────────────────────────────────────────

function scr_load_discovered_rooms(_list) {

    var _path = working_directory + "discovered_rooms.sav";
    if (!file_exists(_path)) {
        show_debug_message("No hay salas guardadas todavia.");
        return;
    }

    var _buf = buffer_load(_path);
    if (_buf < 0) {
        show_debug_message("ERROR: no se pudo leer " + _path);
        return;
    }

    var _size = buffer_get_size(_buf);
    var _line = "";

    for (var i = 0; i < _size; i++) {
        buffer_seek(_buf, buffer_seek_start, i);
        var _byte = buffer_read(_buf, buffer_u8);

        if (_byte == 10 || _byte == 13) {
            _line = string_replace_all(_line, chr(13), "");
            _line = string_replace_all(_line, chr(10), "");
            if (_line != "" && ds_list_find_index(_list, _line) == -1) {
                ds_list_add(_list, _line);
            }
            _line = "";
        } else {
            _line += chr(_byte);
        }
    }
    // Última línea sin salto al final
    if (_line != "" && ds_list_find_index(_list, _line) == -1) {
        ds_list_add(_list, _line);
    }

    buffer_delete(_buf);
    show_debug_message("Salas cargadas: " + string(ds_list_size(_list)));
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABLA DE ROOMS VÁLIDAS  –  añade aquí nuevos códigos
// ─────────────────────────────────────────────────────────────────────────────

function scr_build_valid_rooms() {
    var _m = ds_map_create();
    ds_map_add(_m, "ALPHA1", "Sector Alpha");
    ds_map_add(_m, "BETA02", "Pasillo Beta");
    ds_map_add(_m, "TEST00", "Sala de Prueba");
    ds_map_add(_m, "DOOM25", "Mazmorra 25");
    ds_map_add(_m, "DARK01", "Cripta Oscura");
    ds_map_add(_m, "FOGX99", "Niebla Eterna");
    return _m;
}
