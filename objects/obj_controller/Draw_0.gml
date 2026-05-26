/// obj_controller  –  Draw Event
/// Pase 1: techo + suelo texturizados (floor casting)
/// Pase 2: paredes (rellena z-buffer)
/// Pase 3: props/sprites (respeta z-buffer)

if (!instance_exists(obj_player)) exit;

var _px  = obj_player.x;
var _py  = obj_player.y;
var _pa  = degtorad(obj_player.look_angle);
var _pvt = obj_player.look_vertical;

var _horizon = half_h + _pvt;

var _fog_r = color_get_red(global.fog_color);
var _fog_g = color_get_green(global.fog_color);
var _fog_b = color_get_blue(global.fog_color);

// ════════════════════════════════════════════════════════════════════════════
//  1. SUELO Y TECHO TEXTURIZADOS
// ════════════════════════════════════════════════════════════════════════════
var _dir_x   =  cos(_pa);
var _dir_y   =  sin(_pa);
var _plane_x = -sin(_pa) * tan(fov * 0.5);
var _plane_y =  cos(_pa) * tan(fov * 0.5);
var _eye_h   =  global.CELL_SIZE * 0.5;

var _has_floor   = sprite_exists(spr_floor);
var _has_ceiling = sprite_exists(spr_ceiling);

// Fallback inmediato si no hay sprites
if (!_has_ceiling) {
    draw_set_color(global.ceiling_color);
    draw_rectangle(0, 0, sw, _horizon, false);
}
if (!_has_floor) {
    draw_set_color(global.floor_color);
    draw_rectangle(0, _horizon, sw, sh, false);
}

// ── Obtener UV reales del sprite dentro del atlas ─────────────────────────
// sprite_get_uvs devuelve [u_izq, v_arr, u_der, v_aba, trimX, trimY, trimW, trimH]
var _fu = [0,0,1,1];
var _cu = [0,0,1,1];
if (_has_floor)   _fu = sprite_get_uvs(spr_floor,   0);
if (_has_ceiling) _cu = sprite_get_uvs(spr_ceiling, 0);

var _f_u0 = _fu[0]; var _f_v0 = _fu[1];
var _f_uw = _fu[2] - _fu[0];   // ancho del sprite en espacio UV del atlas
var _f_vh = _fu[3] - _fu[1];   // alto

var _c_u0 = _cu[0]; var _c_v0 = _cu[1];
var _c_uw = _cu[2] - _cu[0];
var _c_vh = _cu[3] - _cu[1];

// Sin filtro bilineal → evita sangrado entre tiles
gpu_set_texfilter(false);

// ── SUELO ─────────────────────────────────────────────────────────────────
if (_has_floor) {
    var _tex_floor = sprite_get_texture(spr_floor, 0);
    draw_primitive_begin_texture(pr_trianglelist, _tex_floor);

    for (var _fy = floor(_horizon) + 1; _fy < sh; _fy++) {
        var _rp = _fy - _horizon;
        if (_rp <= 0) continue;

        var _rd = proj_dist * _eye_h / _rp;

        // Posición mundial (celdas) del borde izquierdo y derecho del scanline
        var _ulx = (_px + (_dir_x - _plane_x) * _rd) / global.CELL_SIZE;
        var _uly = (_py + (_dir_y - _plane_y) * _rd) / global.CELL_SIZE;
        var _urx = (_px + (_dir_x + _plane_x) * _rd) / global.CELL_SIZE;
        var _ury = (_py + (_dir_y + _plane_y) * _rd) / global.CELL_SIZE;

        // Remapar: frac() para tiling → espacio UV del atlas
        var _u_l = _f_u0 + frac(_ulx) * _f_uw;
        var _v_l = _f_v0 + frac(_uly) * _f_vh;
        var _u_r = _f_u0 + frac(_urx) * _f_uw;
        var _v_r = _f_v0 + frac(_ury) * _f_vh;

        // Niebla
        var _fog_t = global.fog_enabled
            ? clamp((_rd - global.fog_start) / max(global.fog_end - global.fog_start, 1), 0, 1)
            : 0;
        var _light = max(1.0 - _fog_t, global.ambient_light);
        var _col = make_color_rgb(
            clamp(floor(lerp(255*_light, _fog_r, _fog_t)), 0, 255),
            clamp(floor(lerp(255*_light, _fog_g, _fog_t)), 0, 255),
            clamp(floor(lerp(255*_light, _fog_b, _fog_t)), 0, 255)
        );

        // Dos triángulos = quad de 1px de alto
        draw_vertex_texture_colour(  0, _fy,   _u_l, _v_l, _col, 1);
        draw_vertex_texture_colour( sw, _fy,   _u_r, _v_r, _col, 1);
        draw_vertex_texture_colour(  0, _fy+1, _u_l, _v_l, _col, 1);
        draw_vertex_texture_colour( sw, _fy,   _u_r, _v_r, _col, 1);
        draw_vertex_texture_colour( sw, _fy+1, _u_r, _v_r, _col, 1);
        draw_vertex_texture_colour(  0, _fy+1, _u_l, _v_l, _col, 1);
    }
    draw_primitive_end();
}

