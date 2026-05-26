/// obj_controller  –  Draw GUI Event
/// HUD: crosshair, estados de niebla/luz, controles.

var _sw = display_get_gui_width();
var _sh = display_get_gui_height();

// ── Crosshair ────────────────────────────────────────────────────────────────
var _cx  = _sw * 0.5;
var _cy  = _sh * 0.5;
var _cs  = cross_size;
var _cg  = cross_gap;

draw_set_color(make_color_rgb(255, 255, 255));
draw_set_alpha(0.85);
// Línea horizontal
draw_rectangle(_cx - _cs - _cg, _cy - 1, _cx - _cg,      _cy + 1, false);
draw_rectangle(_cx + _cg,       _cy - 1, _cx + _cs + _cg, _cy + 1, false);
// Línea vertical
draw_rectangle(_cx - 1, _cy - _cs - _cg, _cx + 1, _cy - _cg,      false);
draw_rectangle(_cx - 1, _cy + _cg,       _cx + 1, _cy + _cs + _cg, false);
draw_set_alpha(1.0);

// ── Info HUD (esquina inferior izquierda) ─────────────────────────────────────
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_bottom);

var _fog_str  = global.fog_enabled ? "ON" : "OFF";
var _line_h   = 18;
var _base_y   = _sh - 8;

draw_set_color(make_color_rgb(0, 0, 0));   // sombra
//draw_text(11, _base_y - _line_h * 0 + 1, "[ESC] Menú   [M] Mapa   [F] Niebla   [+/-] Luz");
//draw_text(11, _base_y - _line_h * 1 + 1,
//    "Niebla: " + _fog_str + "   Luz: " + string(floor(global.ambient_light * 100)) + "%");

draw_set_color(make_color_rgb(200, 200, 200));
//draw_text(10, _base_y - _line_h * 0, "[ESC] Menú   [M] Mapa   [F] Niebla   [+/-] Luz");
//draw_text(10, _base_y - _line_h * 1,
//    "Niebla: " + _fog_str + "   Luz: " + string(floor(global.ambient_light * 100)) + "%");

draw_set_halign(fa_left);
draw_set_valign(fa_top);