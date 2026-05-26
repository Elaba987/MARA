/// obj_menu  –  Create Event
/// Menú principal: entrada de códigos alfanuméricos para desbloquear salas.

// ── Tabla de rooms válidas ────────────────────────────────────────────────────
valid_rooms = scr_build_valid_rooms();

// ── Lista de rooms descubiertas (ds_list de strings) ─────────────────────────
discovered  = ds_list_create();
scr_load_discovered_rooms(discovered);   // carga sesiones anteriores

// ── Estado del campo de texto ────────────────────────────────────────────────
input_text   = "";
max_input    = 8;         // máximo de caracteres del código
cursor_blink = 0;         // contador para parpadeo del cursor

// ── Mensajes de feedback ──────────────────────────────────────────────────────
msg_text     = "";
msg_color    = c_white;
msg_timer    = 0;         // frames hasta desaparecer

// ── Restaurar cursor del sistema ──────────────────────────────────────────────
window_set_cursor(cr_default);