// ── TECHO ─────────────────────────────────────────────────────────────────
if (_has_ceiling) {
    var _tex_ceil = sprite_get_texture(spr_ceiling, 0);
    draw_primitive_begin_texture(pr_trianglelist, _tex_ceil);

    for (var _cy = 0; _cy < floor(_horizon); _cy++) {
        var _rp = _horizon - _cy;
        if (_rp <= 0) continue;

        var _rd = proj_dist * _eye_h / _rp;

        var _ulx = (_px + (_dir_x - _plane_x) * _rd) / global.CELL_SIZE;
        var _uly = (_py + (_dir_y - _plane_y) * _rd) / global.CELL_SIZE;
        var _urx = (_px + (_dir_x + _plane_x) * _rd) / global.CELL_SIZE;
        var _ury = (_py + (_dir_y + _plane_y) * _rd) / global.CELL_SIZE;

        var _u_l = _c_u0 + frac(_ulx) * _c_uw;
        var _v_l = _c_v0 + frac(_uly) * _c_vh;
        var _u_r = _c_u0 + frac(_urx) * _c_uw;
        var _v_r = _c_v0 + frac(_ury) * _c_vh;

        var _fog_t = global.fog_enabled
            ? clamp((_rd - global.fog_start) / max(global.fog_end - global.fog_start, 1), 0, 1)
            : 0;
        var _light = max(1.0 - _fog_t, global.ambient_light);
        var _col = make_color_rgb(
            clamp(floor(lerp(255*_light, _fog_r, _fog_t)), 0, 255),
            clamp(floor(lerp(255*_light, _fog_g, _fog_t)), 0, 255),
            clamp(floor(lerp(255*_light, _fog_b, _fog_t)), 0, 255)
        );

        draw_vertex_texture_colour(  0, _cy,   _u_l, _v_l, _col, 1);
        draw_vertex_texture_colour( sw, _cy,   _u_r, _v_r, _col, 1);
        draw_vertex_texture_colour(  0, _cy+1, _u_l, _v_l, _col, 1);
        draw_vertex_texture_colour( sw, _cy,   _u_r, _v_r, _col, 1);
        draw_vertex_texture_colour( sw, _cy+1, _u_r, _v_r, _col, 1);
        draw_vertex_texture_colour(  0, _cy+1, _u_l, _v_l, _col, 1);
    }
    draw_primitive_end();
}

gpu_set_texfilter(false);

// ════════════════════════════════════════════════════════════════════════════
//  2. PAREDES + RELLENO DE Z-BUFFER
// ════════════════════════════════════════════════════════════════════════════
gpu_set_texfilter(tex_filter);

