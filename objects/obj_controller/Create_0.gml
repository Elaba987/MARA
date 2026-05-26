/// obj_controller  –  Create Event

scr_map_init();
scr_props_init();

// ── Dimensiones de pantalla ──────────────────────────────────────────────────
sw     = surface_get_width(application_surface);
sh     = surface_get_height(application_surface);
half_h = sh / 2;
half_w = sw / 2;

// Guardar como globals para que scr_sprites.gml los use
global.sw       = sw;
global.sh       = sh;
global.half_w   = half_w;
global.half_h   = half_h;

// ── Proyección ───────────────────────────────────────────────────────────────
fov       = degtorad(66);
proj_dist = half_w / tan(fov * 0.5);
global.proj_dist = proj_dist;

// ── Z-buffer (una entrada por columna de pantalla) ───────────────────────────
global.zbuffer = array_create(sw, 999999);

// ── Sprites de pared  (referencia directa al asset) ──────────────────────────
wall_sprites[0] = -1;
wall_sprites[1] = spr_wall_stone;
wall_sprites[2] = spr_wall_grey;
wall_sprites[3] = spr_wall_metal;
wall_sprites[4] = spr_wall_flesh;
wall_sprites[5] = spr_door;          // textura de puerta

// Colores de fallback (si falta algún sprite)
wall_fallback[0] = make_color_rgb(  0,   0,   0);
wall_fallback[1] = make_color_rgb(190, 150, 110);
wall_fallback[2] = make_color_rgb(140, 140, 135);
wall_fallback[3] = make_color_rgb(100, 120, 140);
wall_fallback[4] = make_color_rgb(200,  80,  80);
wall_fallback[5] = make_color_rgb(160, 120,  60);  // madera de puerta

// Debug de sprites
show_debug_message("=== Paredes ===");
show_debug_message("stone  [1] exists: " + string(sprite_exists(wall_sprites[1])));
show_debug_message("grey   [2] exists: " + string(sprite_exists(wall_sprites[2])));
show_debug_message("metal  [3] exists: " + string(sprite_exists(wall_sprites[3])));
show_debug_message("flesh  [4] exists: " + string(sprite_exists(wall_sprites[4])));
show_debug_message("door   [5] exists: " + string(sprite_exists(wall_sprites[5])));
show_debug_message("=== Props ===");
show_debug_message("chair  exists: " + string(sprite_exists(spr_prop_chair)));
show_debug_message("desk   exists: " + string(sprite_exists(spr_prop_desk)));
show_debug_message("barrel exists: " + string(sprite_exists(spr_prop_barrel)));
show_debug_message("lamp   exists: " + string(sprite_exists(spr_prop_lamp)));

// ── Minimapa ─────────────────────────────────────────────────────────────────
minimap_show  = true;
minimap_scale = 5;
minimap_x     = 10;
minimap_y     = 10;

// ── Crosshair ────────────────────────────────────────────────────────────────
cross_size = 10;
cross_gap  = 4;

// false = pixelado retro | true = bilinear
tex_filter = false;

// ── Enemigos ──────────────────────────────────────────────────────────────────
scr_enemy_init();
