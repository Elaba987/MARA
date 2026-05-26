/// @desc  Enemigos: init, IA con cono de visión, renderizado billboard.

// ─────────────────────────────────────────────────────────────────────────────
//  INIT
// ─────────────────────────────────────────────────────────────────────────────
function scr_enemy_init() {
    global.enemies = ds_list_create();

    // scr_enemy_add(world_x, world_y, facing_grados)
    scr_enemy_add(5  * 64 + 32,  2  * 64 + 32, 90);
    scr_enemy_add(10 * 64 + 32,  10 * 64 + 32, 180);
    scr_enemy_add(15 * 64 + 32,  3  * 64 + 32, 270);
}

function scr_enemy_add(_wx, _wy, _facing) {
    ds_list_add(global.enemies, {
        wx:         _wx,
        wy:         _wy,
        facing:     _facing,   // grados — dirección que mira en idle
        state:      0,         // 0=idle  1=chase
        vision_r:   220,       // px — distancia máxima de visión
        vision_fov: 80,        // grados — apertura del cono (mitad a cada lado = 40°)
        move_spd:   52,        // px/s en persecución
        alert_t:    0,         // frames que sigue al jugador sin LOS
    });
}

// ─────────────────────────────────────────────────────────────────────────────
//  LÍNEA DE VISIÓN  (muestreo a lo largo del rayo)
// ─────────────────────────────────────────────────────────────────────────────
function scr_enemy_los(_ex, _ey, _px, _py) {
    var _dx   = _px - _ex;
    var _dy   = _py - _ey;
    var _len  = sqrt(_dx*_dx + _dy*_dy);
    if (_len < 1) return true;

    var _steps = max(floor(_len / (global.CELL_SIZE * 0.3)), 6);
    var _sx    = _dx / _steps;
    var _sy    = _dy / _steps;

    for (var i = 1; i < _steps; i++) {
        var _c = floor((_ex + _sx*i) / global.CELL_SIZE);
        var _r = floor((_ey + _sy*i) / global.CELL_SIZE);
        var _t = scr_map_get(_c, _r);
        if (_t > 0 && _t != 5)                       return false;  // pared sólida
        if (_t == 5 && scr_door_get(_c,_r) < 0.35)   return false;  // puerta cerrada
    }
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP / IA
// ─────────────────────────────────────────────────────────────────────────────
function scr_enemy_step(_px, _py, _dt) {
    if (!variable_global_exists("enemies")) return;
    if (!ds_exists(global.enemies, ds_type_list)) return;

    var _n = ds_list_size(global.enemies);
    for (var i = 0; i < _n; i++) {
        var _e    = global.enemies[| i];
        var _dx   = _px - _e.wx;
        var _dy   = _py - _e.wy;
        var _dist = sqrt(_dx*_dx + _dy*_dy);

        // Ángulo desde el enemigo hacia el jugador (grados)
        var _ang_to_player = radtodeg(arctan2(_dy, _dx));

        // Diferencia con el eje de visión del enemigo
        var _diff = _ang_to_player - _e.facing;
        while (_diff >  180) _diff -= 360;
        while (_diff < -180) _diff += 360;

        var _can_see = (_dist <= _e.vision_r)
                    && (abs(_diff) <= _e.vision_fov * 0.5)
                    && scr_enemy_los(_e.wx, _e.wy, _px, _py);

        switch (_e.state) {

            case 0: // ── IDLE ─────────────────────────────────────────────────
                if (_can_see) {
                    _e.state   = 1;
                    _e.alert_t = 150;
                }
                break;

            case 1: // ── CHASE ────────────────────────────────────────────────
                if (_can_see) {
                    _e.alert_t = 150;           // resetear timer mientras ve al jugador
                } else {
                    _e.alert_t--;
                    if (_e.alert_t <= 0) _e.state = 0;   // perdió al jugador → idle
                }

                // Orientarse y avanzar
                if (_dist > 20) {
                    _e.facing = _ang_to_player;           // girar hacia el jugador

                    var _spd = _e.move_spd * _dt;
                    var _mx  = (_dx / _dist) * _spd;
                    var _my  = (_dy / _dist) * _spd;
                    var _cr  = 12;                        // radio de colisión del enemigo

                    if (!scr_circle_wall(_e.wx + _mx, _e.wy,       _cr)) _e.wx += _mx;
                    if (!scr_circle_wall(_e.wx,       _e.wy + _my, _cr)) _e.wy += _my;
                }
                break;
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RENDER  (billboard con z-buffer, igual que props)
// ─────────────────────────────────────────────────────────────────────────────
function scr_render_enemies(_px, _py, _player_ang, _look_vert) {
    if (!variable_global_exists("enemies")) return;
    if (!ds_exists(global.enemies, ds_type_list)) return;

    var _n = ds_list_size(global.enemies);
    if (_n == 0) return;

    var _sw     = global.sw;
    var _half_w = global.half_w;
    var _half_h = global.half_h;
    var _pd     = global.proj_dist;
    var _cell   = global.CELL_SIZE;
    var _pa_rad = degtorad(_player_ang);

    var _fog_r  = color_get_red(global.fog_color);
    var _fog_g  = color_get_green(global.fog_color);
    var _fog_b  = color_get_blue(global.fog_color);

    // Ordenar de lejos a cerca
    var _sorted = array_create(_n);
    for (var i = 0; i < _n; i++) {
        var _e  = global.enemies[| i];
        var _dx = _e.wx - _px;   var _dy = _e.wy - _py;
        _sorted[i] = { dsq:_dx*_dx+_dy*_dy, idx:i };
    }
    for (var a = 1; a < _n; a++) {
        var _cur = _sorted[a];   var b = a-1;
        while (b >= 0 && _sorted[b].dsq < _cur.dsq) { _sorted[b+1] = _sorted[b]; b--; }
        _sorted[b+1] = _cur;
    }

    for (var si = 0; si < _n; si++) {
        var _e   = global.enemies[| _sorted[si].idx];
        var _dx  = _e.wx - _px;
        var _dy  = _e.wy - _py;

        var _rel_ang = arctan2(_dy, _dx) - _pa_rad;
        while (_rel_ang >  pi) _rel_ang -= 2*pi;
        while (_rel_ang < -pi) _rel_ang += 2*pi;
        if (abs(_rel_ang) > pi * 0.55) continue;

        var _dist = sqrt(_dx*_dx + _dy*_dy);
        if (_dist < 4) continue;

        var _perp = _dist * cos(_rel_ang);
        if (_perp <= 0) continue;

        var _spr_h  = (_cell * _pd) / _perp;
        var _spr_w  = _spr_h;
        var _scr_cx = floor(_half_w + tan(_rel_ang) * _pd);
        var _top    = floor(_half_h + _look_vert - _spr_h * 0.5);

        // Niebla
        var _fog_t = 0;
        if (global.fog_enabled) {
            _fog_t = clamp((_perp - global.fog_start) /
                           max(global.fog_end - global.fog_start, 1), 0, 1);
        }
        var _light = max(1.0 - _fog_t, global.ambient_light);

        // Color: blanco en idle, rojo en chase
        var _br = (_e.state == 1) ? 255 : 210;
        var _bg = (_e.state == 1) ?  55 : 210;
        var _bb = (_e.state == 1) ?  55 : 210;
        var _tint = make_color_rgb(
            clamp(floor(lerp(_br*_light, _fog_r, _fog_t)), 0, 255),
            clamp(floor(lerp(_bg*_light, _fog_g, _fog_t)), 0, 255),
            clamp(floor(lerp(_bb*_light, _fog_b, _fog_t)), 0, 255)
        );

        var _x0 = _scr_cx - floor(_spr_w * 0.5);
        var _x1 = _scr_cx + floor(_spr_w * 0.5);

        // ── Con sprite ────────────────────────────────────────────────────────
        if (sprite_exists(spr_enemy)) {
            var _tw     = sprite_get_width(spr_enemy);
            var _th     = sprite_get_height(spr_enemy);
            var _yscale = _spr_h / _th;
            var _frame  = min(_e.state, sprite_get_number(spr_enemy)-1);

            for (var _sx = _x0; _sx < _x1; _sx++) {
                if (_sx < 0 || _sx >= _sw) continue;
                if (_perp >= global.zbuffer[_sx]) continue;
                var _tx = clamp(floor((_sx-_x0)/_spr_w*_tw), 0, _tw-1);
                draw_sprite_part_ext(spr_enemy, _frame, _tx, 0, 1, _th,
                                     _sx, _top, 1, _yscale, _tint, 1.0);
            }
        } else {
            // ── Fallback: silueta de rectángulo si no existe spr_enemy ────────
            for (var _sx = _x0; _sx < _x1; _sx++) {
                if (_sx < 0 || _sx >= _sw) continue;
                if (_perp >= global.zbuffer[_sx]) continue;
                draw_set_color(_tint);
                draw_rectangle(_sx, _top, _sx+1, _top+floor(_spr_h), false);
            }
        }
    }
}