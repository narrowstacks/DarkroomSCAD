// ============================================================================
// carrier-baked.scad  —  baked-base fast-preview render path
// ============================================================================
//
// A full parametric carrier render spends most of its time (in WASM) on BOSL2's
// interpreted geometry execution — the rounded/chamfered carrier body and the
// alignment board. This entry point instead `import()`s pre-baked STLs of those two
// expensive pieces and applies the parameter-dependent features (film opening, pegs,
// text, footprint holes, directional arrows) with NATIVE OpenSCAD primitives + the
// project's existing native feature modules. No BOSL2 include — ~10x faster, with
// output equivalent to carrier.scad for the baked geometry.
//
// Carriers covered: omega-d, lpl-saunders-45xx, beseler-23c (+ their alignment boards).
// The test frame is NOT baked (format-dependent base, already fast) — the web app's
// preview-engine routes it (and any unsupported config) to the exact parametric path.
//
// What is BAKED (offline, by scripts/gen-base-stls.ts in darkroomscad-web):
//   - <carrier>-{top,bottom}.stl : the base body (output of <carrier>_base_shape(...)).
//   - board-<type>[-4x5].stl     : the alignment board (output of the board module).
// What is CUT/ADDED here (cheap, native, parameter-dependent):
//   - film opening (native rim chamfer), registration pegs/holes, owner/type text,
//     alignment footprint holes, directional arrows.
//
// This is the WASM preview entry — it imports absolute WASM-FS paths and is not meant
// to render standalone on the desktop. BOSL2 is intentionally NOT included; the
// modules it reuses (pegs, text, footprint, arrows, position functions) are all native.

// Transitively pulls film-sizes, carrier-features, carrier-configs, text-etching and
// the per-carrier base/board modules + calculate_text_position / get_text_rotation.
// Its BOSL2-using modules (base shapes, film_opening, boards) are defined but never
// called here, so no BOSL2 is needed.
include <src/common/universal-carrier-assembly.scad>

/* [Baked geometry] */
// Absolute paths in the (WASM) filesystem to the pre-baked STLs for this variant.
Baked_Base_Stl = "/base-stls/omega-d-bottom.stl";
Baked_Board_Stl = "/base-stls/board-omega.stl";

/* [Carrier Options] */
Carrier_Type = "omega-d";      // ["omega-d", "lpl-saunders-45xx", "beseler-23c"]
Orientation = "vertical";      // ["vertical", "horizontal"]
Film_Format = "35mm";
Top_or_Bottom = "bottom";      // ["top", "bottom"]
Flip_Bottom_For_Printing = true;
Printed_or_Heat_Set_Pegs = "heat_set"; // ["printed", "heat_set"]
Alignment_Board = false;
Alignment_Board_Type = "omega"; // ["omega", "lpl-saunders", "beseler-23c"]

/* [Adjustments] */
Peg_Gap = 0;
Adjust_Film_Width = 0;
Adjust_Film_Height = 0;

/* [Text] */
Enable_Owner_Name_Etch = true;
Owner_Name = "NAME";
Enable_Type_Name_Etch = true;
Type_Name = "Carrier Type";
Custom_Type_Name = "CUSTOM";
Fontface = "Lucida Console";
Font_Size = 10;
TEXT_ETCH_DEPTH = 1;
Owner_Text_X_Offset = 0;
Owner_Text_Y_Offset = 0;
Type_Text_X_Offset = 0;
Type_Text_Y_Offset = 0;

/* [Hidden] */
$fn = 32; // preview quality for the small native cut features

// --- Carrier-generic constants (same source functions carrier.scad uses) -----------
CARRIER_HEIGHT = get_carrier_height(Carrier_Type);
HALF_HEIGHT = CARRIER_HEIGHT / 2;
CUT_THROUGH_EXTENSION = 1;
FILM_OPENING_FRAME_FILLET = get_film_opening_frame_fillet(Carrier_Type);
IS_TOP = (Top_or_Bottom == "top");

SELECTED_TYPE_NAME = get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format);

opening_height = get_custom_aware_opening_height(Film_Format, Orientation, Adjust_Film_Height);
opening_width  = get_custom_aware_opening_width(Film_Format, Orientation, Adjust_Film_Width);

peg_diameter = DEFAULT_PEG_DIAMETER;
peg_positions = calculate_unified_peg_positions(
    film_format_str = Film_Format,
    orientation_str = Orientation,
    peg_diameter = peg_diameter,
    peg_gap_val = Peg_Gap,
    adjust_film_width_val = Adjust_Film_Width,
    adjust_film_height_val = Adjust_Film_Height,
    positioning_style = "omega",
    film_peg_distance = get_film_format_peg_distance(Film_Format)
);
peg_pos_x = peg_positions[0];
peg_pos_y = peg_positions[1];
peg_z_offset = IS_TOP ? (CARRIER_HEIGHT - get_top_peg_hole_z_offset(Carrier_Type)) : HALF_HEIGHT;

// Alignment screw pattern (footprint holes when the board is NOT fused).
SCREW_DIA = get_alignment_screw_diameter(Carrier_Type);
SCREW_DIST_X = get_alignment_screw_pattern_dist_x(Carrier_Type);
SCREW_DIST_Y = get_alignment_screw_pattern_dist_y(Carrier_Type);

