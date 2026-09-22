// Omega-D Glass Plate Carrier Base Shape Generator
// Single-piece Omega-D carrier for 4x5 glass plates (dry plates, or a negative
// on a 4x5 glass). It is one slab as thick as a normal top+bottom pair, with a
// pocket on the top face that locates the plate. There is no top half: the
// rigid plate can't curl, so nothing needs to clamp it. The alignment board is
// screwed on underneath rather than fused, so the pocket prints face-up without
// supports (see OMEGA_BOARD_4X5_SCREW_PATTERN_* in carrier-configs.scad).

// BOSL2 is included once at the entry point (carrier.scad) — OpenSCAD re-parses
// every include with no dedup, so re-including the ~80k-line library here would
// add seconds per render. Uncomment to render/preview this file by itself:
// include <BOSL2/std.scad>
include <carrier-configs.scad>
// omega_d_base_shape (omega-d-base-shape.scad), alignment_footprint_holes
// (common/carrier-features.scad) and omega_d_alignment_board_no_screws
// (common/omega-d-alignment-board.scad) are included by the entry point.

// Config array indices for the glass carrier (built by omega_d_glass_config)
_GC_PLATE_WIDTH = 0;     // plate size across the carrier (X, short edge)
_GC_PLATE_LENGTH = 1;    // plate size along the carrier width (Y, long edge)
_GC_PLATE_THICKNESS = 2; // thickest plate the pocket must swallow
_GC_SIDE_PLAY = 3;       // clearance per side between plate and pocket wall
_GC_DEPTH_PLAY = 4;      // extra pocket depth beyond the plate thickness
_GC_NOTCH_DIAMETER = 5;  // finger notch diameter (0 disables)
_GC_NOTCH_CORNER = 6;    // which pocket corner gets the notch
_GC_NOTCH_FLOOR = 7;     // material left under the notch (0 = through)
_GC_NOTCH_REACH = 8;     // how far the notch extends under the plate edge

// Inside-corner radius of the pocket. A printed pocket can't hold a sharp
// inside corner anyway; with the side play this still clears a square-cornered
// plate (a 1mm radius costs ~0.4mm of diagonal clearance).
OMEGA_D_GLASS_POCKET_CORNER_RADIUS = 1;

/**
 * Build the config array the glass base shape reads.
 * @param plate_width - Plate dimension along X (mm), the short edge
 * @param plate_length - Plate dimension along Y (mm), the long edge
 * @param plate_thickness - Plate thickness the pocket is sized for (mm)
 * @param side_play - Per-side lateral clearance (mm)
 * @param depth_play - Extra pocket depth beyond plate_thickness (mm)
 * @param notch_diameter - Finger notch diameter (mm); 0 disables
 * @param notch_corner - "handle-lower" | "handle-upper" | "far-lower" | "far-upper" | "none"
 * @param notch_floor - Material left under the notch (mm); 0 cuts through
 * @param notch_reach - How far the notch extends under the plate edge (mm);
 *        keep it under the rim between pocket and film opening
 */
function omega_d_glass_config(plate_width, plate_length, plate_thickness, side_play, depth_play, notch_diameter, notch_corner, notch_floor, notch_reach) =
    [plate_width, plate_length, plate_thickness, side_play, depth_play, notch_diameter, notch_corner, notch_floor, notch_reach];

// Pocket footprint and depth derived from a glass config
function omega_d_glass_pocket_width(config) = config[_GC_PLATE_WIDTH] + 2 * config[_GC_SIDE_PLAY];
function omega_d_glass_pocket_length(config) = config[_GC_PLATE_LENGTH] + 2 * config[_GC_SIDE_PLAY];
function omega_d_glass_pocket_depth(config) = config[_GC_PLATE_THICKNESS] + config[_GC_DEPTH_PLAY];

// Sign vector [sx, sy] for a notch corner name. The Omega-D handle is on -X,
// so "handle" corners are at -X and "far" corners at +X; "lower" is -Y.
function _omega_d_glass_notch_signs(corner) =
    corner == "handle-lower" ? [-1, -1]
    : corner == "handle-upper" ? [-1, 1]
    : corner == "far-lower" ? [1, -1]
    : corner == "far-upper" ? [1, 1]
    : undef;

/**
 * Omega-D glass plate carrier base shape.
 * The standard Omega-D outline and registration holes at double thickness,
 * minus the plate pocket and the finger notch. The film opening, text and
 * alignment-board screw holes are applied by the universal assembly.
 *
 * @param config - Array from omega_d_glass_config()
 * @param top_or_bottom - Ignored: this is a single-piece carrier (always the
 *        bottom-style piece, no separation hole)
 */
