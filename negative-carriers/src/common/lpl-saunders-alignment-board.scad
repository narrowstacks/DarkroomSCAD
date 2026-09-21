
// BOSL2 is included once at the entry point (carrier.scad) — OpenSCAD re-parses
// every include with no dedup, so re-including the ~80k-line library here would
// add seconds per render. Uncomment to render/preview this file by itself:
// include <BOSL2/std.scad>
// include <../carrier-configs.scad>  // pilot-hole pattern constants

// $fn inherited from carrier.scad for variable preview/final quality

CIRCLE_DIAMETER = 161.5;
TOP_BOTTOM_CUT = 10.75;
BOARD_DEPTH = 4;
GAP_WIDTH = 121;
CORNER_CUT_BOX_WIDTH = 20;
SCREWS_DIAMETER = 3.5;
SCREW_HOLE_BOTTOM_DIAMETER = 2.5;
SCREW_HOLE_TOP_DIAMETER = 5;
SCREW_HOLE_LOCATION_X = 18;
SCREW_HOLE_LOCATION_Y = 5.3;
SCREW_HOLE_DISTANCE_X = 121;
SCREW_HOLE_DISTANCE_Y = 121;
// Z of the board's flat mounting face (the side that seats against the carrier
// underside) in this module's own coordinates. The chamfered half of the
// cylinder is kept and flipped 180°, so the slab spans
// [-(BOARD_DEPTH / 2 + 0.05), -0.05] with the flat face at -0.05.
LPL_BOARD_MOUNT_FACE_Z = -0.05;

module lpl_corner_cut_box() {
    rotate([0, 0, 45]) cuboid([CORNER_CUT_BOX_WIDTH, CORNER_CUT_BOX_WIDTH, BOARD_DEPTH + 0.1], anchor=CENTER);
}

// Large body geometry doesn't need high $fn
BOARD_BODY_FN = 72;

// pilot_holes: cut the carrier's screw footprint (LPL_SAUNDERS_BOARD_SCREW_PATTERN_*,
// carrier-configs.scad) as thread-forming pilot holes, for the separately printed
// board that the carrier screws onto. Off for a fused board.
module lpl_saunders_alignment_board(pilot_holes = false) {
    render() rotate([0, 180, 90]) difference() {
            cyl(l=BOARD_DEPTH + 0.1, d=CIRCLE_DIAMETER, chamfer=.9, chamfang=45, from_end=true, $fn=BOARD_BODY_FN);
            translate([0, 0, -BOARD_DEPTH / 2]) cuboid([CIRCLE_DIAMETER, CIRCLE_DIAMETER, BOARD_DEPTH + 0.1], anchor=CENTER);
            cuboid([CIRCLE_DIAMETER + 0.1, GAP_WIDTH, BOARD_DEPTH + 0.2], anchor=CENTER);
            translate([0, CIRCLE_DIAMETER / 2, 0]) cuboid([161, TOP_BOTTOM_CUT, BOARD_DEPTH + 0.2], anchor=CENTER);
            translate([0, -CIRCLE_DIAMETER / 2, 0]) cuboid([161, TOP_BOTTOM_CUT, BOARD_DEPTH + 0.2], anchor=CENTER);
            // The rotate above maps this module's (x, y) to carrier (-y, -x), so
            // the carrier's (±dist_x/2, ±dist_y/2) pattern is (±dist_y/2, ±dist_x/2)
            // here (it's symmetric, so the sign flips don't matter).
            if (pilot_holes)
                for (xm = [-1, 1]) for (ym = [-1, 1])
                    translate([xm * LPL_SAUNDERS_BOARD_SCREW_PATTERN_DIST_Y / 2, ym * LPL_SAUNDERS_BOARD_SCREW_PATTERN_DIST_X / 2, 0])
                        cylinder(h=BOARD_DEPTH + 2, d=ALIGNMENT_BOARD_SCREW_PILOT_DIA, center=true, $fn=24);
        }
}
