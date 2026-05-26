/// @desc  Mapa, colisiones, puertas y props.

// ─────────────────────────────────────────────────────────────────────────────
//  INIT PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
function scr_map_init() {

    global.MAP_COLS  = 20;
    global.MAP_ROWS  = 20;
    global.CELL_SIZE = 64;

    global.fog_enabled   = true;
    global.fog_start     = 80;
    global.fog_end       = 420;
    global.fog_color     = make_color_rgb(8, 8, 20);
    global.ambient_light = 0.18;
    global.ceiling_color = make_color_rgb(22, 22, 38);
    global.floor_color   = make_color_rgb(55, 42, 32);

    // 0=suelo  1=piedra  2=gris deteriorada  3=metal  4=carne  5=puerta
    var _raw = [
        1,1,1,1,1,1,1,1,1,3,3,1,1,1,1,1,1,1,1,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,0,1,1,0,0,0,0,0,0,0,0,0,2,2,0,0,0,1,
        1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,1,
        1,0,0,0,0,0,0,3,0,0,0,0,3,0,0,0,0,0,0,1,
        1,1,1,1,5,1,1,1,1,1,1,1,1,1,5,1,1,1,1,1,
        1,0,0,0,0,2,0,0,0,0,0,0,0,0,2,0,0,0,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,
        3,0,0,0,0,0,0,0,4,4,4,4,0,0,0,0,0,0,0,3,
        3,0,0,0,0,0,0,0,4,5,4,4,0,0,0,0,0,0,0,3,
        3,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,3,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,0,2,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,1,
        1,0,0,2,2,0,0,0,0,0,0,0,0,0,2,2,0,0,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,0,0,0,0,0,0,4,4,0,0,0,0,0,0,0,0,0,1,
        1,0,0,0,0,3,0,0,4,0,0,0,0,3,0,0,0,0,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,1,1,1,1,1,1,1,1,3,3,1,1,1,1,1,1,1,1,1
    ];

    global.map = array_create(global.MAP_COLS * global.MAP_ROWS, 0);
    for (var i = 0; i < array_length(_raw); i++) {
        global.map[i] = _raw[i];
    }

    // Estados de puertas:  key = "col_row"  value = 0.0 (cerrada) .. 1.0 (abierta)
    global.door_states  = ds_map_create();
    global.door_targets = ds_map_create();

    for (var r = 0; r < global.MAP_ROWS; r++) {
        for (var c = 0; c < global.MAP_COLS; c++) {
            if (scr_map_get(c, r) == 5) {
                var _k = string(c) + "_" + string(r);
                ds_map_add(global.door_states,  _k, 0.0);
                ds_map_add(global.door_targets, _k, 0.0);
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS DE CELDA
// ─────────────────────────────────────────────────────────────────────────────
function scr_map_get(_col, _row) {
    if (_col < 0 || _col >= global.MAP_COLS ||
        _row < 0 || _row >= global.MAP_ROWS) { return 1; }
    return global.map[_row * global.MAP_COLS + _col];
}

/// Devuelve true si la posición en píxeles es bloqueante para movimiento.
function scr_wall_at(_wx, _wy) {
    var _c = floor(_wx / global.CELL_SIZE);
    var _r = floor(_wy / global.CELL_SIZE);
    var _t = scr_map_get(_c, _r);
    if (_t == 0) return false;
    if (_t == 5) { return scr_door_get(_c, _r) < 0.35; }
    return true;
}

function scr_circle_wall(_cx, _cy, _r) {
    var _pts = [
        [_cx+_r,       _cy      ],[_cx-_r,       _cy      ],
        [_cx,          _cy+_r   ],[_cx,           _cy-_r   ],
        [_cx+_r*0.72,  _cy+_r*0.72],[_cx-_r*0.72, _cy+_r*0.72],
        [_cx+_r*0.72,  _cy-_r*0.72],[_cx-_r*0.72, _cy-_r*0.72]
    ];
    for (var i = 0; i < 8; i++) {
        if (scr_wall_at(_pts[i][0], _pts[i][1])) return true;
    }
    return false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PUERTAS
// ─────────────────────────────────────────────────────────────────────────────

/// Apertura actual 0.0–1.0.
function scr_door_get(_col, _row) {
    var _k = string(_col) + "_" + string(_row);
    if (ds_map_exists(global.door_states, _k)) {
        return global.door_states[? _k];
    }
    return 0.0;
}

/// Alterna la puerta entre abrir/cerrar.
function scr_door_toggle(_col, _row) {
    var _k = string(_col) + "_" + string(_row);
    if (!ds_map_exists(global.door_states, _k)) {
        ds_map_add(global.door_states,  _k, 0.0);
        ds_map_add(global.door_targets, _k, 0.0);
    }
    var _cur = global.door_states[? _k];
    global.door_targets[? _k] = (_cur < 0.5) ? 1.0 : 0.0;
}

/// Devuelve info de orientación y bisagra de la puerta.
/// orient 0 = puerta en pared horizontal (bloquea paso N-S)
/// orient 1 = puerta en pared vertical   (bloquea paso E-W)
function scr_door_info(_col, _row) {
    var _cx = _col * global.CELL_SIZE;
    var _cy = _row * global.CELL_SIZE;
    var _hs = global.CELL_SIZE * 0.5;
    var _k  = string(_col) + "_" + string(_row);

    // ── Override manual ───────────────────────────────────────────────────────
    if (variable_global_exists("door_orient_override") &&
        ds_map_exists(global.door_orient_override, _k)) {
        var _ov = global.door_orient_override[? _k];
        var _hx, _hy;
        if (_ov.orient == 0) {
            _hx = (_ov.hinge == 0) ? _cx : _cx + global.CELL_SIZE;
            _hy = _cy + _hs;
        } else {
            _hx = _cx + _hs;
            _hy = (_ov.hinge == 0) ? _cy : _cy + global.CELL_SIZE;
        }
        return { orient:_ov.orient, hx:_hx, hy:_hy };
    }

    // ── Auto-detect (comportamiento original) ─────────────────────────────────
    var _n_wall = (scr_map_get(_col, _row-1) > 0 && scr_map_get(_col, _row-1) != 5);
    var _s_wall = (scr_map_get(_col, _row+1) > 0 && scr_map_get(_col, _row+1) != 5);
    if (_n_wall || _s_wall) {
        return { orient:0, hx:_cx, hy:_cy+_hs };
    } else {
        return { orient:1, hx:_cx+_hs, hy:_cy };
    }
}

/// Devuelve el segmento 2D de la puerta en píxeles según su apertura actual.
/// {x1,y1} = bisagra   {x2,y2} = extremo libre
function scr_door_segment(_col, _row) {
    var _info = scr_door_info(_col, _row);
    var _open = scr_door_get(_col, _row);
    var _ang  = _open * (pi / 2.0);
    var _len  = global.CELL_SIZE;

    // Leer swing del override (1 por defecto)
    var _swing = 1;
    var _k = string(_col) + "_" + string(_row);
    if (variable_global_exists("door_orient_override") &&
        ds_map_exists(global.door_orient_override, _k)) {
        _swing = global.door_orient_override[? _k].swing;
    }

    var _ex, _ey;
    if (_info.orient == 0) {
        _ex = _info.hx + _len * cos(_ang);
        _ey = _info.hy - _len * sin(_ang) * _swing;
    } else {
        _ex = _info.hx + _len * sin(_ang) * _swing;
        _ey = _info.hy + _len * cos(_ang);
    }
    return { x1:_info.hx, y1:_info.hy, x2:_ex, y2:_ey };
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROPS DECORATIVOS
//  type 1=silla  2=escritorio  3=barril  4=lámpara
// ─────────────────────────────────────────────────────────────────────────────
function scr_props_init() {
    global.props = ds_list_create();

    //                    wx    wy   type  facing  scale
    scr_prop_add(  224,  160,   4,    0,   0.30);  // lámpara    → pequeña
    scr_prop_add(  480,  160,   1,   90,   0.10);  // silla      → media
    scr_prop_add(  736,  288,   2,    0,   0.70);  // escritorio → algo grande
    scr_prop_add( 1056,  224,   3,    0,   0.45);  // barril     → medio
    scr_prop_add(  224,  544,   3,    0,   0.45);  // barril
    scr_prop_add(  672,  800,   1,  180,   0.10);  // silla
    scr_prop_add(  992,  992,   4,    0,   0.30);  // lámpara
    scr_prop_add(  160, 1120,   2,   90,   0.70);  // escritorio
    scr_prop_add(  864,  608,   4,    0,   0.30);  // lámpara
}

function scr_prop_add(_wx, _wy, _type, _facing, _scale) {
    ds_list_add(global.props, {
        wx:     _wx,
        wy:     _wy,
        ptype:  _type,
        facing: (_facing ?? 0),
        scale:  (_scale  ?? 1.0)
    });
}

// ── Override manual de puertas ────────────────────────────────────────────
    // orient: 0=panel horizontal (bisagra N/S)  1=panel vertical (bisagra E/O)
    // hinge:  0=bisagra en extremo mínimo (O/N) 1=bisagra en extremo máximo (E/S)
    // swing:  1=gira "hacia afuera"             -1=gira "hacia adentro"
    global.door_orient_override = ds_map_create();

    // ── Ajusta estos valores para cada puerta de tu mapa ─────────────────────
    ds_map_add(global.door_orient_override, "4_6",   { orient:0, hinge:0, swing: 1 });
    ds_map_add(global.door_orient_override, "14_6",  { orient:0, hinge:1, swing: 1 });
    ds_map_add(global.door_orient_override, "11_10", { orient:1, hinge:0, swing:-1 });
