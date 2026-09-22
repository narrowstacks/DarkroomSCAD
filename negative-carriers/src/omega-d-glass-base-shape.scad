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
_GC_ORIENTATION = 9;     // effective sheet orientation: the plate's long edge runs
                         // along Y ("horizontal", the default) or X ("vertical")

// Inside-corner radius of the pocket. A printed pocket can't hold a sharp
// inside corner anyway; with the side play this still clears a square-cornered
// plate (a 1mm radius costs ~0.4mm of diagonal clearance).
OMEGA_D_GLASS_POCKET_CORNER_RADIUS = 1;

/**
 * Build the config array the glass base shape reads.
 * @param plate_width - Plate dimension (mm) along its short edge
 * @param plate_length - Plate dimension (mm) along its long edge
 * @param plate_thickness - Plate thickness the pocket is sized for (mm)
 * @param side_play - Per-side lateral clearance (mm)
 * @param depth_play - Extra pocket depth beyond plate_thickness (mm)
 * @param notch_diameter - Finger notch diameter (mm); 0 disables
 * @param notch_corner - "handle-lower" | "handle-upper" | "far-lower" | "far-upper" | "none"
 * @param notch_floor - Material left under the notch (mm); 0 cuts through
 * @param notch_reach - How far the notch extends under the plate edge (mm);
 *        keep it under the rim between pocket and film opening
 * @param orientation - The sheet's EFFECTIVE orientation (get_effective_orientation):
 *        "horizontal" (default) runs the plate's long edge along Y like the 4x5
 *        film opening; "vertical" turns the pocket with it (long edge along X)
 */
function omega_d_glass_config(plate_width, plate_length, plate_thickness, side_play, depth_play, notch_diameter, notch_corner, notch_floor, notch_reach, orientation = "horizontal") =
    [plate_width, plate_length, plate_thickness, side_play, depth_play, notch_diameter, notch_corner, notch_floor, notch_reach, orientation];

// Pocket footprint and depth derived from a glass config. The pocket turns
// with the sheet: its X extent is the plate's short edge when horizontal and
// its long edge when vertical (the config's orientation is the effective one).
function omega_d_glass_is_vertical(config) = config[_GC_ORIENTATION] == "vertical";
function omega_d_glass_pocket_width(config) =
    (omega_d_glass_is_vertical(config) ? config[_GC_PLATE_LENGTH] : config[_GC_PLATE_WIDTH]) + 2 * config[_GC_SIDE_PLAY];
function omega_d_glass_pocket_length(config) =
    (omega_d_glass_is_vertical(config) ? config[_GC_PLATE_WIDTH] : config[_GC_PLATE_LENGTH]) + 2 * config[_GC_SIDE_PLAY];
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
     * floor. It sits just beyond the pocket's X extent, tangent to the pocket's
     * Y edge, and reaches notch_reach under the plate: the part beside the
     * plate is where a fingertip presses down, the sliver under the plate lets
     * a nail hook its bottom edge. The reach is kept small so the notch never
     * runs into the film opening — the rim between pocket and 4x5 opening is
     * only ~3.5mm (4mm turned) — and it goes beyond the X extent because the
     * carrier has only ~6mm of rail beyond the (horizontal) pocket in Y; in X
     * there is 20mm+ either way, so a vertical pocket keeps the same rule and
     * the notch lands at the ends of the plate's long edge.
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
 * 4x5-widened board opening for the 4x5 film format like the fused board,
 * turned — with the screw pattern — for a vertical sheet.
 *
 * Each hole gets a counterbore on the board's top face (+Z, the face away from
 * the carrier, which the screws go in from) so the screw head sits mostly
 * inside the 1.7mm board instead of standing its full height proud of it. The
 * counterbore is the same diameter as the top carrier's head hole (head + 0.5)
 * and must leave some floor for the head to bear on: at the default 1mm in a
 * 1.7mm board that floor is 0.7mm (about three 0.2mm layers), enough for an M2
 * at hand-tight torque, so don't go much deeper.
 *
 * @param film_format - Film format string, selects the board opening variant
 * @param orientation - The sheet's EFFECTIVE orientation (get_effective_orientation);
 *                      turns the 4x5 opening and the screw pattern
 * @param screw_clearance_dia - Board hole diameter (default: M2 clearance; pass
 *                              heat_set_clearance_hole_dia(Heat_Set_Screw_Size))
 * @param head_hole_dia - Counterbore diameter (default: M2 socket head + 0.5;
 *                        pass the carrier's heat_set_head_hole_dia(...))
 * @param counterbore_depth - Counterbore depth from the top face (mm); 0 = none
 */
module omega_d_glass_alignment_board(film_format = "4x5", orientation = "horizontal", screw_clearance_dia = heat_set_clearance_hole_dia(),
                                     head_hole_dia = heat_set_head_hole_dia(), counterbore_depth = 1) {
    assert(counterbore_depth >= 0 && counterbore_depth < BOARD_HEIGHT,
        str("GLASS CARRIER ERROR: board screw counterbore ", counterbore_depth, "mm must be between 0 and the ", BOARD_HEIGHT, "mm board thickness."));
    assert(head_hole_dia > screw_clearance_dia,
        "GLASS CARRIER ERROR: board screw counterbore is not wider than the clearance hole.");

    dist_x = get_alignment_screw_pattern_dist_x("omega-d-glass", orientation = orientation);
    dist_y = get_alignment_screw_pattern_dist_y("omega-d-glass", orientation = orientation);

    difference() {
        omega_d_alignment_board_no_screws(film_format, orientation);
        alignment_footprint_holes(
            _screw_dia=screw_clearance_dia,
            _dist_for_x_coords=dist_x,
            _dist_for_y_coords=dist_y,
            _carrier_h=BOARD_HEIGHT,
            _cut_ext=1,
            _is_dent=false,
            _dent_depth=0
        );
        // Counterbores: cut down from the top face (+Z), oversize above it.
        if (counterbore_depth > 0)
            for (xm = [-1, 1]) for (ym = [-1, 1])
                translate([xm * dist_x / 2, ym * dist_y / 2, BOARD_HEIGHT / 2 - counterbore_depth])
                    cylinder(h=counterbore_depth + 1, d=head_hole_dia, $fn=24);
    }
}
