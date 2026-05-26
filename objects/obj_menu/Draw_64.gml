/// obj_menu  –  Draw GUI Event
/// Interfaz completa del menú principal.

var _sw = display_get_gui_width();
var _sh = display_get_gui_height();

// ════════════════════════════════════════════════════════════════════════════
//  FONDO
// ════════════════════════════════════════════════════════════════════════════
// Gradiente simulado con tres rectángulos
draw_set_color(make_color_rgb(4,  4,  14));
draw_rectangle(0,       0,       _sw, _sh * 0.5, false);
draw_set_color(make_color_rgb(8,  6,  20));
draw_rectangle(0,       _sh*0.5, _sw, _sh * 0.8, false);
draw_set_color(make_color_rgb(12, 8,  24));
draw_rectangle(0,       _sh*0.8, _sw, _sh,        false);

// Líneas decorativas horizontales (scanlines sutiles)
draw_set_alpha(0.04);
draw_set_color(c_white);
for (var _sl = 0; _sl < _sh; _sl += 3) {
    draw_line(0, _sl, _sw, _sl);
}
draw_set_alpha(1.0);

// ════════════════════════════════════════════════════════════════════════════
//  PANEL IZQUIERDO / CENTRAL  (código de sala)
// ════════════════════════════════════════════════════════════════════════════
var _panel_w = floor(_sw * 0.55);
var _panel_x = 0;

// ── Título ────────────────────────────────────────────────────────────────────
draw_set_font(-1);   // Reemplaza por fnt_title si tienes una fuente grande
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _tx = 60;

// Título principal
draw_set_color(make_color_rgb(255, 80, 50));
draw_text_transformed(_tx, 60, "RAYCASTER", 3, 3, 0);

draw_set_color(make_color_rgb(200, 140, 90));
draw_text_transformed(_tx, 120, "ENGINE  2.5D", 2, 2, 0);

// Línea separadora
draw_set_color(make_color_rgb(100, 60, 160));
draw_set_alpha(0.8);
draw_rectangle(_tx, 162, _panel_w - 40, 164, false);
draw_set_alpha(1.0);

// Subtítulo
draw_set_color(make_color_rgb(130, 130, 180));
draw_text_transformed(_tx, 175, "DOOM-STYLE  RAYCASTING", 1, 1, 0);

// ── Instrucción ───────────────────────────────────────────────────────────────
var _field_y = 260;

draw_set_color(make_color_rgb(180, 160, 220));
draw_text_transformed(_tx, _field_y - 28, "INGRESA CÓDIGO DE SALA:", 1, 1, 0);

// ── Caja de input ─────────────────────────────────────────────────────────────
var _field_w = 280;
var _field_h = 44;
var _field_x = _tx;

// Marco exterior (glow)
draw_set_alpha(0.4);
draw_set_color(make_color_rgb(120, 80, 200));
draw_rectangle(_field_x - 2, _field_y - 2, _field_x + _field_w + 2, _field_y + _field_h + 2, false);
draw_set_alpha(1.0);

// Fondo interior
draw_set_color(make_color_rgb(18, 14, 34));
draw_rectangle(_field_x, _field_y, _field_x + _field_w, _field_y + _field_h, false);

// Borde
draw_set_color(make_color_rgb(80, 60, 140));
draw_rectangle(_field_x, _field_y, _field_x + _field_w, _field_y + _field_h, true);

// Texto del input
var _display = input_text;
var _cursor_char = (cursor_blink < 30) ? "_" : " ";
_display += _cursor_char;

draw_set_color(make_color_rgb(220, 200, 255));
draw_text_transformed(_field_x + 14, _field_y + 10, _display, 1.3, 1.3, 0);

// ── Mensaje de feedback ───────────────────────────────────────────────────────
if (msg_text != "") {
    var _alpha_fade = msg_timer > 30 ? 1.0 : (msg_timer / 30);
    draw_set_alpha(_alpha_fade);
    draw_set_color(msg_color);
    draw_text(_field_x, _field_y + _field_h + 14, msg_text);
    draw_set_alpha(1.0);
}

// ── Hint de teclas ────────────────────────────────────────────────────────────
draw_set_color(make_color_rgb(80, 75, 110));
draw_text(_tx, _field_y + _field_h + 48, "ENTER → confirmar    BACKSPACE → borrar");

// ── Códigos de ejemplo (debug) ────────────────────────────────────────────────
draw_set_color(make_color_rgb(55, 50, 80));
draw_text(_tx, _field_y + _field_h + 72,
    "Códigos de prueba: ALPHA1  BETA02  TEST00  DOOM25  DARK01  FOGX99");

// ════════════════════════════════════════════════════════════════════════════
//  PANEL DERECHO  (salas desbloqueadas)
// ════════════════════════════════════════════════════════════════════════════
var _rpx    = _panel_w + 20;
var _rpy    = 60;
var _rpw    = _sw - _rpx - 20;
var _line_h = 26;

// Fondo del panel
draw_set_alpha(0.45);
draw_set_color(make_color_rgb(0, 0, 0));
draw_rectangle(_rpx - 10, _rpy - 10, _sw - 10, _sh - 10, false);
draw_set_alpha(1.0);

// Borde izquierdo decorativo
draw_set_color(make_color_rgb(100, 60, 160));
draw_rectangle(_rpx - 10, _rpy - 10, _rpx - 7, _sh - 10, false);

// Encabezado
draw_set_color(make_color_rgb(180, 140, 255));
draw_text_transformed(_rpx, _rpy, "SALAS DESBLOQUEADAS", 1.1, 1.1, 0);

draw_set_color(make_color_rgb(80, 60, 120));
draw_rectangle(_rpx, _rpy + 26, _sw - 14, _rpy + 28, false);

// Lista de salas
var _n = ds_list_size(discovered);
if (_n == 0) {
    draw_set_color(make_color_rgb(70, 65, 100));
    draw_text(_rpx, _rpy + 40, "Ninguna todavía…");
} else {
    for (var i = 0; i < _n; i++) {
        var _code  = ds_list_find_value(discovered, i);
        var _name  = ds_map_exists(valid_rooms, _code)
                     ? ds_map_find_value(valid_rooms, _code)
                     : "???";
        var _iy    = _rpy + 42 + i * _line_h;

        // Alternar color de fila
        if (i mod 2 == 0) {
            draw_set_alpha(0.12);
            draw_set_color(c_white);
            draw_rectangle(_rpx - 4, _iy - 2, _sw - 14, _iy + _line_h - 4, false);
            draw_set_alpha(1.0);
        }

        // Icono de sala
        draw_set_color(make_color_rgb(80, 255, 130));
        draw_text(_rpx, _iy, "▶");

        // Código
        draw_set_color(make_color_rgb(220, 210, 255));
        draw_text(_rpx + 18, _iy, _code);

        // Nombre
        draw_set_color(make_color_rgb(140, 140, 180));
        draw_text(_rpx + 90, _iy, _name);

        // Parar si se sale del panel
        if (_iy + _line_h > _sh - 20) break;
    }
}

// Contador total
draw_set_color(make_color_rgb(80, 75, 110));
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_text(_sw - 14, _sh - 12,
    string(_n) + " / " + string(ds_map_size(valid_rooms)) + " salas encontradas");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
