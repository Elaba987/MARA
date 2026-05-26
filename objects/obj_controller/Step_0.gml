/// obj_controller  –  Step Event

var _dt = delta_time / 1_000_000;

// ── Animación de puertas (lerp hacia el objetivo) ─────────────────────────────
var _door_spd = 1.8 * _dt;   // velocidad: se abre/cierra en ~0.55 seg

var _k = ds_map_find_first(global.door_states);
while (_k != undefined) {
    var _state  = global.door_states[? _k];
    var _target = global.door_targets[? _k];
    var _diff   = _target - _state;

    if (abs(_diff) < 0.008) {
        global.door_states[? _k] = _target;
    } else {
        global.door_states[? _k] = _state + sign(_diff) * min(abs(_diff), _door_spd);
    }
    _k = ds_map_find_next(global.door_states, _k);
}

// ── [E] Interactuar con puerta ────────────────────────────────────────────────
if (keyboard_check_pressed(ord("E"))) {
    var _cell = global.CELL_SIZE;
    var _pa   = degtorad(obj_player.look_angle);
    var _cx   = obj_player.x + cos(_pa) * _cell * 1.1;
    var _cy   = obj_player.y + sin(_pa) * _cell * 1.1;
    var _col  = floor(_cx / _cell);
    var _row  = floor(_cy / _cell);

    if (scr_map_get(_col, _row) == 5) {
        scr_door_toggle(_col, _row);
    }
}

// ── Toggles de debug ─────────────────────────────────────────────────────────
if (keyboard_check_pressed(ord("M"))) { minimap_show = !minimap_show; }
if (keyboard_check_pressed(ord("F"))) { global.fog_enabled = !global.fog_enabled; }
if (keyboard_check_pressed(vk_add))      global.ambient_light = min(global.ambient_light + 0.05, 1.0);
if (keyboard_check_pressed(vk_subtract)) global.ambient_light = max(global.ambient_light - 0.05, 0.0);
if (keyboard_check_pressed(vk_escape))   room_goto(rm_menu);

// ── IA de enemigos ────────────────────────────────────────────────────────────
scr_enemy_step(obj_player.x, obj_player.y, _dt);