/// @desc  Raycasting DDA con soporte de puertas giratorias.
///
/// @param {real} _px          Pos X jugador (px)
/// @param {real} _py          Pos Y jugador (px)
/// @param {real} _ray_ang     Ángulo del rayo (rad)
/// @param {real} _player_ang  Ángulo de cámara principal (rad) – necesario para antifish-eye de puertas
///
/// @returns struct { dist, wall_type, side, map_x, map_y, wall_u }

function scr_cast_ray(_px, _py, _ray_ang, _player_ang) {

    var _cell = global.CELL_SIZE;
    var _pcx  = _px / _cell;
    var _pcy  = _py / _cell;
    var _mx   = floor(_pcx);
    var _my   = floor(_pcy);

    var _rdx  = cos(_ray_ang);
    var _rdy  = sin(_ray_ang);

    var _ddx, _ddy;
    if (abs(_rdx) < 0.000001) { _ddx = 999999999; } else { _ddx = abs(1.0 / _rdx); }
    if (abs(_rdy) < 0.000001) { _ddy = 999999999; } else { _ddy = abs(1.0 / _rdy); }

    var _sx, _sy, _sdx, _sdy;
    if (_rdx < 0) { _sx = -1; _sdx = (_pcx - _mx)       * _ddx; }
    else          { _sx =  1; _sdx = (_mx + 1.0 - _pcx)  * _ddx; }
    if (_rdy < 0) { _sy = -1; _sdy = (_pcy - _my)       * _ddy; }
    else          { _sy =  1; _sdy = (_my + 1.0 - _pcy)  * _ddy; }

    var _hit       = false;
    var _side      = 0;
    var _wall_type = 0;
    var _steps     = 0;

    // Variables para hit de puerta
    var _door_dist = -1;
    var _door_u    = 0;
    var _door_side = 0;

    while (!_hit && _steps < 80) {
        if (_sdx < _sdy) { _sdx += _ddx; _mx += _sx; _side = 0; }
        else             { _sdy += _ddy; _my += _sy; _side = 1; }

        _wall_type = scr_map_get(_mx, _my);

        if (_wall_type == 5) {
            // ── Test de intersección rayo-segmento de la puerta ──────────────
            var _seg = scr_door_segment(_mx, _my);
            var _sdx2 = _seg.x2 - _seg.x1;
            var _sdy2 = _seg.y2 - _seg.y1;

            // Denominador del sistema 2×2
            var _den = _rdx * _sdy2 - _rdy * _sdx2;

            if (abs(_den) > 0.0001) {
                var _diffx = _seg.x1 - _px;
                var _diffy = _seg.y1 - _py;

                var _t = (_diffx * _sdy2 - _diffy * _sdx2) / _den;
                var _u = (_diffx * _rdy  - _diffy * _rdx)  / _den;

                if (_t > 2.0 && _u >= 0.0 && _u <= 1.0) {
                    // Convertir distancia euclidiana al plano de proyección (anti-fisheye)
                    _door_dist = _t * cos(_ray_ang - _player_ang);
                    if (_door_dist <= 0) _door_dist = 0.5;
                    _door_u    = _u;
                    _door_side = scr_door_info(_mx, _my).orient;
                    _hit       = true;
                }
                // Si no hay intersección (puerta abierta) el DDA continúa
            }
        } else if (_wall_type > 0) {
            _hit = true;
        }
        _steps++;
    }

    // ── Calcular distancia y UV para pared normal ────────────────────────────
    var _perp, _final_u, _final_side;

    if (_wall_type == 5 && _door_dist > 0) {
        _perp       = _door_dist;
        _final_u    = _door_u;
        _final_side = _door_side;
    } else {
        if (_side == 0) {
            _perp = (_mx - _pcx + (1 - _sx) * 0.5) / _rdx * _cell;
        } else {
            _perp = (_my - _pcy + (1 - _sy) * 0.5) / _rdy * _cell;
        }
        if (_perp <= 0) _perp = 0.5;

        if (_side == 0) {
            var _hy  = _pcy + (_perp / _cell) * _rdy;
            _final_u = _hy - floor(_hy);
            if (_rdx > 0) _final_u = 1.0 - _final_u;
        } else {
            var _hx  = _pcx + (_perp / _cell) * _rdx;
            _final_u = _hx - floor(_hx);
            if (_rdy < 0) _final_u = 1.0 - _final_u;
        }
        _final_side = _side;
    }

    return {
        dist:      _perp,
        wall_type: _wall_type,
        side:      _final_side,
        map_x:     _mx,
        map_y:     _my,
        wall_u:    _final_u
    };
}