for (var col = 0; col < sw; col++) {

    var _ray_a = _pa - fov * 0.5 + fov * col / sw;
    var _hit   = scr_cast_ray(_px, _py, _ray_a, _pa);

    var _dist  = _hit.dist;
    var _wtype = _hit.wall_type;
    var _u     = _hit.wall_u;

    global.zbuffer[col] = _dist;

    var _wh = (global.CELL_SIZE * proj_dist) / _dist;
    if (_wh > sh * 4) _wh = sh * 4;

    var _top    = _horizon - _wh * 0.5;
    var _bottom = _horizon + _wh * 0.5;

    var _fog_t = 0;
    if (global.fog_enabled) {
        _fog_t = clamp((_dist - global.fog_start) /
                       max(global.fog_end - global.fog_start, 1), 0, 1);
    }
    var _shade = max((1.0 - _fog_t) * ((_hit.side == 1) ? 0.6 : 1.0),
                     global.ambient_light);

    var _tr = clamp(floor(lerp(255*_shade, _fog_r, _fog_t)), 0, 255);
    var _tg = clamp(floor(lerp(255*_shade, _fog_g, _fog_t)), 0, 255);
    var _tb = clamp(floor(lerp(255*_shade, _fog_b, _fog_t)), 0, 255);
    var _tint = make_color_rgb(_tr, _tg, _tb);

    var _spr = -1;
    if (_wtype >= 0 && _wtype <= 5) _spr = wall_sprites[_wtype];

    if (_spr >= 0 && sprite_exists(_spr)) {
        var _tw = sprite_get_width(_spr);
        var _th = sprite_get_height(_spr);
        var _tc = clamp(floor(_u * _tw), 0, _tw - 1);

        draw_sprite_part_ext(
            _spr, 0,
            _tc, 0, 1, _th,
            col, _top,
            1, _wh / _th,
            _tint, 1.0
        );
    } else {
        var _fc = wall_fallback[clamp(_wtype, 0, 5)];
        var _fr = clamp(floor(lerp(color_get_red(_fc)   * _shade, _fog_r, _fog_t)), 0, 255);
        var _fg = clamp(floor(lerp(color_get_green(_fc) * _shade, _fog_g, _fog_t)), 0, 255);
        var _fb = clamp(floor(lerp(color_get_blue(_fc)  * _shade, _fog_b, _fog_t)), 0, 255);
        draw_set_color(make_color_rgb(_fr, _fg, _fb));
        draw_rectangle(col, _top, col + 1, _bottom, false);
    }
}

gpu_set_texfilter(false);

// ════════════════════════════════════════════════════════════════════════════
//  3. PROPS / SPRITES
// ════════════════════════════════════════════════════════════════════════════
scr_render_props(_px, _py, obj_player.look_angle, _pvt);

// ════════════════════════════════════════════════════════════════════════════
//  4. MINIMAPA
// ════════════════════════════════════════════════════════════════════════════
if (minimap_show) {
    var _ms   = minimap_scale;
    var _mx   = minimap_x;
    var _my   = minimap_y;
    var _cols = global.MAP_COLS;
    var _rows = global.MAP_ROWS;

    draw_set_alpha(0.60);
    draw_set_color(make_color_rgb(0,0,0));
    draw_rectangle(_mx-2, _my-2, _mx+_cols*_ms+2, _my+_rows*_ms+2, false);
    draw_set_alpha(1.0);

    for (var r = 0; r < _rows; r++) {
        for (var c = 0; c < _cols; c++) {
            var _cell_t = scr_map_get(c, r);
            var _col_c;
            switch (_cell_t) {
                case 1: _col_c = wall_fallback[1]; break;
                case 2: _col_c = wall_fallback[2]; break;
                case 3: _col_c = wall_fallback[3]; break;
                case 4: _col_c = wall_fallback[4]; break;
                case 5:
                    var _open = scr_door_get(c, r);
                    _col_c = make_color_rgb(
                        floor(lerp(160, 60,  _open)),
                        floor(lerp(120, 200, _open)),
                        floor(lerp(60,  60,  _open))
                    );
                    break;
                default: continue;
            }
            draw_set_color(_col_c);
            draw_rectangle(_mx+c*_ms, _my+r*_ms,
                           _mx+c*_ms+_ms-1, _my+r*_ms+_ms-1, false);
        }
    }

    // Props en minimapa
    if (ds_exists(global.props, ds_type_list)) {
        draw_set_color(make_color_rgb(200, 200, 50));
        for (var _pii = 0; _pii < ds_list_size(global.props); _pii++) {
            var _pr  = global.props[| _pii];
            var _pmx2 = _mx + (_pr.wx / global.CELL_SIZE) * _ms;
            var _pmy2 = _my + (_pr.wy / global.CELL_SIZE) * _ms;
            draw_rectangle(_pmx2-1, _pmy2-1, _pmx2+1, _pmy2+1, false);
        }
    }

    // Jugador
    var _pmx = _mx + (_px / global.CELL_SIZE) * _ms;
    var _pmy = _my + (_py / global.CELL_SIZE) * _ms;
    draw_set_color(c_yellow);
    draw_circle(_pmx, _pmy, 2.5, false);
    draw_set_color(make_color_rgb(255,220,50));
    draw_line(_pmx, _pmy, _pmx + cos(_pa)*12, _pmy + sin(_pa)*12);
}