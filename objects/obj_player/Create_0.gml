/// obj_player  –  Create Event
/// El jugador es invisible (sin sprite). Es la cámara del raycaster.
/// Posición inicial: celda (1,1) del mapa → píxeles (96, 96).

// ── Posición y ángulo ────────────────────────────────────────────────────────
x = 96;             // píxeles (celda 1 × 64 + 32 de offset central)
y = 96;
look_angle    = 0;  // ángulo horizontal de vista (grados)
look_vertical = 0;  // offset vertical del horizonte (px)  – truco estilo DOOM

// ── Velocidades ──────────────────────────────────────────────────────────────
move_speed    = 180;   // px / segundo
vert_spd      = 150;   // velocidad de mira vertical (px / s)
mouse_sens_h  = 0.22;  // sensibilidad horizontal del ratón
mouse_sens_v  = 0.18;  // sensibilidad vertical   del ratón

// ── Colisión ─────────────────────────────────────────────────────────────────
col_radius = 14;   // radio del círculo de colisión (px)

// ── Bloquear cursor al centro de la ventana ───────────────────────────────────
window_mouse_set(window_get_width()  div 2,
                 window_get_height() div 2);
window_set_cursor(cr_none);   // ocultar cursor del sistema