module omega_d_glass_base_shape(config, top_or_bottom = "bottom") {
    CARRIER_HEIGHT = get_carrier_height("omega-d-glass");
    HALF_H = CARRIER_HEIGHT / 2;

    pocket_w = omega_d_glass_pocket_width(config);
    pocket_l = omega_d_glass_pocket_length(config);
    pocket_depth = omega_d_glass_pocket_depth(config);
    notch_d = config[_GC_NOTCH_DIAMETER];
    notch_signs = _omega_d_glass_notch_signs(config[_GC_NOTCH_CORNER]);
    notch_floor = config[_GC_NOTCH_FLOOR];
    notch_depth = CARRIER_HEIGHT - notch_floor;
    notch_reach = config[_GC_NOTCH_REACH];
    has_notch = notch_d > 0 && notch_signs != undef;

    assert(pocket_depth < CARRIER_HEIGHT,
        str("GLASS CARRIER ERROR: pocket depth ", pocket_depth, "mm leaves no floor in a ", CARRIER_HEIGHT, "mm carrier."));
    assert(!has_notch || notch_depth > pocket_depth,
        str("GLASS CARRIER ERROR: notch floor ", notch_floor, "mm puts the notch above the pocket floor; it must sit below the plate to be useful."));
    assert(!has_notch || notch_d <= pocket_l,
        "GLASS CARRIER ERROR: notch diameter is larger than the pocket length.");
    assert(!has_notch || (notch_reach >= 0 && notch_reach <= notch_d / 2),
        "GLASS CARRIER ERROR: notch reach must be between 0 and the notch radius.");

    /**
     * Plate pocket, open to the top face. Cut oversize in Z so the top face is
     * cleanly removed.
     */
    module plate_pocket() {
        translate([0, 0, HALF_H - pocket_depth / 2 + 0.5])
            cuboid([pocket_w, pocket_l, pocket_depth + 1],
                anchor=CENTER, rounding=OMEGA_D_GLASS_POCKET_CORNER_RADIUS, edges="Z");
    }

    /**
     * Finger notch: a circle at one pocket corner, cut deeper than the pocket
     * floor. It sits just outside the pocket's short (X) edge, tangent to the
     * long edge, and reaches notch_reach under the plate: the part beside the
     * plate is where a fingertip presses down, the sliver under the plate lets
     * a nail hook its bottom edge. The reach is kept small so the notch never
     * runs into the film opening — the rim between pocket and 4x5 opening is
     * only ~3.5mm — and it goes on the short edge because the carrier has only
     * ~6mm of rail beyond the pocket on the long (Y) edges.
     */
    module finger_notch() {
        if (has_notch) {
            r = notch_d / 2;
            cx = notch_signs[0] * (pocket_w / 2 + r - notch_reach);
            cy = notch_signs[1] * (pocket_l / 2 - r);
            translate([cx, cy, HALF_H - notch_depth / 2 + 0.5])
                cylinder(h=notch_depth + 1, r=r, center=true);
        }
    }

    // render() caches geometry for faster subsequent previews
    render() difference() {
        omega_d_base_shape(config, "bottom", carrier_height=CARRIER_HEIGHT);
        plate_pocket();
        finger_notch();
    }
}

/**
 * Separately printed Omega alignment board for the glass carrier, with
 * clearance holes matching the carrier's screw footprint so it can be screwed
 * on from below (M2 screws thread into the carrier's 2mm holes). Uses the
 * 4x5-widened board opening for the 4x5 film format like the fused board.
 *
 * @param film_format - Film format string, selects the board opening variant
 * @param screw_clearance_dia - Board hole diameter (default: M2 clearance; pass
 *                              heat_set_clearance_hole_dia(Heat_Set_Screw_Size))
 */
module omega_d_glass_alignment_board(film_format = "4x5", screw_clearance_dia = heat_set_clearance_hole_dia()) {
    difference() {
        omega_d_alignment_board_no_screws(film_format);
        alignment_footprint_holes(
            _screw_dia=screw_clearance_dia,
            _dist_for_x_coords=get_alignment_screw_pattern_dist_x("omega-d-glass"),
            _dist_for_y_coords=get_alignment_screw_pattern_dist_y("omega-d-glass"),
            _carrier_h=BOARD_HEIGHT,
            _cut_ext=1,
            _is_dent=false,
            _dent_depth=0
        );
    }
}
