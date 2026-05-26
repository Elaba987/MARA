/// @desc  Renderizado de props (objetos decorativos) con z-buffer.
///
/// Props 3D  (case 1, 2): 8 frames direccionales — silla, escritorio.
/// Props billboard (case 3, 4): siempre miran al jugador — barril, lámpara.
///
/// Llama a esta función DESPUÉS del bucle de paredes en Draw_0.
/// Requisito: global.zbuffer[] debe estar relleno por el bucle de paredes.
///
/// @param {real} _px          X jugador (px)
/// @param {real} _py          Y jugador (px)
/// @param {real} _player_ang  Ángulo de mirada horizontal (grados)
/// @param {real} _look_vert   Offset vertical del horizonte (px)

function scr_render_props(_px, _py, _player_ang, _look_vert) {

    // ── Guards ────────────────────────────────────────────────────────────────
    if (!variable_global_exists("props"))           return;
    if (!ds_exists(global.props, ds_type_list))     return;

    var _n = ds_list_size(global.props);
    if (_n == 0) return;

    var _sw      = global.sw;
    var _sh      = global.sh;
    var _half_w  = global.half_w;
    var _half_h  = global.half_h;
    var _pd      = global.proj_dist;
    var _cell    = global.CELL_SIZE;
    var _pa_rad  = degtorad(_player_ang);

    var _fog_r = color_get_red(global.fog_color);
    var _fog_g = color_get_green(global.fog_color);
    var _fog_b = color_get_blue(global.fog_color);

    // ── Ordenar props de lejos a cerca (Painter's Algorithm) ─────────────────
    var _sorted = array_create(_n);
    for (var i = 0; i < _n; i++) {
        var _p  = global.props[| i];
        var _dx = _p.wx - _px;
        var _dy = _p.wy - _py;
        _sorted[i] = { dsq: _dx*_dx + _dy*_dy, idx: i };
    }

    // Insertion sort de mayor a menor distancia
    for (var a = 1; a < _n; a++) {
        var _cur = _sorted[a];
        var b    = a - 1;
        while (b >= 0 && _sorted[b].dsq < _cur.dsq) {
            _sorted[b+1] = _sorted[b];
            b--;
        }
        _sorted[b+1] = _cur;
    }

    // ── Renderizar cada prop ──────────────────────────────────────────────────
    for (var si = 0; si < _n; si++) {
        var _p = global.props[| _sorted[si].idx];

        var _dx = _p.wx - _px;
        var _dy = _p.wy - _py;

        // Ángulo relativo al eje de visión del jugador
        var _rel_ang = arctan2(_dy, _dx) - _pa_rad;

        // Normalizar a -pi..pi
        while (_rel_ang >  pi) _rel_ang -= 2*pi;
        while (_rel_ang < -pi) _rel_ang += 2*pi;

        // Culling: descartar props fuera del FOV ampliado
        if (abs(_rel_ang) > pi * 0.55) continue;

        var _dist = sqrt(_dx*_dx + _dy*_dy);
        if (_dist < 4) continue;

        // Distancia perpendicular al plano de proyección (anti-fisheye)
        var _perp = _dist * cos(_rel_ang);
        if (_perp <= 0) continue;

        // ── Seleccionar sprite, frame y modo ──────────────────────────────────
        var _spr       = -1;
        var _frame     = 0;
        var _billboard = true;   // true = siempre cara al jugador

        switch (_p.ptype) {
            case 1:   // silla — 8 frames direccionales
                _spr       = spr_prop_chair;
                _billboard = false;
                break;
            case 2:   // escritorio — 8 frames direccionales
                _spr       = spr_prop_desk;
                _billboard = false;
                break;
            case 3:   // barril — billboard
                _spr       = spr_prop_barrel;
                _billboard = true;
                break;
            case 4:   // lámpara — billboard
                _spr       = spr_prop_lamp;
                _billboard = true;
                break;
        }

        if (_spr < 0 || !sprite_exists(_spr)) continue;

        // ── Cálculo de frame para props 3D (8 direcciones) ───────────────────
        if (!_billboard) {
            // Ángulo desde el OBJETO hacia el JUGADOR (mundo)
            var _view_deg = radtodeg(arctan2(_py - _p.wy, _px - _p.wx));

            // Restar el facing del prop para obtener la cara visible
            // facing: 0=mira al Este, 90=Sur, 180=Oeste, 270=Norte
            var _facing   = variable_struct_exists(_p, "facing") ? _p.facing : 0;
            var _frame_ang = ((_view_deg - _facing) mod 360 + 360) mod 360;

            // Dividir en 8 sectores de 45°, centrados con offset de 22.5°
            _frame = floor((_frame_ang + 22.5) / 45.0) mod 8;

            // Clamp por si el sprite tiene menos de 8 frames
            var _total = sprite_get_number(_spr);
            if (_frame >= _total) _frame = _frame mod max(_total, 1);
        }

        // ── Proyección en pantalla ────────────────────────────────────────────
       // ── Proyección en pantalla ────────────────────────────────────────────────────
		var _prop_scale = variable_struct_exists(_p, "scale") ? _p.scale : 1.0;
		var _spr_h  = ((_cell * _pd) / _perp) * _prop_scale;
		var _spr_w  = _spr_h;   // mantener proporción cuadrada

        var _scr_cx = floor(_half_w + tan(_rel_ang) * _pd);
        var _horizon = _half_h + _look_vert;
        var _top    = floor(_horizon - _spr_h * 0.5);

        // ── Tinte de niebla y luz ambiental ───────────────────────────────────
        var _fog_t = 0;
        if (global.fog_enabled) {
            _fog_t = clamp(
                (_perp - global.fog_start) / max(global.fog_end - global.fog_start, 1),
                0, 1
            );
        }
        var _light = max(1.0 - _fog_t, global.ambient_light);
        var _tr    = clamp(floor(lerp(255 * _light, _fog_r, _fog_t)), 0, 255);
        var _tg    = clamp(floor(lerp(255 * _light, _fog_g, _fog_t)), 0, 255);
        var _tb    = clamp(floor(lerp(255 * _light, _fog_b, _fog_t)), 0, 255);
        var _tint  = make_color_rgb(_tr, _tg, _tb);

        // ── Dimensiones de textura ────────────────────────────────────────────
        var _tw     = sprite_get_width(_spr);
        var _th     = sprite_get_height(_spr);
        var _yscale = _spr_h / _th;

        // ── Bucle de columnas con z-buffer ────────────────────────────────────
        var _x0 = _scr_cx - floor(_spr_w * 0.5);
        var _x1 = _scr_cx + floor(_spr_w * 0.5);

        for (var _sx = _x0; _sx < _x1; _sx++) {
            if (_sx < 0 || _sx >= _sw) continue;

            // Solo dibujar si este prop está delante de la pared en esa columna
            if (_perp >= global.zbuffer[_sx]) continue;

            // Columna de textura correspondiente
            var _tex_x = floor((_sx - _x0) / _spr_w * _tw);
            _tex_x = clamp(_tex_x, 0, _tw - 1);

            draw_sprite_part_ext(
                _spr, _frame,
                _tex_x, 0, 1, _th,
                _sx, _top,
                1, _yscale,
                _tint, 1.0
            );
        }
    }
}