// --- Native film opening: through-cut box with a 45° rim chamfer (reproduces
//     BOSL2 cuboid(..., chamfer=frame_fillet) without BOSL2). --------------------
module baked_film_opening(oh, ow, h, ext, ch) {
    union() {
        cube([oh, ow, h + ext], center = true);
        for (zf = [1, -1])
            translate([0, 0, zf * h / 2]) scale([1, 1, zf])
                hull() {
                    translate([0, 0, -0.001]) cube([oh, ow, 0.002], center = true);
                    translate([0, 0, ch]) cube([oh + 2 * ch, ow + 2 * ch, 0.002], center = true);
                }
    }
}

// --- Text: reuse the real carrier-aware positioning + native text-etch modules -----
// Beseler bottom carriers etch on the underside (mirrored), like the parametric path.
_etch_on_bottom = (Carrier_Type == "beseler-23c" && Top_or_Bottom == "bottom");
TEXT_ETCH_Z_POSITION = _etch_on_bottom
    ? -(HALF_HEIGHT) - 0.1
    : HALF_HEIGHT - (TEXT_ETCH_DEPTH + 0.1);

owner_metrics = (Enable_Owner_Name_Etch)
    ? textmetrics(text = Owner_Name, font = Fontface, size = Font_Size, halign = "center", valign = "center") : undef;
type_metrics = (Enable_Type_Name_Etch)
    ? textmetrics(text = SELECTED_TYPE_NAME, font = Fontface, size = Font_Size, halign = "center", valign = "center") : undef;

owner_pos_raw = (Enable_Owner_Name_Etch)
    ? calculate_text_position(Carrier_Type, "owner", carrier_owner_text_settings(Carrier_Type), owner_metrics, TEXT_ETCH_Z_POSITION, opening_width, Top_or_Bottom) : [0, 0, 0];
type_pos_raw = (Enable_Type_Name_Etch)
    ? calculate_text_position(Carrier_Type, "type", carrier_type_text_settings(Carrier_Type), type_metrics, TEXT_ETCH_Z_POSITION, opening_width, Top_or_Bottom) : [0, 0, 0];
owner_pos = [owner_pos_raw[0] + Owner_Text_X_Offset, owner_pos_raw[1] + Owner_Text_Y_Offset, owner_pos_raw[2]];
type_pos  = [type_pos_raw[0] + Type_Text_X_Offset, type_pos_raw[1] + Type_Text_Y_Offset, type_pos_raw[2]];

module baked_text_etches() {
    generate_shared_text_etch_subtractions(
        owner_name = Owner_Name, type_name = SELECTED_TYPE_NAME,
        enable_owner_etch = Enable_Owner_Name_Etch, enable_type_etch = Enable_Type_Name_Etch,
        owner_position = owner_pos, type_position = type_pos,
        owner_rotation = get_text_rotation(Carrier_Type, "owner"),
        type_rotation = get_text_rotation(Carrier_Type, "type"),
        font_face = Fontface, font_size = Font_Size,
        etch_depth = TEXT_ETCH_DEPTH, mirror_text = _etch_on_bottom
    );
}

// Footprint holes appear only when the board is NOT fused, for omega/lpl board types
// (matches generate_universal_alignment_footprint_holes). Dent (shallow) on top.
module baked_footprint_holes(is_dent) {
    if (!Alignment_Board && (Alignment_Board_Type == "omega" || Alignment_Board_Type == "lpl-saunders"))
        alignment_footprint_holes(
            _screw_dia = SCREW_DIA, _dist_for_x_coords = SCREW_DIST_X, _dist_for_y_coords = SCREW_DIST_Y,
            _carrier_h = CARRIER_HEIGHT, _cut_ext = CUT_THROUGH_EXTENSION, _is_dent = is_dent, _dent_depth = 1
        );
}

// All subtractions applied to the imported base (same set as the parametric assembly).
module baked_subtractions() {
    baked_film_opening(opening_height, opening_width, CARRIER_HEIGHT, CUT_THROUGH_EXTENSION, FILM_OPENING_FRAME_FILLET);
    generate_all_peg_features(Top_or_Bottom, Printed_or_Heat_Set_Pegs, peg_diameter, DEFAULT_PEG_HEIGHT, peg_pos_x, peg_pos_y, peg_z_offset);
    baked_footprint_holes(IS_TOP);
    baked_text_etches();
    generate_directional_arrow_etch(
        film_format_str = Film_Format, orientation_str = Orientation,
        opening_width = opening_width, opening_height = opening_height,
        arrow_length = ARROW_LENGTH, arrow_width = ARROW_WIDTH,
        arrow_etch_depth = ARROW_ETCH_DEPTH, arrow_offset = 5
    );
}

// --- Assembly: import baked base, apply native cuts + native pegs, fuse board -------
module baked_carrier() {
    union() {
        difference() {
            import(Baked_Base_Stl);
            baked_subtractions();
        }
        // Printed pegs are added (not cut) — matches carrier_base_processing.
        generate_additive_peg_features(Top_or_Bottom, Printed_or_Heat_Set_Pegs, peg_diameter, DEFAULT_PEG_HEIGHT, peg_pos_x, peg_pos_y, peg_z_offset);
        // Alignment board fuses onto the bottom carrier at a carrier/board-specific Z.
        if (Alignment_Board && !IS_TOP)
            translate([0, 0, get_alignment_board_z_offset(Carrier_Type, Alignment_Board_Type, CARRIER_HEIGHT)])
                import(Baked_Board_Stl);
    }
}

if (!IS_TOP && Flip_Bottom_For_Printing) {
    rotate([180, 0, 0]) baked_carrier();
} else {
    baked_carrier();
}
