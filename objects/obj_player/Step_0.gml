/// obj_player  –  Step Event
/// Controles: WASD para moverse, ratón para mirar (horizontal + vertical).
/// Sistema de colisión deslizante con las paredes.

var _dt  = delta_time / 1_000_000;   // delta time en segundos
var _wcx = window_get_width()  div 2;
var _wcy = window_get_height() div 2;

// ════════════════════════════════════════════════════════════════════════════
//  1. MIRADA CON EL RATÓN
// ════════════════════════════════════════════════════════════════════════════
var _mdx = window_mouse_get_x() - _wcx;   // delta X del ratón
var _mdy = window_mouse_get_y() - _wcy;   // delta Y del ratón

// Girar horizontalmente
look_angle += _mdx * mouse_sens_h;
if (look_angle >= 360) look_angle -= 360;
if (look_angle <    0) look_angle += 360;

// Mira vertical (offset del horizonte, estilo DOOM – no cambia el ángulo real)
look_vertical += _mdy * mouse_sens_v;
var _max_vert = surface_get_height(application_surface) * 0.30;
look_vertical  = clamp(look_vertical, -_max_vert, _max_vert);

// Re-centrar el cursor
window_mouse_set(_wcx, _wcy);

// ════════════════════════════════════════════════════════════════════════════
//  2. MOVIMIENTO WASD
// ════════════════════════════════════════════════════════════════════════════
var _rad  = degtorad(look_angle);
var _fwd  = [cos(_rad),            sin(_rad)           ];   // frente
var _rgt  = [cos(_rad + pi * 0.5), sin(_rad + pi * 0.5)];   // derecha (strafe)

var _dx = 0;
var _dy = 0;

if (keyboard_check(ord("W"))) { _dx += _fwd[0];  _dy += _fwd[1]; }
if (keyboard_check(ord("S"))) { _dx -= _fwd[0];  _dy -= _fwd[1]; }
if (keyboard_check(ord("A"))) { _dx -= _rgt[0];  _dy -= _rgt[1]; }
if (keyboard_check(ord("D"))) { _dx += _rgt[0];  _dy += _rgt[1]; }

// Normalizar diagonal para no moverse más rápido en 45°
var _len = sqrt(_dx*_dx + _dy*_dy);
if (_len > 0) {
    _dx = (_dx / _len) * move_speed * _dt;
    _dy = (_dy / _len) * move_speed * _dt;
}

// ════════════════════════════════════════════════════════════════════════════
//  3. COLISIÓN DESLIZANTE (slide collision)
//     Separamos X e Y para permitir "deslizarse" por las paredes.
// ════════════════════════════════════════════════════════════════════════════
var _cr  = col_radius;
var _nx  = x + _dx;
var _ny  = y + _dy;

// ── Movimiento en X ──────────────────────────────────────────────────────────
if (!scr_circle_wall(_nx, y, _cr)) {
    x = _nx;
} else {
    // Empuja suavemente lejos del muro para evitar quedarse pegado
    var _push_x = (scr_wall_at(x + _cr, y) ? -1 : 0) +
                  (scr_wall_at(x - _cr, y) ?  1 : 0);
    x += _push_x * 0.5;
}

// ── Movimiento en Y ──────────────────────────────────────────────────────────
if (!scr_circle_wall(x, _ny, _cr)) {
    y = _ny;
} else {
    var _push_y = (scr_wall_at(x, y + _cr) ? -1 : 0) +
                  (scr_wall_at(x, y - _cr) ?  1 : 0);
    y += _push_y * 0.5;
}

// ════════════════════════════════════════════════════════════════════════════
//  4. AJUSTE DE NIEBLA CON FLECHAS (para testing rápido)
// ════════════════════════════════════════════════════════════════════════════
// Flecha arriba/abajo → fog_start ; Flecha izq/dcha → fog_end
if (keyboard_check(vk_up))    global.fog_start = max(global.fog_start   - 80*_dt, 0);
if (keyboard_check(vk_down))  global.fog_start = min(global.fog_start   + 80*_dt, global.fog_end - 1);
if (keyboard_check(vk_left))  global.fog_end   = max(global.fog_end     - 120*_dt, global.fog_start + 1);
if (keyboard_check(vk_right)) global.fog_end   = min(global.fog_end     + 120*_dt, 2000);
